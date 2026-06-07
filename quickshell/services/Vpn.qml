pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool connected: false
    property bool busy: false
    property string activeInterface: ""
    property string lastError: ""
    property string lastMessage: ""
    property string lastConnectedName: ""
    property bool authIssue: false
    property var availableConfigs: []
    property var pendingConnect: null

    readonly property string userConfigDir: Quickshell.env("HOME") + "/.config/wireguard"
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string lastConnectedFile: root.stateDir + "/topbar-vpn-last"

    function refresh() {
        statusProc.running = true;
        listConfigsProc.running = true;
    }

    function clearStatus() {
        lastError = "";
        lastMessage = "";
        authIssue = false;
    }

    function setError(message) {
        lastError = (message || "").trim();
        if (lastError.length > 0) {
            lastMessage = "";
            const lower = lastError.toLowerCase();
            authIssue = lower.includes("pkexec") || lower.includes("polkit") || lower.includes("not authorized") || lower.includes("authentication") || lower.includes("no authentication agent") || lower.includes("permission denied") || lower.includes("cannot be used to start a command as another user");
        }
    }

    function setMessage(message) {
        lastMessage = (message || "").trim();
        if (lastMessage.length > 0)
            lastError = "";
    }

    function normalizeConfigName(path) {
        return path.split("/").pop().replace(/\.conf$/, "");
    }

    function rememberLastConnected(name) {
        if (!name || name.length === 0)
            return;
        lastConnectedName = name;
        saveLastConnectedProc.value = name;
        saveLastConnectedProc.running = true;
    }

    function connectLastUsed() {
        if (!lastConnectedName || lastConnectedName.length === 0)
            return;

        const config = availableConfigs.find(c => c.name === lastConnectedName);
        if (config)
            connect(config);
        else
            setError("Last used config not found: " + lastConnectedName);
    }

    function connect(config) {
        if (!config || !config.name)
            return;

        clearStatus();

        if (busy)
            return;

        if (connected && activeInterface === config.name) {
            disconnect(config.name);
            return;
        }

        if (connected && activeInterface !== config.name) {
            pendingConnect = config;
            disconnect(activeInterface);
            return;
        }

        const target = config.path.indexOf("/etc/wireguard/") === 0 ? config.name : config.path;
        busy = true;
        connectProc.cmd = ["pkexec", "--disable-internal-agent", "wg-quick", "up", target];
        connectProc.running = true;
    }

    function disconnect(name) {
        if (!name || busy)
            return;

        clearStatus();
        busy = true;
        disconnectProc.cmd = ["pkexec", "--disable-internal-agent", "wg-quick", "down", name];
        disconnectProc.running = true;
    }

    Process {
        id: statusProc

        command: ["wg", "show", "interfaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                const output = (text || "").trim();
                const interfaces = output.length > 0 ? output.split(/\s+/).filter(s => s !== "") : [];
                root.connected = interfaces.length > 0;
                root.activeInterface = root.connected ? interfaces[0] : "";
                if (root.connected)
                    root.rememberLastConnected(root.activeInterface);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const err = (text || "").trim();
                if (err.length > 0 && !err.includes("Unable to access interface"))
                    root.setError(err);
            }
        }
    }

    Process {
        id: listConfigsProc

        command: ["sh", "-lc", 'for file in /etc/wireguard/*.conf "$HOME/.config/wireguard"/*.conf; do [ -f "$file" ] && printf "%s\n" "$file"; done | sort -u']
        stdout: StdioCollector {
            onStreamFinished: {
                const output = (text || "").trim();
                const paths = output.length > 0 ? output.split("\n").map(s => s.trim()).filter(s => s !== "") : [];
                const configs = [];

                for (const path of paths) {
                    configs.push({
                        name: root.normalizeConfigName(path),
                        path: path
                    });
                }

                if (root.connected && root.activeInterface.length > 0 && !configs.some(c => c.name === root.activeInterface)) {
                    configs.unshift({
                        name: root.activeInterface,
                        path: "/etc/wireguard/" + root.activeInterface + ".conf"
                    });
                }

                root.availableConfigs = configs;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const err = (text || "").trim();
                if (err.length > 0)
                    root.setError(err);
            }
        }
    }

    Process {
        id: connectProc

        property var cmd: []
        command: cmd
        stdout: StdioCollector {
            onStreamFinished: {
                const msg = (text || "").trim();
                if (msg.length > 0)
                    root.setMessage(msg);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const err = (text || "").trim();
                if (err.length > 0)
                    root.setError(err);
            }
        }
        onExited: code => {
            root.busy = false;
            if (code === 0) {
                root.rememberLastConnected(root.normalizeConfigName(root.cmd[root.cmd.length - 1]));
                root.setMessage("CONNECTED");
            }
            root.refresh();
        }
    }

    Process {
        id: disconnectProc

        property var cmd: []
        command: cmd
        stdout: StdioCollector {
            onStreamFinished: {
                const msg = (text || "").trim();
                if (msg.length > 0)
                    root.setMessage(msg);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const err = (text || "").trim();
                if (err.length > 0)
                    root.setError(err);
            }
        }
        onExited: code => {
            root.busy = false;

            if (code === 0 && root.pendingConnect !== null) {
                const nextConfig = root.pendingConnect;
                root.pendingConnect = null;
                root.connect(nextConfig);
                return;
            }

            root.pendingConnect = null;
            if (code === 0)
                root.setMessage("DISCONNECTED");
            root.refresh();
        }
    }

    Process {
        id: loadLastConnectedProc

        command: ["sh", "-lc", "[ -f \"$1\" ] && tr -d '\\n' < \"$1\" || true", "sh", root.lastConnectedFile]
        stdout: StdioCollector {
            onStreamFinished: {
                root.lastConnectedName = (text || "").trim();
            }
        }
    }

    Process {
        id: saveLastConnectedProc

        property string value: ""
        command: ["sh", "-lc", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"", "sh", root.stateDir, saveLastConnectedProc.value, root.lastConnectedFile]
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: {
        loadLastConnectedProc.running = true;
        refresh();
    }
}
