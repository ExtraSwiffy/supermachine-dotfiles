import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

ShellRoot {
    IpcHandler {
        target: "launcher"

        function toggle() {
            WallpaperState.close();
            ControlCenterState.close();
            LauncherState.toggle(Hyprland.focusedMonitor?.name ?? "");
        }

        function close() {
            LauncherState.close();
        }

        function status(): string {
            return `${LauncherState.open}:${LauncherState.screenName}`;
        }
    }

    IpcHandler {
        target: "wallpapers"

        function toggle() {
            LauncherState.close();
            ControlCenterState.close();
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

        function status(): string {
            return `${WallpaperState.open}:${WallpaperState.selectedName}`;
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle() {
            LauncherState.close();
            WallpaperState.close();
            ControlCenterState.toggle(Hyprland.focusedMonitor?.name ?? "");
        }

        function close() {
            ControlCenterState.close();
        }

        function status(): string {
            return `${ControlCenterState.open}:${ControlCenterState.section}`;
        }
    }

    IpcHandler {
        target: "settings"

        function setEmoji(value: string) {
            ShellSettings.setBadgeMode("emoji");
            ShellSettings.setBadgeText(value);
        }

        function setImage(value: string) {
            ShellSettings.setBadgeSource(value);
            ShellSettings.setBadgeMode("image");
        }

        function resetBadge() {
            ShellSettings.resetBadge();
        }

        function status(): string {
            return `${ShellSettings.badgeMode}:${ShellSettings.badgeText}:${ShellSettings.badgeSource}:${ShellSettings.badgeSize}`;
        }
    }

    Variants {
        model: Quickshell.screens
        ScreenShell {}
    }
}
