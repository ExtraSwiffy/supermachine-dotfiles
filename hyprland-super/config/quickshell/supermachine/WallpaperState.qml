pragma Singleton
import QtQuick

QtObject {
    property bool open: false
    property string screenName: ""
    // Redwood Creek is the curated out-of-box default.
    property int selectedIndex: 4

    readonly property var wallpapers: [
        { name: "Alpine Morning", source: Qt.resolvedUrl("assets/wallpapers/alpine-morning.webp") },
        { name: "Canyon Glow", source: Qt.resolvedUrl("assets/wallpapers/canyon-glow.webp") },
        { name: "Aurora Lake", source: Qt.resolvedUrl("assets/wallpapers/aurora-lake.webp") },
        { name: "Coral Coast", source: Qt.resolvedUrl("assets/wallpapers/coral-coast.webp") },
        { name: "Redwood Creek", source: Qt.resolvedUrl("assets/wallpapers/redwood-creek.webp") },
        { name: "Blossom Valley", source: Qt.resolvedUrl("assets/wallpapers/blossom-valley.webp") },
        { name: "Volcanic Island", source: Qt.resolvedUrl("assets/wallpapers/volcanic-island.webp") },
        { name: "Autumn Falls", source: Qt.resolvedUrl("assets/wallpapers/autumn-falls.webp") },
        { name: "Bioluminescent Forest", source: Qt.resolvedUrl("assets/wallpapers/bioluminescent-forest.webp") },
        { name: "Lavender Hills", source: Qt.resolvedUrl("assets/wallpapers/lavender-hills.webp") },
        { name: "Moonlit Dunes", source: Qt.resolvedUrl("assets/wallpapers/moonlit-dunes.webp") },
        { name: "Monsoon Valley", source: Qt.resolvedUrl("assets/wallpapers/monsoon-valley.webp") },
        { name: "Floating Islands", source: Qt.resolvedUrl("assets/wallpapers/floating-islands.webp") },
        { name: "Bamboo River", source: Qt.resolvedUrl("assets/wallpapers/bamboo-river.webp") },
        { name: "Wildflower Meadow", source: Qt.resolvedUrl("assets/wallpapers/wildflower-meadow.webp") },
        { name: "Glacier Fjord", source: Qt.resolvedUrl("assets/wallpapers/glacier-fjord.webp") },
        { name: "Mangrove Lagoon", source: Qt.resolvedUrl("assets/wallpapers/mangrove-lagoon.webp") },
        { name: "Red Maple Lake", source: Qt.resolvedUrl("assets/wallpapers/red-maple-lake.webp") },
        { name: "Celestial Clouds", source: Qt.resolvedUrl("assets/wallpapers/celestial-clouds.webp") },
        { name: "Sunflower Plains", source: Qt.resolvedUrl("assets/wallpapers/sunflower-plains.webp") },
        { name: "Crystal Cavern", source: Qt.resolvedUrl("assets/wallpapers/crystal-cavern.webp") },
        { name: "Golden Savanna", source: Qt.resolvedUrl("assets/wallpapers/golden-savanna.webp") },
        { name: "Storm Cliffs", source: Qt.resolvedUrl("assets/wallpapers/storm-cliffs.webp") },
        { name: "Pastel Mushrooms", source: Qt.resolvedUrl("assets/wallpapers/pastel-mushrooms.webp") },
        { name: "Snowy Cabin River", source: Qt.resolvedUrl("assets/wallpapers/snowy-cabin-river.webp") },
        { name: "Winter Covered Bridge", source: Qt.resolvedUrl("assets/wallpapers/winter-covered-bridge.webp") },
        { name: "Frozen Aurora Lake", source: Qt.resolvedUrl("assets/wallpapers/frozen-aurora-lake.webp") },
        { name: "Christmas Village", source: Qt.resolvedUrl("assets/wallpapers/christmas-village.webp") },
        { name: "Christmas Forest Cabin", source: Qt.resolvedUrl("assets/wallpapers/christmas-forest-cabin.webp") },
        { name: "Camp Lake Jason", source: Qt.resolvedUrl("assets/wallpapers/camp-lake-jason.webp") },
        { name: "Halloween Street Michael", source: Qt.resolvedUrl("assets/wallpapers/halloween-street-michael.webp") },
        { name: "Boiler Dream Freddy", source: Qt.resolvedUrl("assets/wallpapers/boiler-dream-freddy.webp") },
        { name: "Enchanted Pumpkin Forest", source: Qt.resolvedUrl("assets/wallpapers/enchanted-pumpkin-forest.webp") },
        { name: "Moonlit Bat Cemetery", source: Qt.resolvedUrl("assets/wallpapers/moonlit-bat-cemetery.webp") }
    ]

    readonly property url selectedSource: wallpapers.length > selectedIndex ? wallpapers[selectedIndex].source : ""
    readonly property string selectedName: wallpapers.length > selectedIndex ? wallpapers[selectedIndex].name : ""

    function thumbnailFor(source) {
        return source.toString().replace("/wallpapers/", "/wallpapers/thumbs/");
    }

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
