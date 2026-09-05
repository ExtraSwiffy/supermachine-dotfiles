pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string badgeMode: "image"
    property string badgeText: "🚀"
    property string badgeSource: Qt.resolvedUrl("assets/badges/whitetail-deer.webp").toString()
    property int badgeSize: 42
    property string colorMode: "dark"
    property bool rainEnabled: true
    property bool leavesEnabled: true
    property bool snowEnabled: false
    property bool batsEnabled: false
    property string leafColor: "#83ad62"
    property real rainSpeed: 1.0
    property real leafSpeed: 1.0
    property real snowSpeed: 1.0
    property real batSpeed: 1.0
    property int frameWidth: 9
    property int windowGap: 12
    property string windowBorderColor: "#86d9d9"
    property string powerProfile: "performance"

    readonly property var badgePresets: {
        const badges = [
            { name: "Whitetail", source: Qt.resolvedUrl("assets/badges/whitetail-deer.webp"), animated: false }
        ];
        if (GameState.roadrunnerUnlocked)
            badges.push({ name: "Roadrunner · 50", source: Qt.resolvedUrl("assets/badges/desert-roadrunner-50.webp"), animated: false });
        if (GameState.coyoteUnlocked)
            badges.push({ name: "Coyote · 100", source: Qt.resolvedUrl("assets/badges/desert-coyote-100.webp"), animated: false });
        return badges;
    }

    readonly property var emojiPresets: []

    property FileView settingsFile: FileView {
        path: `${Quickshell.shellDir}/user-settings.json`
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

    function normalizeSource(value) {
        const source = value.trim();
        if (source.startsWith("~/"))
            return `${Quickshell.env("HOME")}/${source.slice(2)}`;
        return source;
    }

    function load() {
        try {
            const raw = settingsFile.text();
            if (!raw.trim().length)
                return;
            const saved = JSON.parse(raw);
            badgeMode = saved.badgeMode ?? badgeMode;
            badgeText = saved.badgeText ?? badgeText;
            badgeSource = saved.badgeSource ?? badgeSource;
            badgeSize = saved.badgeSize ?? badgeSize;
            colorMode = saved.colorMode ?? colorMode;
            rainEnabled = saved.rainEnabled ?? rainEnabled;
            leavesEnabled = saved.leavesEnabled ?? leavesEnabled;
            leafColor = saved.leafColor ?? leafColor;
            rainSpeed = saved.rainSpeed ?? rainSpeed;
            leafSpeed = saved.leafSpeed ?? leafSpeed;
            snowEnabled = saved.snowEnabled ?? snowEnabled;
            batsEnabled = saved.batsEnabled ?? batsEnabled;
            snowSpeed = saved.snowSpeed ?? snowSpeed;
            batSpeed = saved.batSpeed ?? batSpeed;
            frameWidth = saved.frameWidth ?? frameWidth;
            windowGap = saved.windowGap ?? windowGap;
            windowBorderColor = saved.windowBorderColor ?? windowBorderColor;
            powerProfile = saved.powerProfile ?? powerProfile;
        } catch (error) {
            console.warn(`Could not load SuperMachine settings: ${error}`);
        }
    }

    function save() {
        settingsFile.setText(JSON.stringify({
            badgeMode,
            badgeText,
            badgeSource,
            badgeSize,
            colorMode,
            rainEnabled,
            leavesEnabled,
            leafColor,
            rainSpeed,
            leafSpeed,
            snowEnabled,
            batsEnabled,
            snowSpeed,
            batSpeed,
            frameWidth,
            windowGap,
            windowBorderColor,
            powerProfile
        }, null, 2));
    }

    function setBadgeMode(mode) {
        badgeMode = mode;
        save();
    }

    function validateBadge() {
        const allowed = badgePresets.some(badge => badge.source.toString() === badgeSource.toString());
        if (!allowed) {
            badgeMode = "image";
            badgeSource = Qt.resolvedUrl("assets/badges/whitetail-deer.webp").toString();
            save();
        }
    }

    function setBadgeText(value) {
        badgeText = value.length ? value : "🚀";
        save();
    }

    function setBadgeSource(value) {
        badgeSource = normalizeSource(value);
        save();
    }

    function setBadgePreset(source) {
        badgeSource = source.toString();
        badgeMode = "image";
        save();
    }

    function setEmojiPreset(value) {
        badgeText = value;
        badgeMode = "emoji";
        save();
    }

    function setBadgeSize(value) {
        badgeSize = Math.max(20, Math.min(42, value));
        save();
    }

    function setColorMode(value) {
        colorMode = value === "dark" ? "dark" : "light";
        save();
    }

    function setRainEnabled(value) {
        rainEnabled = value;
        save();
    }

    function setLeavesEnabled(value) {
        leavesEnabled = value;
        save();
    }

    function setSnowEnabled(value) {
        snowEnabled = value;
        save();
    }

    function setBatsEnabled(value) {
        batsEnabled = value;
        save();
    }

    function setLeafColor(value) {
        leafColor = value;
        save();
    }

    function setRainSpeed(value) {
        rainSpeed = Math.max(0.5, Math.min(2.0, value));
        save();
    }

    function setLeafSpeed(value) {
        leafSpeed = Math.max(0.5, Math.min(2.0, value));
        save();
    }

    function setSnowSpeed(value) {
        snowSpeed = Math.max(0.5, Math.min(2.0, value));
        save();
    }

    function setBatSpeed(value) {
        batSpeed = Math.max(0.5, Math.min(2.0, value));
        save();
    }

    function applyWindowSettings() {
        const color = `rgba(${windowBorderColor.slice(1)}ff)`;
        const code = `hl.config({ general = { gaps_in = ${windowGap}, gaps_out = ${windowGap}, col = { active_border = "${color}" } } })`;
        Quickshell.execDetached(["hyprctl", "eval", code]);
    }

    function setFrameWidth(value) {
        frameWidth = Math.max(5, Math.min(18, Math.round(value)));
        save();
    }

    function setWindowGap(value) {
        windowGap = Math.max(4, Math.min(30, Math.round(value)));
        applyWindowSettings();
        save();
    }

    function setWindowBorderColor(value) {
        windowBorderColor = value;
        applyWindowSettings();
        save();
    }

    function setPowerProfile(value) {
        if (["power-saver", "balanced", "performance"].indexOf(value) === -1)
            return;
        powerProfile = value;
        Quickshell.execDetached(["powerprofilesctl", "set", value]);
        save();
    }

    function enterConsoleMode() {
        save();
        Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/supermachine-console-mode`, "enter"]);
    }

    function viewLogs() {
        const log = `${Quickshell.env("HOME")}/.local/state/supermachine/logs/quickshell.log`;
        Quickshell.execDetached(["foot", "-e", "tail", "-n", "250", "-F", log]);
    }

    function createDiagnosticReport() {
        Quickshell.execDetached([`${Quickshell.env("HOME")}/.local/bin/supermachine-diagnostics`, "--open"]);
    }

    function resetBadge() {
        badgeMode = "image";
        badgeText = "🚀";
        badgeSource = Qt.resolvedUrl("assets/badges/whitetail-deer.webp").toString();
        badgeSize = 42;
        save();
    }

    Component.onCompleted: {
        load();
        // GameState loads its unlocks independently; defer validation until all
        // singletons have completed startup so an earned badge is never reset.
        Qt.callLater(root.validateBadge);
        applyWindowSettings();
        Quickshell.execDetached(["powerprofilesctl", "set", powerProfile]);
        // Also writes newly introduced defaults during settings migrations.
        save();
    }
}
