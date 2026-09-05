pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string badgeMode: "emoji"
    property string badgeText: "🚀"
    property string badgeSource: ""
    property int badgeSize: 30
    property string colorMode: "light"
    property bool rainEnabled: false
    property bool leavesEnabled: false
    property string leafColor: "#e58a45"

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
            leafColor
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

    function setLeafColor(value) {
        leafColor = value;
        save();
    }

    function resetBadge() {
        badgeMode = "emoji";
        badgeText = "🚀";
        badgeSource = "";
        badgeSize = 30;
        save();
    }

    Component.onCompleted: load()
}
