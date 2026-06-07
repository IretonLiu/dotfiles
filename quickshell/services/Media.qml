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

    // Update active player whenever the list or any player's state changes
    function updateActive() {
        if (players.length === 0) {
            active = null;
            return;
        }

        var best = null;
        for (var i = 0; i < players.length; i++) {
            var p = players[i];
            var id = p.identity.toLowerCase();
            
            // Priority: Spotify Playing > Any Playing > Spotify Paused > First Available
            if (p.playbackState === MprisPlaybackState.Playing) {
                if (id.indexOf("spotify") !== -1) {
                    active = p;
                    return;
                }
                if (!best) best = p;
            }
        }

        if (best) {
            active = best;
            return;
        }

        // Check for paused Spotify
        for (var i = 0; i < players.length; i++) {
            if (players[i].identity.toLowerCase().indexOf("spotify") !== -1) {
                active = players[i];
                return;
            }
        }

        active = players[0];
    }

    // React to list changes
    onPlayersChanged: updateActive()

    // Periodically refresh to catch state changes if bindings miss them
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateActive()
    }

    Component.onCompleted: updateActive()
}
