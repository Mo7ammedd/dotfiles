import qs
import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Io

// Small compatibility surface for the user's existing Caelestia shortcuts.
// Instantiate once as PreservedShortcuts {} inside shell.qml's ShellRoot.
Scope {
    IpcHandler {
        target: "preservedShortcuts"

        function toggleNightLight(): void {
            Config.options.light.night.colorTemperature = 4500;
            Hyprsunset.toggleTemperature();
        }

        function clearNotifications(): void {
            Notifications.discardAllNotifications();
        }

        function showAll(): void {
            const open = !(GlobalStates.overviewOpen
                || GlobalStates.sidebarRightOpen || GlobalStates.mediaControlsOpen);
            GlobalStates.overviewOpen = open;
            GlobalStates.sidebarRightOpen = open;
            GlobalStates.mediaControlsOpen = open;
        }
    }
}
