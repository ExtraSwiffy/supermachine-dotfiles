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

        function openSection(section: string) {
            LauncherState.close();
            WallpaperState.close();
            ControlCenterState.show(section);
            ControlCenterState.screenName = Hyprland.focusedMonitor?.name ?? "";
            ControlCenterState.open = true;
        }

        function status(): string {
            return `${ControlCenterState.open}:${ControlCenterState.section}`;
        }
    }

    IpcHandler {
        target: "settings"

        function setEmoji(value: string) {
            ShellSettings.setEmojiPreset(value);
        }

        function setImage(value: string) {
            ShellSettings.setBadgePreset(value);
        }

        function resetBadge() {
            ShellSettings.resetBadge();
        }

        function setColorMode(value: string) {
            ShellSettings.setColorMode(value);
        }

        function setRain(value: bool) {
            ShellSettings.setRainEnabled(value);
        }

        function setLeaves(value: bool) {
            ShellSettings.setLeavesEnabled(value);
        }

        function status(): string {
            return `${ShellSettings.badgeMode}:${ShellSettings.badgeText}:${ShellSettings.badgeSource}:${ShellSettings.badgeSize}:${ShellSettings.colorMode}:rain=${ShellSettings.rainEnabled}:leaves=${ShellSettings.leavesEnabled}:${ShellSettings.leafColor}`;
        }
    }

    Variants {
        model: Quickshell.screens
        ScreenShell {}
    }
}
