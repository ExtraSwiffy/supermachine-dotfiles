pragma Singleton
import QtQuick

QtObject {
    property bool open: false
    property string screenName: ""
    property int selectedIndex: 0

    readonly property var wallpapers: [
        { name: "Alpine Morning", source: Qt.resolvedUrl("assets/wallpapers/alpine-morning.webp") },
        { name: "Canyon Glow", source: Qt.resolvedUrl("assets/wallpapers/canyon-glow.webp") },
        { name: "Aurora Lake", source: Qt.resolvedUrl("assets/wallpapers/aurora-lake.webp") },
        { name: "Coral Coast", source: Qt.resolvedUrl("assets/wallpapers/coral-coast.webp") }
    ]

    readonly property url selectedSource: wallpapers.length > selectedIndex ? wallpapers[selectedIndex].source : ""
    readonly property string selectedName: wallpapers.length > selectedIndex ? wallpapers[selectedIndex].name : ""

    function toggle(name) {
        if (open && screenName === name) {
            open = false;
            return;
        }

        screenName = name;
        open = true;
    }

    function close() {
        open = false;
    }

    function select(index) {
        if (index >= 0 && index < wallpapers.length)
            selectedIndex = index;
    }

    function step(amount) {
        const count = wallpapers.length;
        if (count > 0)
            selectedIndex = (selectedIndex + amount + count) % count;
    }
}
