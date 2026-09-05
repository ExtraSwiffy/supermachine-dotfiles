import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

ShellRoot {
    IpcHandler {
        target: "quickmenu"

        function close() {
            QuickMenuState.close();
        }

        function status(): string {
            return `${QuickMenuState.open}:${QuickMenuState.configOpen}`;
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle() {
            WallpaperState.close();
            ControlCenterState.close();
            BadgeDeckState.close();
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
            BadgeDeckState.close();
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

        function enterDeck(index: int) {
            WallpaperState.enterDeck(index);
        }

        function back() {
            WallpaperState.back();
        }

        function status(): string {
            return `${WallpaperState.open}:${WallpaperState.browsingDecks ? "decks" : WallpaperState.deckTitle}:${WallpaperState.selectedName}`;
        }
    }

    IpcHandler {
        target: "controlcenter"

        function toggle() {
            LauncherState.close();
            WallpaperState.close();
            BadgeDeckState.close();
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
        target: "badges"

        function toggle() {
            LauncherState.close();
            WallpaperState.close();
            ControlCenterState.close();
            BadgeDeckState.toggle(Hyprland.focusedMonitor?.name ?? "");
        }

        function close() {
            BadgeDeckState.close();
        }

        function status(): string {
            return `${BadgeDeckState.open}:${ShellSettings.badgeSource}`;
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

        function setSnow(value: bool) {
            ShellSettings.setSnowEnabled(value);
        }

        function setBats(value: bool) {
            ShellSettings.setBatsEnabled(value);
        }

        function setRainSpeed(value: real) {
            ShellSettings.setRainSpeed(value);
        }

        function setLeafSpeed(value: real) {
            ShellSettings.setLeafSpeed(value);
        }

        function setSnowSpeed(value: real) {
            ShellSettings.setSnowSpeed(value);
        }

        function setBatSpeed(value: real) {
            ShellSettings.setBatSpeed(value);
        }

        function setFrameWidth(value: int) {
            ShellSettings.setFrameWidth(value);
        }

        function setWindowGap(value: int) {
            ShellSettings.setWindowGap(value);
        }

        function setWindowBorderColor(value: string) {
            ShellSettings.setWindowBorderColor(value);
        }

        function setPowerProfile(value: string) {
            ShellSettings.setPowerProfile(value);
        }

        function status(): string {
            return `${ShellSettings.badgeMode}:${ShellSettings.badgeText}:${ShellSettings.badgeSource}:${ShellSettings.badgeSize}:${ShellSettings.colorMode}:frame=${ShellSettings.frameWidth}:gap=${ShellSettings.windowGap}:border=${ShellSettings.windowBorderColor}:power=${ShellSettings.powerProfile}:rain=${ShellSettings.rainEnabled}@${ShellSettings.rainSpeed}:snow=${ShellSettings.snowEnabled}@${ShellSettings.snowSpeed}:leaves=${ShellSettings.leavesEnabled}@${ShellSettings.leafSpeed}:${ShellSettings.leafColor}:bats=${ShellSettings.batsEnabled}@${ShellSettings.batSpeed}`;
        }
    }

    Variants {
        model: Quickshell.screens
        ScreenShell {}
    }
}
