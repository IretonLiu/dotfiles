pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // Use the native list property for better reactivity
    readonly property list<MprisPlayer> players: Mpris.players.values
    
    // Explicitly track the active player
    property MprisPlayer active: null

    // Prefer an actively playing source, while retaining the current paused
    // player instead of unexpectedly snapping back to Spotify or list order.
    function updateActive() {
        if (players.length === 0) {
            active = null;
            return;
        }

        let currentIsPresent = false;
        for (let index = 0; index < players.length; index++) {
            if (players[index] === active) {
                currentIsPresent = true;
                break;
            }
        }
        if (currentIsPresent && active.playbackState === MprisPlaybackState.Playing)
            return;

        const playing = players.find(player => player.playbackState === MprisPlaybackState.Playing);
        if (playing) {
            active = playing;
            return;
        }

        if (!currentIsPresent)
            active = players[0];
    }

    // React to list changes
    onPlayersChanged: updateActive()

    // Periodically refresh to catch state changes if bindings miss them
    Timer {
        interval: 750
        running: true
        repeat: true
        onTriggered: root.updateActive()
    }

    Component.onCompleted: updateActive()
}
