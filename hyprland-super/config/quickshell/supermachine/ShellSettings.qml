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

    readonly property var badgePresets: [
        { name: "Rocket", source: Qt.resolvedUrl("assets/badges/rocket.webp"), animated: false },
        { name: "Robot", source: Qt.resolvedUrl("assets/badges/robot.webp"), animated: false },
        { name: "Moon", source: Qt.resolvedUrl("assets/badges/moon-cloud.webp"), animated: false },
        { name: "Crystal", source: Qt.resolvedUrl("assets/badges/crystal.webp"), animated: false },
        { name: "Fox", source: Qt.resolvedUrl("assets/badges/fox.webp"), animated: false },
        { name: "Frog", source: Qt.resolvedUrl("assets/badges/frog.webp"), animated: false },
        { name: "Coffee", source: Qt.resolvedUrl("assets/badges/coffee.webp"), animated: false },
        { name: "Windmill", source: Qt.resolvedUrl("assets/badges/ranch-windmill.webp"), animated: false },
        { name: "Red barn", source: Qt.resolvedUrl("assets/badges/red-barn.webp"), animated: false },
        { name: "Whitetail", source: Qt.resolvedUrl("assets/badges/whitetail-deer.webp"), animated: false },
        { name: "Rocket loop", source: Qt.resolvedUrl("assets/badges/rocket-flight.gif"), animated: true },
        { name: "Moon drift", source: Qt.resolvedUrl("assets/badges/moon-drift.gif"), animated: true },
        { name: "Crystal pulse", source: Qt.resolvedUrl("assets/badges/crystal-pulse.gif"), animated: true },
        { name: "Coffee steam", source: Qt.resolvedUrl("assets/badges/coffee-steam.gif"), animated: true },
        { name: "Windmill spin", source: Qt.resolvedUrl("assets/badges/windmill-spin.gif"), animated: true }
    ]

    readonly property var emojiPresets: ["🚀", "⚡", "🌙", "🛸", "🐸", "🦊", "💎", "🌈"]

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
        applyWindowSettings();
        Quickshell.execDetached(["powerprofilesctl", "set", powerProfile]);
        // Also writes newly introduced defaults during settings migrations.
        save();
    }
}
