pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    property bool open: false
    property string screenName: ""
    // Redwood Creek is the curated out-of-box default.
    property int selectedIndex: 4
    property bool browsingDecks: true
    property int selectedDeckIndex: 0
    property int selectedCardIndex: 0
    property int previewIndex: -1

    property FileView settingsFile: FileView {
        path: `${Quickshell.shellDir}/wallpaper-settings.json`
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

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

    readonly property int displayIndex: previewIndex >= 0 ? previewIndex : selectedIndex
    readonly property url selectedSource: wallpapers.length > displayIndex ? wallpapers[displayIndex].source : ""
    readonly property string selectedName: wallpapers.length > displayIndex ? wallpapers[displayIndex].name : ""

    readonly property var decks: [
        { name: "Scenic Nature", detail: "13 landscapes", indices: [0, 1, 3, 4, 5, 7, 9, 13, 14, 16, 17, 19, 21] },
        { name: "Fantasy Worlds", detail: "11 dreamscapes", indices: [2, 6, 8, 10, 11, 12, 15, 18, 20, 22, 23] },
        { name: "Winter", detail: "3 snowy scenes", indices: [24, 25, 26] },
        { name: "Christmas", detail: "2 festive scenes", indices: [27, 28] },
        { name: "Halloween", detail: "5 spooky scenes", indices: [29, 30, 31, 32, 33] }
    ]

    readonly property var deckCards: decks.map((deck, index) => ({
        name: deck.name,
        detail: deck.detail,
        source: wallpapers[deck.indices[0]].source,
        deckIndex: index
    }))
    readonly property var wallpaperCards: decks[selectedDeckIndex].indices.map(wallpaperIndex => ({
        name: wallpapers[wallpaperIndex].name,
        source: wallpapers[wallpaperIndex].source,
        wallpaperIndex
    }))
    readonly property var visibleCards: browsingDecks ? deckCards : wallpaperCards
    readonly property int visibleIndex: browsingDecks ? selectedDeckIndex : selectedCardIndex
    readonly property string deckTitle: browsingDecks ? "Wallpaper Decks" : decks[selectedDeckIndex].name

    function thumbnailFor(source) {
        return source.toString().replace("/wallpapers/", "/wallpapers/thumbs/");
    }

    function load() {
        try {
            const raw = settingsFile.text();
            if (!raw.trim().length)
                return;
            const saved = JSON.parse(raw);
            const index = Number(saved.selectedIndex);
            if (index >= 0 && index < wallpapers.length)
                selectedIndex = index;
        } catch (error) {
            console.warn(`Could not load wallpaper choice: ${error}`);
        }
    }

    function save() {
        settingsFile.setText(JSON.stringify({
            selectedIndex,
            selectedName: wallpapers[selectedIndex].name
        }, null, 2));
    }

    function toggle(name) {
        if (open && screenName === name) {
            open = false;
            return;
        }

        screenName = name;
        showDeckChooser();
        open = true;
    }

    function close() {
        previewIndex = -1;
        open = false;
    }

    function select(index) {
        if (index >= 0 && index < wallpapers.length) {
            selectedIndex = index;
            save();
        }
    }

    function step(amount) {
        const count = visibleCards.length;
        if (!count)
            return;
        if (browsingDecks)
            selectedDeckIndex = (selectedDeckIndex + amount + count) % count;
        else {
            selectedCardIndex = (selectedCardIndex + amount + count) % count;
            previewIndex = visibleCards[selectedCardIndex].wallpaperIndex;
        }
    }

    function showDeckChooser() {
        browsingDecks = true;
        for (let i = 0; i < decks.length; i++) {
            if (decks[i].indices.indexOf(selectedIndex) !== -1) {
                selectedDeckIndex = i;
                break;
            }
        }
    }

    function enterDeck(index) {
        if (index < 0 || index >= decks.length)
            return;
        selectedDeckIndex = index;
        const currentPosition = decks[index].indices.indexOf(selectedIndex);
        selectedCardIndex = currentPosition === -1 ? 0 : currentPosition;
        previewIndex = decks[index].indices[selectedCardIndex];
        browsingDecks = false;
    }

    function chooseVisible(index) {
        if (index < 0 || index >= visibleCards.length)
            return;
        if (browsingDecks) {
            enterDeck(index);
            return;
        }
        selectedCardIndex = index;
        previewIndex = visibleCards[index].wallpaperIndex;
    }

    function activate() {
        if (browsingDecks)
            enterDeck(selectedDeckIndex);
        else {
            if (previewIndex >= 0)
                select(previewIndex);
            previewIndex = -1;
            close();
        }
    }

    function back() {
        if (browsingDecks)
            close();
        else {
            previewIndex = -1;
            browsingDecks = true;
        }
    }

    Component.onCompleted: load()
}
