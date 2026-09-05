import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

ShellRoot {
    IpcHandler {
        target: "launcher"

        function toggle() {
            LauncherState.toggle(Hyprland.focusedMonitor?.name ?? "");
        }

        function close() {
            LauncherState.close();
        }

        function status() {
            return `${LauncherState.open}:${LauncherState.screenName}`;
        }
    }

    Variants {
        model: Quickshell.screens
        ScreenShell {}
    }
}
