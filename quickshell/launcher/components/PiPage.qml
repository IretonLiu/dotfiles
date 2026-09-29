import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services" as Services
import "." as Components

Item {
    id: root

    property string stateDir: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell-launcher"
    readonly property string settingsFile: root.stateDir + "/pi-settings.json"
    readonly property string historyFile: root.stateDir + "/pi-history.json"
    readonly property string resultFile: root.stateDir + "/pi-result"
    readonly property string queryScript: Quickshell.env("HOME") + "/dotfiles/quickshell/launcher/pi-query.sh"
    readonly property string quickModel: "openai-codex/gpt-5.6-luna"

    property string queryText: ""
    property string answerText: ""
    property string errorText: ""
    property string activeModel: "gpt-5.6 luna"
    property string activeEffortLabel: "FAST"
    property string activeThinking: "minimal"
    property bool quickMode: false
    property bool queryRunning: false
    property bool settingsWritable: true
    property bool historyWritable: true
    property string currentRunId: ""
    property string pendingPrompt: ""
    property string lastAppliedRunId: ""
    readonly property int maxHistoryEntries: 64

    property int modelIndex: 0
    property int effortIndex: 0
    property int historyIndex: -1
    property var historyEntries: []
    property var modelPresets: ["openai-codex/gpt-5.6-luna", "default", "gpt-5.6", "gpt-5", "sonnet"]
    property var effortPresets: [
        { "label": "FAST", "thinking": "minimal" },
        { "label": "LOW", "thinking": "low" },
        { "label": "MED", "thinking": "medium" },
        { "label": "DEEP", "thinking": "high" },
        { "label": "MAX", "thinking": "max" }
    ]
    property string statusText: queryRunning ? "THINKING" : (errorText !== "" ? "ERROR" : (answerText !== "" ? "DONE" : "READY"))
    property color statusColor: queryRunning ? Services.Theme.warning : (errorText !== "" ? Services.Theme.danger : (answerText !== "" ? Services.Theme.success : Services.Theme.accent))
    readonly property string systemPrompt: "You are a fast desktop answer assistant. Answer concisely and practically. Prefer direct answers, short bullets, and useful commands when relevant."

    signal openInteractiveRequested(string query)

    function forceActiveFocus() {
        piInput.forceActiveFocus();
    }

    function insertText(value) {
        piInput.insertText(value);
    }

    function clear() {
        quickMode = false;
        answerText = "";
        errorText = "";
        queryText = "";
        queryRunning = false;
        currentRunId = "";
        pendingPrompt = "";
        lastAppliedRunId = "";
        historyIndex = -1;
        piInput.clear();
    }

    function beginQuickAsk(prompt) {
        quickMode = true;
        answerText = "";
        errorText = "";
        queryRunning = false;
        currentRunId = "";
        pendingPrompt = "";
        lastAppliedRunId = "";
        historyIndex = -1;
        piInput.setText(prompt || "");
    }

    function rerun() {
        if (queryText.trim() !== "")
            submit();
    }

    function currentModel() {
        return modelPresets[Math.max(0, Math.min(modelIndex, modelPresets.length - 1))] || "gpt-5.6 luna";
    }

    function currentEffort() {
        return effortPresets[Math.max(0, Math.min(effortIndex, effortPresets.length - 1))] || effortPresets[0];
    }

    function resolveModel(model) {
        if (model === "gpt-5.6 luna" || model === "gpt-5.6-luna")
            return quickModel;
        return model;
    }

    function displayModel(model) {
        return resolveModel(model) === quickModel ? "gpt-5.6 luna" : model;
    }

    function refreshActiveRunMeta(model, effort) {
        activeModel = resolveModel(model);
        activeEffortLabel = effort.label;
        activeThinking = effort.thinking;
    }

    function parseSettingsJson(value) {
        try {
            return JSON.parse(value);
        } catch (error) {
            settingsWritable = false;
            throw new Error("Invalid JSON in " + settingsFile + ": " + error.message);
        }
    }

    function parseHistoryJson(value) {
        try {
            return JSON.parse(value);
        } catch (error) {
            historyWritable = false;
            throw new Error("Invalid JSON in " + historyFile + ": " + error.message);
        }
    }

    function failSettings(message) {
        settingsWritable = false;
        throw new Error(message + " in " + settingsFile);
    }

    function failHistory(message) {
        historyWritable = false;
        throw new Error(message + " in " + historyFile);
    }

    function normalizeHistory(entries) {
        const normalized = [];
        for (const entry of entries) {
            if (!entry || typeof entry !== "object")
                failHistory("Expected history entry object");
            const previous = normalized.length > 0 ? normalized[normalized.length - 1] : null;
            if (previous && previous.q === entry.q && previous.a === entry.a)
                continue;
            normalized.push(entry);
            if (normalized.length >= maxHistoryEntries)
                break;
        }
        return normalized;
    }

    function saveSettings() {
        if (!settingsWritable)
            throw new Error("Refusing to overwrite invalid Pi settings: " + settingsFile);
        settingsWriter.run(JSON.stringify({
            "modelIndex": modelIndex,
            "effortIndex": effortIndex,
            "models": modelPresets
        }));
    }

    function cycleModel(delta) {
        if (modelPresets.length === 0)
            return;
        quickMode = false;
        modelIndex = (modelIndex + delta + modelPresets.length) % modelPresets.length;
        saveSettings();
        refreshActiveRunMeta(currentModel(), currentEffort());
    }

    function cycleEffort(delta) {
        if (effortPresets.length === 0)
            return;
        quickMode = false;
        effortIndex = (effortIndex + delta + effortPresets.length) % effortPresets.length;
        saveSettings();
        refreshActiveRunMeta(currentModel(), currentEffort());
    }

    function submit() {
        const prompt = queryText.trim();
        if (prompt === "" || queryRunning || piProcess.running)
            return;

        const model = quickMode ? quickModel : resolveModel(currentModel());
        const effort = quickMode ? effortPresets[0] : currentEffort();

        refreshActiveRunMeta(model, effort);
        answerText = "DISPATCHED_TO_PI\nAwaiting response...";
        errorText = "";
        currentRunId = Date.now().toString() + "-" + Math.floor(Math.random() * 1000000).toString();
        pendingPrompt = prompt;
        lastAppliedRunId = "";
        queryRunning = true;

        piProcess.command = ["/bin/bash", queryScript, stateDir, currentRunId, model, effort.thinking, systemPrompt, prompt];
        piProcess.running = true;
    }

    function copyAnswer() {
        const text = (answerText || errorText || "").trim();
        if (text === "")
            return;
        copyProc.command = ["wl-copy", text];
        copyProc.running = true;
        copyBadge.text = "COPIED";
        copyBadgeTimer.restart();
    }

    function openInteractive() {
        const prompt = queryText.trim();
        if (prompt !== "")
            openInteractiveRequested(prompt);
    }

    function pushHistory(prompt, answer) {
        if (!historyWritable)
            throw new Error("Refusing to overwrite invalid Pi history: " + historyFile);

        const entries = historyEntries.slice(0);
        if (entries.length > 0 && entries[0].q === prompt && entries[0].a === answer) {
            historyIndex = -1;
            return;
        }

        entries.unshift({
            "ts": Date.now(),
            "q": prompt,
            "a": answer,
            "model": activeModel,
            "effort": activeEffortLabel
        });
        historyEntries = entries.slice(0, maxHistoryEntries);
        historyWriter.run(JSON.stringify(historyEntries));
        historyIndex = -1;
    }

    function formatHistoryEntry(entry) {
        const slot = historyIndex >= 0 ? (historyIndex + 1).toString() : "?";
        const total = historyEntries.length.toString();
        const model = displayModel(entry.model || currentModel());
        const effort = entry.effort || currentEffort().label;
        const question = entry.q || "";
        const answer = entry.a || "";
        return "HISTORY " + slot + "/" + total + " · MODEL: " + model + " · EFFORT: " + effort + "\n\nQ: " + question + "\n\nA:\n" + answer;
    }

    function showHistoryEntry(delta) {
        const count = historyEntries.length;
        if (count === 0)
            return;

        if (historyIndex < 0)
            historyIndex = delta >= 0 ? 0 : count - 1;
        else
            historyIndex = (historyIndex + delta + count) % count;

        const entry = historyEntries[historyIndex];
        quickMode = false;
        queryRunning = false;
        piInput.setText(entry.q || "");
        answerText = formatHistoryEntry(entry);
        errorText = "";
        activeModel = entry.model || currentModel();
        activeEffortLabel = entry.effort || currentEffort().label;
    }

    function historyPrev() {
        showHistoryEntry(1);
    }

    function historyNext() {
        showHistoryEntry(-1);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Components.SearchField {
            id: piInput
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            iconText: "󰚩"
            titleText: root.quickMode ? "PI_QUICK_ASK" : "PI_QUERY"
            subtitleText: root.quickMode ? "FAST_LOCKED" : "ASK_ASSISTANT"
            ctrlEnterEnabled: true
            onTextChanged: text => root.queryText = text
            onAccepted: root.submit()
            onCtrlAccepted: root.openInteractive()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.statusText
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                font.bold: true
                color: root.statusColor
            }

            Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 14; color: Services.Theme.border }

            Text {
                text: "MODEL: " + root.displayModel(root.quickMode ? root.quickModel : root.currentModel())
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                color: Services.Theme.highlight
                elide: Text.ElideRight
                Layout.maximumWidth: 190
            }

            Text {
                text: "EFFORT: " + (root.quickMode ? "FAST" : root.currentEffort().label)
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                color: root.quickMode ? Services.Theme.warning : Services.Theme.muted
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Services.Theme.accent; opacity: 0.25 }

            Text {
                id: copyBadge
                text: "CTRL+C COPY"
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                font.bold: true
                color: Services.Theme.accent
                opacity: 0.75
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Services.Theme.surfaceLighter
            radius: 4
            border.width: 1
            border.color: Services.Theme.border
            clip: true

            GlitchText {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
                textData: root.statusText + " / " + root.activeEffortLabel
                triggerOnTextChanged: true
                periodicInterval: 22000
                totalTicks: 12
                glitchInterval: 80
                font.pixelSize: 36
                font.bold: true
                color: Services.Theme.accent
                opacity: 0.07
            }

            ScrollView {
                anchors.fill: parent
                anchors.margins: 12
                clip: true

                TextArea {
                    id: outputText
                    readOnly: true
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    textFormat: TextEdit.PlainText
                    text: root.errorText !== "" ? root.errorText : (root.answerText !== "" ? root.answerText : "Type a prompt and press Enter.\n\nQuick path: switch to Apps and type '? your question'.\n\nKeys: Ctrl+M model · Ctrl+E effort · Ctrl+R rerun · Ctrl+L clear · Ctrl+Enter full Pi.")
                    font.family: "JetBrains Mono"
                    font.pixelSize: 12
                    color: root.errorText !== "" ? Services.Theme.danger : Services.Theme.highlight
                    selectedTextColor: Services.Theme.surface
                    selectionColor: Services.Theme.accent
                    background: Rectangle { color: "transparent" }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "CTRL+UP/DOWN HISTORY " + root.historyEntries.length + "/" + root.maxHistoryEntries
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                color: Services.Theme.muted
            }

            Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Services.Theme.border }

            Text {
                text: root.quickMode ? "QUICK_ASK_LOCKED_FAST" : "CTRL+M MODEL  CTRL+E EFFORT"
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                font.bold: true
                color: root.quickMode ? Services.Theme.warning : Services.Theme.accent
            }
        }
    }

    FileView {
        path: root.settingsFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const value = (text() || "").trim();
            if (value === "") {
                root.settingsWritable = true;
                root.refreshActiveRunMeta(root.currentModel(), root.currentEffort());
                return;
            }
            const parsed = root.parseSettingsJson(value);
            if (parsed === null || Array.isArray(parsed) || typeof parsed !== "object")
                root.failSettings("Expected object");
            if ("models" in parsed) {
                if (!Array.isArray(parsed.models) || parsed.models.length === 0)
                    root.failSettings("Expected non-empty models array");
                root.modelPresets = parsed.models.map(model => root.resolveModel(model));
            }
            if ("modelIndex" in parsed) {
                if (typeof parsed.modelIndex !== "number")
                    root.failSettings("Expected numeric modelIndex");
                root.modelIndex = Math.max(0, Math.min(parsed.modelIndex, root.modelPresets.length - 1));
            }
            if ("effortIndex" in parsed) {
                if (typeof parsed.effortIndex !== "number")
                    root.failSettings("Expected numeric effortIndex");
                root.effortIndex = Math.max(0, Math.min(parsed.effortIndex, root.effortPresets.length - 1));
            }
            root.settingsWritable = true;
            root.refreshActiveRunMeta(root.currentModel(), root.currentEffort());
        }
    }

    FileView {
        path: root.historyFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const value = (text() || "").trim();
            if (value === "") {
                root.historyWritable = true;
                root.historyEntries = [];
                return;
            }
            const parsed = root.parseHistoryJson(value);
            if (!Array.isArray(parsed))
                root.failHistory("Expected array");
            root.historyWritable = true;
            root.historyEntries = root.normalizeHistory(parsed);
        }
    }

    FileView {
        id: resultState
        path: root.resultFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyResult(text() || "")
    }

    function applyResult(raw) {
        if (raw.trim() === "")
            return;

        const marker = "\nSTDOUT:\n";
        const stderrMarker = "\n__PI_STDERR__\n";
        const markerIndex = raw.indexOf(marker);
        const stderrIndex = raw.indexOf(stderrMarker);
        if (markerIndex < 0 || stderrIndex < markerIndex)
            throw new Error("Invalid Pi result format in " + resultFile);

        const header = raw.slice(0, markerIndex).split("\n");
        const stdoutText = raw.slice(markerIndex + marker.length, stderrIndex).trim();
        const stderrText = raw.slice(stderrIndex + stderrMarker.length).trim();
        const meta = ({});
        for (const line of header) {
            const splitIndex = line.indexOf(":");
            if (splitIndex > 0)
                meta[line.slice(0, splitIndex)] = line.slice(splitIndex + 1);
        }

        if (meta.RUN_ID !== currentRunId || meta.RUN_ID === lastAppliedRunId)
            return;

        lastAppliedRunId = meta.RUN_ID;
        queryRunning = false;
        if (meta.STATUS === "done") {
            errorText = "";
            answerText = stdoutText;
            if (stdoutText !== "")
                pushHistory(pendingPrompt, stdoutText);
            currentRunId = "";
            pendingPrompt = "";
        } else {
            answerText = stdoutText;
            errorText = stderrText || stdoutText || ("pi exited with code " + (meta.CODE || "unknown"));
            currentRunId = "";
            pendingPrompt = "";
        }
    }

    Process {
        id: piProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const helperError = (text || "").trim();
                if (helperError !== "")
                    root.errorText = helperError;
            }
        }
        onExited: code => {
            if (code === 0) {
                resultState.reload();
                return;
            }

            root.queryRunning = false;
            if (root.errorText === "")
                root.errorText = "pi helper exited with code " + code;
        }
    }

    Process {
        id: settingsWriter
        property string value: ""

        function run(newValue) {
            value = newValue;
            command = ["sh", "-lc", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"", "sh", root.stateDir, value, root.settingsFile];
            running = true;
        }
    }

    Process {
        id: historyWriter
        property string value: ""

        function run(newValue) {
            value = newValue;
            command = ["sh", "-lc", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"", "sh", root.stateDir, value, root.historyFile];
            running = true;
        }
    }

    Process { id: copyProc }

    Timer {
        id: copyBadgeTimer
        interval: 1200
        onTriggered: copyBadge.text = "CTRL+C COPY"
    }
}
