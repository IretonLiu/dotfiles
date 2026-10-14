import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../services" as Services

Item {
    id: root

    implicitWidth: 216
    // Keep enough vertical room for the 10px metadata line plus a distinct
    // gap above the seek strip; 32px clipped title glyphs at this bar scale.
    implicitHeight: 34
    Layout.minimumWidth: 112
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    property color textColor: Services.Theme.highlight
    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted

    readonly property var player: Services.Media.active
    readonly property bool playing: player?.playbackState === MprisPlaybackState.Playing
    readonly property bool hasTimeline: !!player && player.length > 0 && player.positionSupported
    readonly property real currentPosition: hasTimeline ? Math.max(0, player.position % player.length) : 0
    readonly property real progress: hasTimeline ? Math.max(0, Math.min(1, currentPosition / player.length)) : 0
    readonly property bool showTransport: width >= 182

    function playerLabel() {
        const identity = player?.identity ?? "MEDIA";
        const normalized = identity.toLowerCase();
        if (normalized.includes("spotify")) return "SPOTIFY";
        if (normalized.includes("chromium") || normalized.includes("chrome")) return "BROWSER";
        if (normalized.includes("firefox")) return "FIREFOX";
        return identity.toUpperCase();
    }

    function trackLabel() {
        const title = player?.trackTitle?.trim() ?? "";
        const artist = player?.trackArtist?.trim() ?? "";
        if (title.length === 0 && artist.length === 0)
            return "NO_TRACK_METADATA";
        if (artist.length === 0)
            return title.toUpperCase();
        if (title.length === 0)
            return artist.toUpperCase();
        return title.toUpperCase() + "  //  " + artist.toUpperCase();
    }

    // Quickshell exposes MPRIS position and length in seconds (the D-Bus
    // microsecond values are converted by the service layer).
    function formatTime(valueInSeconds) {
        const seconds = Math.max(0, Math.floor(valueInSeconds));
        const minutes = Math.floor(seconds / 60);
        return minutes + ":" + (seconds % 60).toString().padStart(2, "0");
    }

    // MPRIS clients commonly expose a static Position property. Prompt the
    // service while playing so the thin timeline and elapsed time stay live.
    Timer {
        interval: 1000
        running: root.playing && root.hasTimeline
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player?.positionChanged()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Item {
            id: infoPane
            Layout.fillWidth: true
            Layout.minimumWidth: 38
            Layout.preferredHeight: root.implicitHeight
            clip: true

            RowLayout {
                id: statusRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 9
                spacing: 5

                Rectangle {
                    Layout.preferredWidth: 4
                    Layout.preferredHeight: 4
                    Layout.alignment: Qt.AlignVCenter
                    radius: 2
                    color: root.playing ? root.accentColor : root.mutedColor
                }

                Text {
                    Layout.fillWidth: true
                    text: root.playerLabel() + " // " + (root.playing ? "PLAY" : "PAUSED")
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    font.bold: true
                    color: root.accentColor
                    opacity: root.playing ? 0.8 : 0.5
                    elide: Text.ElideRight
                }

                Text {
                    visible: root.hasTimeline && infoPane.width >= 112
                    text: root.formatTime(root.currentPosition) + "/" + root.formatTime(root.player?.length ?? 0)
                    font.family: "JetBrains Mono"
                    font.pixelSize: 8
                    color: root.mutedColor
                    opacity: 0.75
                }
            }

            Item {
                id: trackViewport
                anchors.top: statusRow.bottom
                anchors.topMargin: 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: timeline.top
                anchors.bottomMargin: 3
                clip: true

                Text {
                    id: trackText
                    text: root.trackLabel()
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: root.textColor

                    readonly property real scrollDistance: Math.max(0, implicitWidth - trackViewport.width)
                    readonly property bool needsScroll: scrollDistance > 0

                    function restartMarquee() {
                        x = 0;
                        if (needsScroll)
                            marquee.restart();
                    }

                    onTextChanged: restartMarquee()
                    onScrollDistanceChanged: restartMarquee()
                    onNeedsScrollChanged: {
                        if (!needsScroll) {
                            marquee.stop();
                            x = 0;
                        }
                    }

                    SequentialAnimation {
                        id: marquee
                        running: trackText.needsScroll
                        loops: Animation.Infinite

                        PauseAnimation { duration: 1800 }
                        NumberAnimation {
                            target: trackText
                            property: "x"
                            from: 0
                            to: -trackText.scrollDistance
                            duration: Math.max(2200, trackText.scrollDistance * 32)
                            easing.type: Easing.Linear
                        }
                        PauseAnimation { duration: 1800 }
                        PropertyAction { target: trackText; property: "x"; value: 0 }
                    }
                }
            }

            MouseArea {
                id: timeline
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 7
                enabled: root.hasTimeline && root.player.canSeek
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                function seek(mouseX) {
                    if (!enabled || width <= 0)
                        return;
                    const ratio = Math.max(0, Math.min(1, mouseX / width));
                    root.player.position = ratio * root.player.length;
                }

                onClicked: mouse => seek(mouse.x)

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: timeline.containsMouse && timeline.enabled ? 3 : 2
                    radius: 1
                    color: Services.Theme.track
                    opacity: 0.55

                    Behavior on height { NumberAnimation { duration: 120 } }
                }

                Rectangle {
                    width: parent.width * root.progress
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: timeline.containsMouse && timeline.enabled ? 3 : 2
                    radius: 1
                    color: root.accentColor

                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on height { NumberAnimation { duration: 120 } }
                }
            }
        }

        RowLayout {
            id: controls
            spacing: 1
            Layout.alignment: Qt.AlignVCenter

            component TransportButton: MouseArea {
                id: button
                property string icon: ""
                property bool actionEnabled: false
                signal activated()

                width: 24
                height: 28
                enabled: actionEnabled
                hoverEnabled: actionEnabled
                activeFocusOnTab: actionEnabled
                cursorShape: actionEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onPressed: forceActiveFocus()
                onClicked: activated()
                Keys.onReturnPressed: event => { event.accepted = true; activated(); }
                Keys.onEnterPressed: event => { event.accepted = true; activated(); }
                Keys.onSpacePressed: event => { event.accepted = true; activated(); }

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    color: root.accentColor
                    opacity: button.containsMouse ? 0.14 : 0
                }

                Text {
                    anchors.centerIn: parent
                    text: button.icon
                    font.family: "JetBrains Mono"
                    font.pixelSize: 15
                    color: button.containsMouse ? root.accentColor : root.textColor
                    opacity: button.actionEnabled ? 1 : 0.28
                }
            }

            TransportButton {
                visible: root.showTransport
                icon: "󰒮"
                actionEnabled: !!root.player && root.player.canGoPrevious
                onActivated: root.player.previous()
            }

            TransportButton {
                icon: root.playing ? "󰏤" : "󰐊"
                actionEnabled: !!root.player && root.player.canTogglePlaying
                onActivated: root.player.togglePlaying()
            }

            TransportButton {
                visible: root.showTransport
                icon: "󰒭"
                actionEnabled: !!root.player && root.player.canGoNext
                onActivated: root.player.next()
            }
        }
    }
}
