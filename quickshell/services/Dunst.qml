pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Dunst's paused state queues every desktop notification until focus mode
    // is disabled, so this is a true notification mute rather than a visual-only flag.
    property bool paused: false
    property bool busy: false
    property bool available: true
    property string lastError: ""

    // The WirePlumber role loopback exposes alert streams as this virtual
    // sink. Muting it leaves normal output (music, calls, video) untouched.
    property int notificationSinkId: -1
    property bool notificationAudioAvailable: false
    property bool notificationAudioApplied: false
    property bool lastAppliedNotificationMute: false
    property string notificationAudioError: ""

    function refresh() {
        if (!busy && !pauseStateProc.running)
            pauseStateProc.running = true;
        syncNotificationAudio();
    }

    function syncNotificationAudio() {
        if (!notificationSinkProc.running)
            notificationSinkProc.running = true;
    }

    function applyNotificationAudioFocus() {
        if (notificationSinkId < 0) {
            syncNotificationAudio();
            return;
        }

        if (setNotificationMuteProc.running || (notificationAudioApplied && lastAppliedNotificationMute === paused))
            return;

        setNotificationMuteProc.sinkId = notificationSinkId;
        setNotificationMuteProc.targetMuted = paused;
        setNotificationMuteProc.running = true;
    }

    function setNotificationSink(rawId) {
        const nextId = /^\d+$/.test(rawId || "") ? Number(rawId) : -1;
        const sinkChanged = nextId !== notificationSinkId;
        notificationSinkId = Number.isInteger(nextId) && nextId >= 0 ? nextId : -1;
        notificationAudioAvailable = notificationSinkId >= 0;

        if (!notificationAudioAvailable) {
            notificationAudioApplied = false;
            notificationAudioError = "System Notifications sink is unavailable.";
            return;
        }

        notificationAudioError = "";
        if (sinkChanged)
            notificationAudioApplied = false;
        applyNotificationAudioFocus();
    }

    function toggle() {
        if (busy)
            return;

        lastError = "";
        busy = true;
        setPauseProc.targetPaused = !paused;
        setPauseProc.running = true;
    }

    Process {
        id: pauseStateProc
        command: ["dunstctl", "is-paused", "--exit-code"]
        property string errorOutput: ""

        stderr: StdioCollector {
            onStreamFinished: pauseStateProc.errorOutput = (text || "").trim()
        }

        onStarted: errorOutput = ""
        onExited: code => {
            // dunstctl uses 0 for paused and 1 for unpaused with --exit-code.
            if (code === 0 || code === 1) {
                root.paused = code === 0;
                root.available = true;
                root.lastError = "";
                root.applyNotificationAudioFocus();
            } else {
                root.available = false;
                root.lastError = pauseStateProc.errorOutput || "Unable to read Dunst focus mode state.";
            }
        }
    }

    Process {
        id: setPauseProc
        property bool targetPaused: false
        property string errorOutput: ""
        command: ["dunstctl", "set-paused", targetPaused ? "true" : "false"]

        stderr: StdioCollector {
            onStreamFinished: setPauseProc.errorOutput = (text || "").trim()
        }

        onStarted: errorOutput = ""
        onExited: code => {
            root.busy = false;
            if (code !== 0) {
                root.available = false;
                root.lastError = setPauseProc.errorOutput || "Unable to change Dunst focus mode.";
                return;
            }

            root.paused = setPauseProc.targetPaused;
            root.available = true;
            root.lastError = "";
            root.notificationAudioApplied = false;
            root.refresh();
        }
    }

    Process {
        id: notificationSinkProc
        command: ["sh", "-lc", "wpctl status -n | awk '{ for (i = 1; i <= NF; i++) if ($i == \"input.loopback.sink.role.notification\") { id = $(i - 1); gsub(/\\./, \"\", id); print id; exit } }'"]
        property string output: ""

        stdout: StdioCollector {
            onStreamFinished: {
                notificationSinkProc.output = (text || "").trim();
                root.setNotificationSink(notificationSinkProc.output);
            }
        }

        onStarted: output = ""
        onExited: code => {
            // stdout is delivered asynchronously. An empty result here is
            // corrected by the collector above once it arrives.
            if (code !== 0)
                root.setNotificationSink("");
        }
    }

    Process {
        id: setNotificationMuteProc
        property int sinkId: -1
        property bool targetMuted: false
        property string errorOutput: ""
        command: ["wpctl", "set-mute", String(sinkId), targetMuted ? "1" : "0"]

        stderr: StdioCollector {
            onStreamFinished: setNotificationMuteProc.errorOutput = (text || "").trim()
        }

        onStarted: errorOutput = ""
        onExited: code => {
            if (code !== 0) {
                root.notificationAudioApplied = false;
                root.notificationAudioError = setNotificationMuteProc.errorOutput || "Unable to change notification audio state.";
                return;
            }

            root.notificationAudioApplied = true;
            root.lastAppliedNotificationMute = setNotificationMuteProc.targetMuted;
            root.notificationAudioError = "";
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
