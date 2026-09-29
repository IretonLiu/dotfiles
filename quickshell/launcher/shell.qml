import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "services" as Services
import "components"

PanelWindow {
    id: rootWindow

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell-launcher"
    readonly property string visibleFile: rootWindow.stateDir + "/visible"
    readonly property string usageFile: rootWindow.stateDir + "/usage.json"

    property bool launcherVisible: false
    property bool launchInProgress: false
    property real animationProgress: launcherVisible ? 1.0 : 0.0
    property string queryText: ""
    property string activePage: "apps"
    property var usageCounts: ({})

    Behavior on animationProgress {
        NumberAnimation {
            duration: 500
            easing.type: Easing.OutExpo
        }
    }
    property var allApps: DesktopEntries.applications.values
    property var filteredApps: launcherEntries(queryText)

    function appKey(app) {
        return app?.id || app?.name || app?.command || app?.execString || "unknown";
    }

    function usageFor(app) {
        return usageCounts[appKey(app)] || 0;
    }

    function fuzzyScore(app, query) {
        const q = query.trim().toLowerCase();
        if (q === "")
            return 0;

        const haystack = `${app?.name || ""} ${app?.comment || ""} ${app?.execString || ""} ${app?.command || ""}`.toLowerCase();
        let qi = 0;
        let score = 0;
        let streak = 0;

        for (let i = 0; i < haystack.length && qi < q.length; i++) {
            if (haystack[i] !== q[qi]) {
                streak = 0;
                continue;
            }

            score += 10 + streak * 8;
            if (i === 0 || [" ", "-", "_", ".", "/"].includes(haystack[i - 1]))
                score += 8;
            streak++;
            qi++;
        }

        if (qi !== q.length)
            return -1;

        const name = (app?.name || "").toLowerCase();
        if (name === q)
            score += 120;
        else if (name.startsWith(q))
            score += 80;
        else if (name.includes(q))
            score += 40;

        return score;
    }

    function sortedApps(query) {
        const q = query.trim();
        return allApps.map(app => ({ app, score: fuzzyScore(app, q), usage: usageFor(app) }))
            .filter(entry => q === "" || entry.score >= 0)
            .sort((a, b) => {
                if (q !== "") {
                    const scoreDiff = b.score - a.score;
                    if (scoreDiff !== 0)
                        return scoreDiff;
                }

                const usageDiff = b.usage - a.usage;
                if (usageDiff !== 0)
                    return usageDiff;

                return (a.app?.name || "").localeCompare(b.app?.name || "");
            })
            .map(entry => entry.app);
    }

    function commandForQuery(query) {
        const q = query.trim();
        if (q === "")
            return "";

        if (q.startsWith(">") || q.startsWith(":"))
            return q.slice(1).trim();

        const commands = {
            "reboot": "systemctl reboot",
            "restart": "systemctl reboot",
            "shutdown": "systemctl poweroff",
            "poweroff": "systemctl poweroff",
            "suspend": "systemctl suspend",
            "hibernate": "systemctl hibernate",
            "logout": "hyprctl dispatch exit",
            "lock": "hyprlock"
        };

        return commands[q.toLowerCase()] || "";
    }

    function commandEntry(command) {
        return {
            id: "command:" + command,
            name: "Run: " + command,
            comment: "SHELL_COMMAND",
            execString: command,
            command: ["sh", "-lc", command],
            isCommand: true
        };
    }

    function launcherEntries(query) {
        const q = query.trim();
        const apps = sortedApps(q);
        const command = commandForQuery(q);

        if (command !== "")
            return [commandEntry(command), ...apps];

        if (q !== "" && apps.length === 0)
            return [commandEntry(q)];

        return apps;
    }

    function quickPromptFromText(text) {
        const raw = text || "";
        if (!raw.startsWith("?"))
            return null;
        return raw.slice(1).replace(/^\s+/, "");
    }

    function focusActivePage() {
        if (activePage === "pi")
            piPage.forceActiveFocus();
        else
            searchInput.forceActiveFocus();
    }

    function switchPage(page) {
        activePage = page;
        if (page === "pi")
            piPage.quickMode = false;
        Qt.callLater(() => focusActivePage());
    }

    function startQuickAsk(prompt) {
        activePage = "pi";
        piPage.beginQuickAsk(prompt || "");
        queryText = "";
        searchInput.clear();
        Qt.callLater(() => piPage.forceActiveFocus());
    }

    function submitAppSearch() {
        const prompt = quickPromptFromText(queryText);
        if (prompt !== null) {
            startQuickAsk(prompt);
            Qt.callLater(() => piPage.submit());
            return;
        }
        resultList.launchCurrent();
    }

    function openPiInteractive(query) {
        Quickshell.execDetached(["sh", "-lc", "q=$1; if [ -n \"${TERMINAL:-}\" ] && command -v \"$TERMINAL\" >/dev/null 2>&1; then exec \"$TERMINAL\" -e pi -- \"$q\"; elif command -v kitty >/dev/null 2>&1; then exec kitty pi -- \"$q\"; elif command -v foot >/dev/null 2>&1; then exec foot pi -- \"$q\"; elif command -v alacritty >/dev/null 2>&1; then exec alacritty -e pi -- \"$q\"; elif command -v wezterm >/dev/null 2>&1; then exec wezterm start -- pi -- \"$q\"; else exec xterm -e pi -- \"$q\"; fi", "sh", query]);
        hideLauncher();
    }

    function setVisibleState(visible) {
        launcherVisible = visible;

        if (visible) {
            launchInProgress = false;
            queryText = "";
            activePage = "apps";
            Qt.callLater(() => {
                searchInput.clear();
                piPage.clear();
                resultList.currentIndex = -1;
                focusActivePage();
                focusRetry.attempts = 0;
                focusRetry.restart();
            });
        }
    }

    function hideLauncher() {
        visibilityWriter.run("false");
    }

    function launchApp(app) {
        if (!app || launchInProgress)
            return;

        launchInProgress = true;

        const key = appKey(app);
        const counts = Object.assign({}, usageCounts);
        counts[key] = (counts[key] || 0) + 1;
        usageCounts = counts;
        usageWriter.run(JSON.stringify(counts));

        Quickshell.execDetached(app.command);
        hideLauncher();
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    visible: launcherVisible || animationProgress > 0.01

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: launcherVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea {
        anchors.fill: parent
        enabled: rootWindow.animationProgress > 0.01
        onClicked: rootWindow.hideLauncher()
    }

    Rectangle {
        id: launcherBox
        readonly property real targetWidth: 700
        readonly property real targetHeight: 500

        width: targetWidth * rootWindow.animationProgress
        height: targetHeight * rootWindow.animationProgress
        anchors.centerIn: parent
        color: Services.Theme.surface
        radius: 4
        border.width: 1
        border.color: Services.Theme.border
        clip: true
        opacity: Math.min(1.0, rootWindow.animationProgress * 5)

        Rectangle {
            id: sideBar
            width: 40
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            color: Services.Theme.accent
            radius: 2
            opacity: 0.8 * rootWindow.animationProgress

            GlitchText {
                anchors.centerIn: parent
                textData: "APP_ORBITAL_LAUNCHER_V2"
                periodicInterval: 12000 + Math.random() * 5000
                totalTicks: 16
                glitchInterval: 80
                font.pixelSize: 10
                font.bold: true
                color: Services.Theme.surface
                rotation: -90
                width: 400
                horizontalAlignment: Text.AlignHCenter
            }
        }

        focus: rootWindow.launcherVisible
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            const alt = event.modifiers & Qt.AltModifier;
            const shift = event.modifiers & Qt.ShiftModifier;
            const meta = event.modifiers & Qt.MetaModifier;
            const enter = event.key === Qt.Key_Return || event.key === Qt.Key_Enter;

            if (event.key === Qt.Key_Escape) {
                rootWindow.hideLauncher();
                event.accepted = true;
            } else if ((ctrl && event.key === Qt.Key_Tab) || event.key === Qt.Key_Tab) {
                rootWindow.switchPage(rootWindow.activePage === "apps" ? "pi" : "apps");
                event.accepted = true;
            } else if (alt && event.key === Qt.Key_A) {
                rootWindow.switchPage("apps");
                event.accepted = true;
            } else if (alt && event.key === Qt.Key_P) {
                rootWindow.switchPage("pi");
                event.accepted = true;
            } else if (rootWindow.activePage === "pi") {
                if (ctrl && event.key === Qt.Key_M) {
                    piPage.cycleModel(shift ? -1 : 1);
                    event.accepted = true;
                } else if (ctrl && event.key === Qt.Key_E) {
                    piPage.cycleEffort(shift ? -1 : 1);
                    event.accepted = true;
                } else if (ctrl && event.key === Qt.Key_R) {
                    piPage.rerun();
                    event.accepted = true;
                } else if (ctrl && event.key === Qt.Key_L) {
                    piPage.clear();
                    event.accepted = true;
                } else if (ctrl && event.key === Qt.Key_C) {
                    piPage.copyAnswer();
                    event.accepted = true;
                } else if (ctrl && enter) {
                    piPage.openInteractive();
                    event.accepted = true;
                } else if (ctrl && event.key === Qt.Key_Up) {
                    piPage.historyPrev();
                    event.accepted = true;
                } else if (ctrl && event.key === Qt.Key_Down) {
                    piPage.historyNext();
                    event.accepted = true;
                } else if (enter) {
                    piPage.submit();
                    event.accepted = true;
                } else if (event.text !== "" && event.text.charCodeAt(0) >= 32 && !ctrl && !alt && !meta) {
                    piPage.insertText(event.text);
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_N)) {
                resultList.moveDown();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_P)) {
                resultList.moveUp();
                event.accepted = true;
            } else if (enter) {
                rootWindow.submitAppSearch();
                event.accepted = true;
            } else if (event.text !== "" && event.text.charCodeAt(0) >= 32 && !ctrl && !alt && !meta) {
                searchInput.insertText(event.text);
                event.accepted = true;
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: -10
            anchors.bottomMargin: -15
            anchors.topMargin: 10
            color: Services.Theme.shadow
            opacity: rootWindow.animationProgress
            z: -1
            radius: 4
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 56
            anchors.rightMargin: 16
            anchors.topMargin: 16
            anchors.bottomMargin: 16
            spacing: 12
            opacity: Math.max(0, rootWindow.animationProgress * 4 - 3)

            RowLayout {
                Layout.fillWidth: true
                Layout.minimumHeight: 28
                Layout.preferredHeight: 28
                Layout.maximumHeight: 28
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 92
                    Layout.minimumHeight: 24
                    Layout.preferredHeight: 24
                    Layout.maximumHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    color: rootWindow.activePage === "apps" ? Services.Theme.accent : Services.Theme.surfaceLighter
                    border.width: 1
                    border.color: rootWindow.activePage === "apps" ? Services.Theme.accent : Services.Theme.border
                    radius: 3

                    Text {
                        anchors.centerIn: parent
                        text: "ALT+A APPS"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        font.bold: true
                        color: rootWindow.activePage === "apps" ? Services.Theme.surface : Services.Theme.muted
                    }

                    MouseArea { anchors.fill: parent; onClicked: rootWindow.switchPage("apps") }
                }

                Rectangle {
                    Layout.preferredWidth: 82
                    Layout.minimumHeight: 24
                    Layout.preferredHeight: 24
                    Layout.maximumHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    color: rootWindow.activePage === "pi" ? Services.Theme.accent : Services.Theme.surfaceLighter
                    border.width: 1
                    border.color: rootWindow.activePage === "pi" ? Services.Theme.accent : Services.Theme.border
                    radius: 3

                    Text {
                        anchors.centerIn: parent
                        text: "ALT+P PI"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 9
                        font.bold: true
                        color: rootWindow.activePage === "pi" ? Services.Theme.surface : Services.Theme.muted
                    }

                    MouseArea { anchors.fill: parent; onClicked: rootWindow.switchPage("pi") }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; Layout.alignment: Qt.AlignVCenter; color: Services.Theme.accent; opacity: 0.3 }

                Text {
                    text: rootWindow.activePage === "pi" ? "TAB PAGE / ? QUICK_ASK" : "TAB PAGE / ? ASK_PI"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.bold: true
                    color: Services.Theme.accent
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0

                ColumnLayout {
                    id: appsPage
                    anchors.fill: parent
                    spacing: 16
                    visible: rootWindow.activePage === "apps"

                    SearchField {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        onTextChanged: text => {
                            rootWindow.queryText = text;
                            const quickPrompt = rootWindow.quickPromptFromText(text);
                            if (quickPrompt !== null) {
                                rootWindow.startQuickAsk(quickPrompt);
                                return;
                            }
                            resultList.currentIndex = text.trim() === "" ? -1 : 0;
                        }
                        onAccepted: rootWindow.submitAppSearch()
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Services.Theme.accent
                            opacity: 0.3
                        }

                        Text {
                            text: "RESULT_POOL_INDEX"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 8
                            font.bold: true
                            color: Services.Theme.accent
                        }

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 1
                            color: Services.Theme.accent
                            opacity: 0.3
                        }
                    }

                    ResultList {
                        id: resultList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: rootWindow.filteredApps
                        onAppLaunched: app => rootWindow.launchApp(app)
                    }
                }

                PiPage {
                    id: piPage
                    anchors.fill: parent
                    visible: rootWindow.activePage === "pi"
                    stateDir: rootWindow.stateDir
                    onOpenInteractiveRequested: query => rootWindow.openPiInteractive(query)
                }
            }
        }
    }

    Repeater {
        model: 4

        delegate: Rectangle {
            width: 3
            height: 3
            color: Services.Theme.accent
            opacity: 0.9
            visible: rootWindow.animationProgress > 0.01
            z: 100

            readonly property real startX: rootWindow.width / 2 - width / 2
            readonly property real startY: rootWindow.height / 2 - height / 2
            readonly property real targetX: launcherBox.x + (index % 2 === 0 ? -1 : launcherBox.targetWidth - width + 1)
            readonly property real targetY: launcherBox.y + (index < 2 ? -1 : launcherBox.targetHeight - height + 1)

            x: startX + (targetX - startX) * rootWindow.animationProgress
            y: startY + (targetY - startY) * rootWindow.animationProgress
        }
    }

    FileView {
        id: visibleState
        path: rootWindow.visibleFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const value = (text() || "").trim();
            rootWindow.setVisibleState(value === "true");
        }
    }

    FileView {
        id: usageState
        path: rootWindow.usageFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const value = (text() || "").trim();
            if (value === "") {
                rootWindow.usageCounts = ({});
                return;
            }

            const parsed = JSON.parse(value);
            if (parsed === null || Array.isArray(parsed) || typeof parsed !== "object")
                throw new Error("Expected object in " + rootWindow.usageFile);
            rootWindow.usageCounts = parsed;
        }
    }

    Timer {
        id: focusRetry
        interval: 16
        repeat: true
        property int attempts: 0
        onTriggered: {
            if (!rootWindow.launcherVisible || attempts >= 8) {
                stop();
                attempts = 0;
                return;
            }
            attempts++;
            rootWindow.focusActivePage();
        }
    }

    Process {
        id: visibilityWriter

        function run(value) {
            command = ["sh", "-lc", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"", "sh", rootWindow.stateDir, value, rootWindow.visibleFile];
            running = true;
        }
    }

    Process {
        id: usageWriter

        function run(value) {
            command = ["sh", "-lc", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"", "sh", rootWindow.stateDir, value, rootWindow.usageFile];
            running = true;
        }
    }
}
