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

    IpcHandler {
        target: "wallpapers"

        function toggle() {
            LauncherState.close();
            WallpaperState.toggle(Hyprland.focusedMonitor?.name ?? "");
        }

        function close() {
            WallpaperState.close();
        }

        function next() {
            WallpaperState.step(1);
        }

        function previous() {
            WallpaperState.step(-1);
        }

        function status() {
            return `${WallpaperState.open}:${WallpaperState.selectedName}`;
        }
    }

    Variants {
        model: Quickshell.screens
        ScreenShell {}
    }
}
