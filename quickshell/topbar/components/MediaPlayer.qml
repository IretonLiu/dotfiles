import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../services" as Services

RowLayout {
    id: root
    spacing: 10
    clip: true
    
    // Explicit sizing for AestheticContainer
    implicitHeight: 28
    implicitWidth: mscLabel.width + trackInfo.Layout.preferredWidth + controlsRow.implicitWidth + progressCol.implicitWidth + (spacing * 3) + 12

    property color textColor: Services.Theme.highlight
    property color accentColor: Services.Theme.accent
    property color mutedColor: Services.Theme.muted

    readonly property var player: Services.Media.active
    readonly property real progress: (player && player.length > 0) ? player.position / player.length : 0

    // --- DECORATIVE: MEDIA LABEL ---
    Item {
        id: mscLabel
        width: 8
        Layout.fillHeight: true
        
        Text {
            anchors.centerIn: parent
            text: "MSC"
            font.family: "JetBrains Mono"
            font.pixelSize: 9
            color: root.accentColor
            opacity: 0.5
            rotation: -90
            width: 30
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 1; height: parent.height - 10
            color: root.accentColor
            opacity: 0.2
        }
    }

    // --- TRACK INFO (130px Width) ---
    ColumnLayout {
        id: trackInfo
        spacing: -3
        Layout.preferredWidth: 130
        Layout.minimumWidth: 36
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        clip: true
        
        Text {
            function getPrettyId(id) {
                if (!id) return "NONE";
                var lid = id.toLowerCase();
                if (lid.indexOf("spotify") !== -1) return "SPOTIFY";
                if (lid.indexOf("chromium") !== -1 || lid.indexOf("chrome") !== -1) return "YOUTUBE";
                if (lid.indexOf("firefox") !== -1) return "FIREFOX";
                return id.toUpperCase();
            }
            text: "ID_" + getPrettyId(root.player ? root.player.identity : "")
            font.family: "JetBrains Mono"
            font.pixelSize: 8
            font.weight: Font.Bold
            color: root.accentColor
            opacity: 0.5
        }

        // --- SCROLLING TITLE ---
        Item {
            id: titleViewport
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            clip: true

            Text {
                id: scrollingTitle
                text: (root.player && root.player.trackTitle) ? root.player.trackTitle.toUpperCase() : "NO_MEDIA"
                font.family: "JetBrains Mono"
                font.pixelSize: 12
                font.bold: true
                color: root.textColor

                readonly property real scrollDistance: Math.max(0, implicitWidth - titleViewport.width)
                readonly property bool needsScroll: scrollDistance > 0

                function restartMarquee() {
                    x = 0
                    if (needsScroll)
                        titleMarquee.restart()
                }

                onTextChanged: restartMarquee()
                onScrollDistanceChanged: restartMarquee()
                onNeedsScrollChanged: {
                    if (!needsScroll) {
                        titleMarquee.stop()
                        x = 0
                    }
                }

                SequentialAnimation {
                    id: titleMarquee
                    running: scrollingTitle.needsScroll
                    loops: Animation.Infinite

                    PauseAnimation { duration: 2000 }
                    NumberAnimation {
                        target: scrollingTitle
                        property: "x"
                        from: 0
                        to: -scrollingTitle.scrollDistance
                        duration: Math.max(2000, scrollingTitle.scrollDistance * 30)
                        easing.type: Easing.Linear
                    }
                    PauseAnimation { duration: 2000 }
                    PropertyAction {
                        target: scrollingTitle
                        property: "x"
                        value: 0
                    }
                }
            }
        }

        // --- SCROLLING ARTIST ---
        Item {
            id: artistViewport
            Layout.fillWidth: true
            Layout.preferredHeight: 10
            clip: true

            Text {
                id: scrollingArtist
                text: (root.player && root.player.trackArtist) ? root.player.trackArtist : "---"
                font.family: "JetBrains Mono"
                font.pixelSize: 9
                color: root.mutedColor

                readonly property real scrollDistance: Math.max(0, implicitWidth - artistViewport.width)
                readonly property bool needsScroll: scrollDistance > 0

                function restartMarquee() {
                    x = 0
                    if (needsScroll)
                        artistMarquee.restart()
                }

                onTextChanged: restartMarquee()
                onScrollDistanceChanged: restartMarquee()
                onNeedsScrollChanged: {
                    if (!needsScroll) {
                        artistMarquee.stop()
                        x = 0
                    }
                }

                SequentialAnimation {
                    id: artistMarquee
                    running: scrollingArtist.needsScroll
                    loops: Animation.Infinite

                    PauseAnimation { duration: 3000 }
                    NumberAnimation {
                        target: scrollingArtist
                        property: "x"
                        from: 0
                        to: -scrollingArtist.scrollDistance
                        duration: Math.max(2000, scrollingArtist.scrollDistance * 40)
                        easing.type: Easing.Linear
                    }
                    PauseAnimation { duration: 3000 }
                    PropertyAction {
                        target: scrollingArtist
                        property: "x"
                        value: 0
                    }
                }
            }
        }
    }

    // --- CONTROLS ---
    Row {
        id: controlsRow
        spacing: 1
        Layout.alignment: Qt.AlignVCenter
        visible: root.width >= 145

        component ControlButton: MouseArea {
            id: btn
            property string icon: ""
            property bool enabled: true
            
            width: 18; height: 18
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            hoverEnabled: true
            
            Text {
                anchors.centerIn: parent
                text: icon
                font.family: "JetBrains Mono"
                font.pixelSize: 14
                color: btn.containsMouse ? root.accentColor : root.textColor
                opacity: btn.enabled ? 1.0 : 0.3
            }
        }

            ControlButton {
                icon: "󰒮"
                enabled: root.player && root.player.canGoPrevious
                onClicked: root.player.previous()
            }

            ControlButton {
                icon: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                enabled: root.player && root.player.canTogglePlaying
                onClicked: root.player.togglePlaying()
            }

            ControlButton {
                icon: "󰒭"
                enabled: root.player && root.player.canGoNext
                onClicked: root.player.next()
            }
    }

    // --- PROGRESS BAR (Geometric Minimalist Style) ---
    Column {
        id: progressCol
        spacing: 1
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: 14
        visible: root.player && root.player.length > 0 && root.width >= 210
        
        Row {
            spacing: 6
            anchors.right: parent.right
            Text {
                text: "TRK"
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                font.weight: Font.Bold
                color: root.mutedColor
            }
            Text {
                text: "0x" + Math.round(root.progress * 255).toString(16).toUpperCase()
                font.family: "JetBrains Mono"
                font.pixelSize: 8
                color: root.accentColor
                opacity: 0.6
            }
        }

        Item {
            width: 42
            height: 4
            
            // Track Background
            Rectangle {
                anchors.fill: parent
                color: Services.Theme.track
                opacity: 0.3
                radius: 1
            }
            
            // Progress Fill (Solid & Clean)
            Rectangle {
                width: parent.width * root.progress
                height: 2
                anchors.verticalCenter: parent.verticalCenter
                color: root.accentColor
                radius: 1
            }
            
            // Start Marker
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 2; height: 6
                color: root.accentColor
            }

            // End Marker
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 1; height: 6
                color: root.mutedColor
                opacity: 0.4
            }
        }
    }
}
