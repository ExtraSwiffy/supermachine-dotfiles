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
        } catch (error) {
            console.warn(`Could not load SuperMachine settings: ${error}`);
        }
    }

    function save() {
        settingsFile.setText(JSON.stringify({
            badgeMode,
            badgeText,
            badgeSource,
            badgeSize
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

    function setBadgeSize(value) {
        badgeSize = Math.max(20, Math.min(42, value));
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
