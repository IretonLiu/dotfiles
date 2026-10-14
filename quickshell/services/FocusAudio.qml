pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/quickshell"
    readonly property string configFile: stateDir + "/focus-audio.json"
    readonly property string helperScript: Quickshell.env("HOME") + "/.config/quickshell/services/focus-audio.py"

    property var selectedApps: []
    property var availableApps: []
    property bool focusActive: false
    property bool loadingApps: false
    property bool saving: false
    property string lastError: ""

    property bool restorePropsWasEnabled: true
    property bool restorePropsSuppressed: false
    property bool restorePropsChanging: false

    readonly property int selectedCount: selectedApps.length

    function normalizedList(value) {
        if (value === undefined || value === null)
            return [];

        // Repeater modelData can expose QVariantList rather than a native JS
        // Array. Accept any array-like value so application identities survive
        // the Add action unchanged.
        let items;
        if (Array.isArray(value))
            items = value;
        else if (typeof value === "string")
            items = [value];
        else if (typeof value.length === "number") {
            items = [];
            for (let index = 0; index < value.length; index++)
                items.push(value[index]);
        } else
            return [];

        return [...new Set(items.filter(item => typeof item === "string" && item.trim().length > 0).map(item => item.trim()))];
    }

    function parseConfig(raw) {
        const trimmed = (raw || "").trim();
        if (trimmed.length === 0)
            return [];

        const data = JSON.parse(trimmed);
        if (!data || data.version !== 1 || !Array.isArray(data.apps))
            throw new Error("expected version 1 with an apps array");

        const ids = new Set();
        return data.apps.map(app => {
            if (!app || typeof app.id !== "string" || typeof app.label !== "string" || app.id.trim().length === 0 || app.label.trim().length === 0)
                throw new Error("each application needs a non-empty id and label");
            if (ids.has(app.id))
                throw new Error("duplicate application id " + app.id);
            ids.add(app.id);

            const binaries = normalizedList(app.binaries);
            const applicationNames = normalizedList(app.applicationNames);
            if (binaries.length === 0 && applicationNames.length === 0)
                throw new Error("application " + app.id + " has no match identity");

            return {
                id: app.id,
                label: app.label,
                binaries: binaries,
                applicationNames: applicationNames
            };
        });
    }

    function saveConfig() {
        if (saving)
            return;

        lastError = "";
        saveConfigProc.payload = JSON.stringify({ version: 1, apps: selectedApps });
        saving = true;
        saveConfigProc.running = true;
    }

    function isSelected(id) {
        return selectedApps.some(app => app.id === id);
    }

    function addApp(candidate) {
        if (!candidate || !candidate.id || isSelected(candidate.id))
            return;

        const binaries = normalizedList(candidate.binaries);
        const applicationNames = normalizedList(candidate.applicationNames);
        if (binaries.length === 0 && applicationNames.length === 0) {
            lastError = "Unable to add " + candidate.label + ": no PipeWire match identity was supplied.";
            return;
        }

        selectedApps = selectedApps.concat([{
            id: candidate.id,
            label: candidate.label,
            binaries: binaries,
            applicationNames: applicationNames
        }]);
        saveConfig();
        reconcileFocusAudio();
    }

    function removeApp(id) {
        if (!id)
            return;

        const next = selectedApps.filter(app => app.id !== id);
        if (next.length === selectedApps.length)
            return;

        selectedApps = next;
        saveConfig();
        reconcileFocusAudio();
    }

    function prettyLabel(binary, name) {
        const source = binary || name || "Unknown application";
        return source.replace(/[-_]+/g, " ").replace(/\b\w/g, char => char.toUpperCase());
    }

    function setAvailableApps(raw) {
        try {
            const objects = JSON.parse(raw);
            const ignoredBinaries = new Set(["pipewire", "wireplumber", "quickshell", "pw-dump", "xdg-desktop-portal", "xdg-desktop-portal-hyprland"]);
            const clients = [];
            const nameOwners = new Map();

            for (const object of objects) {
                if (object.type !== "PipeWire:Interface:Client")
                    continue;

                const props = object.info?.props ?? {};
                const appName = (props["application.name"] ?? "").trim();
                const binary = (props["application.process.binary"] ?? "").trim();
                if ((!appName && !binary) || ignoredBinaries.has(binary.toLowerCase()))
                    continue;

                const owner = binary.length > 0 ? "binary:" + binary.toLowerCase() : "name:" + appName.toLowerCase();
                clients.push({ appName: appName, binary: binary, owner: owner });
                if (appName.length > 0) {
                    const nameKey = appName.toLowerCase();
                    if (!nameOwners.has(nameKey))
                        nameOwners.set(nameKey, new Set());
                    nameOwners.get(nameKey).add(owner);
                }
            }

            const candidates = new Map();
            for (const client of clients) {
                let candidate = candidates.get(client.owner);
                if (!candidate) {
                    candidate = {
                        id: client.owner,
                        label: root.prettyLabel(client.binary, client.appName),
                        binaries: client.binary.length > 0 ? [client.binary] : [],
                        applicationNames: []
                    };
                    candidates.set(client.owner, candidate);
                }

                // Electron's generic Chromium input name is shared by Slack
                // and Discord. Keep only unambiguous app-name fallbacks.
                const owners = nameOwners.get(client.appName.toLowerCase());
                if (client.appName.length > 0 && (!owners || owners.size === 1) && !candidate.applicationNames.includes(client.appName))
                    candidate.applicationNames.push(client.appName);
            }

            availableApps = Array.from(candidates.values()).sort((a, b) => a.label.localeCompare(b.label));
            lastError = "";
        } catch (error) {
            lastError = "Unable to parse PipeWire applications: " + error.message;
        }
    }

    function refreshAvailableApps() {
        if (!clientListProc.running) {
            loadingApps = true;
            clientListProc.running = true;
        }
    }

    function setFocusActive(active) {
        if (focusActive === active)
            return;

        focusActive = active;
        reconcileFocusAudio();
    }

    function reconcileFocusAudio() {
        if (focusActive && selectedApps.length > 0) {
            ensureGuard();
            return;
        }

        stopGuardAndRestore();
    }

    function ensureGuard() {
        if (!focusActive || selectedApps.length === 0 || guardProc.running || restorePropsChanging)
            return;

        if (restorePropsSuppressed) {
            guardProc.running = true;
            return;
        }

        if (!restorePropsQueryProc.running)
            restorePropsQueryProc.running = true;
    }

    function stopGuardAndRestore() {
        if (guardProc.running) {
            guardProc.running = false;
            return;
        }

        restoreStreamState();
    }

    function restoreStreamState() {
        if (!restorePropsSuppressed || restorePropsChanging || setRestorePropsProc.running)
            return;

        setRestorePropsProc.targetEnabled = restorePropsWasEnabled;
        restorePropsChanging = true;
        setRestorePropsProc.running = true;
    }

    FileView {
        path: root.configFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                root.selectedApps = root.parseConfig(text());
                root.lastError = "";
                root.reconcileFocusAudio();
            } catch (error) {
                root.lastError = "Focus Audio configuration error: " + error.message;
            }
        }
    }

    Process {
        id: saveConfigProc
        property string payload: ""
        property string errorOutput: ""
        command: ["python3", root.helperScript, "save", root.configFile, payload]

        stderr: StdioCollector {
            onStreamFinished: saveConfigProc.errorOutput = (text || "").trim()
        }

        onStarted: errorOutput = ""
        onExited: code => {
            root.saving = false;
            if (code !== 0)
                root.lastError = saveConfigProc.errorOutput || "Unable to save Focus Audio configuration.";
        }
    }

    Process {
        id: clientListProc
        command: ["pw-dump"]
        property string output: ""

        stdout: StdioCollector {
            onStreamFinished: {
                clientListProc.output = text || "";
                root.loadingApps = false;
                root.setAvailableApps(clientListProc.output);
            }
        }

        onStarted: output = ""
        onExited: code => {
            if (code !== 0) {
                root.loadingApps = false;
                root.lastError = "Unable to discover PipeWire applications.";
            }
        }
    }

    Process {
        id: restorePropsQueryProc
        command: ["wpctl", "settings", "node.stream.restore-props"]
        property string output: ""

        stdout: StdioCollector {
            onStreamFinished: {
                restorePropsQueryProc.output = (text || "").trim();
                const match = restorePropsQueryProc.output.match(/Value:\s*(true|false)/);
                if (!match)
                    return;

                root.restorePropsWasEnabled = match[1] === "true";
                setRestorePropsProc.targetEnabled = false;
                root.restorePropsChanging = true;
                setRestorePropsProc.running = true;
            }
        }

        onStarted: output = ""
        onExited: code => {
            if (code !== 0)
                root.lastError = "Unable to prepare temporary Focus Audio stream state.";
        }
    }

    Process {
        id: setRestorePropsProc
        property bool targetEnabled: true
        property string errorOutput: ""
        command: ["wpctl", "settings", "node.stream.restore-props", targetEnabled ? "true" : "false"]

        stderr: StdioCollector {
            onStreamFinished: setRestorePropsProc.errorOutput = (text || "").trim()
        }

        onStarted: errorOutput = ""
        onExited: code => {
            root.restorePropsChanging = false;
            if (code !== 0) {
                root.lastError = setRestorePropsProc.errorOutput || "Unable to update Focus Audio stream state.";
                return;
            }

            if (!setRestorePropsProc.targetEnabled) {
                root.restorePropsSuppressed = true;
                if (root.focusActive && root.selectedApps.length > 0)
                    root.ensureGuard();
                else
                    root.restoreStreamState();
            } else {
                root.restorePropsSuppressed = false;
            }
        }
    }

    Process {
        id: guardProc
        command: ["python3", root.helperScript, "guard", root.configFile]
        property string errorOutput: ""

        stderr: StdioCollector {
            onStreamFinished: guardProc.errorOutput = (text || "").trim()
        }

        onStarted: errorOutput = ""
        onExited: code => {
            if (code !== 0 && root.focusActive && root.selectedApps.length > 0)
                root.lastError = guardProc.errorOutput || "Focus Audio guard stopped unexpectedly.";

            if (root.focusActive && root.selectedApps.length > 0)
                root.ensureGuard();
            else
                root.restoreStreamState();
        }
    }

    Component.onCompleted: refreshAvailableApps()
}
