pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool open: false
    property string screenName: ""
    property string page: "library"
    property int bestJumps: 0
    readonly property bool roadrunnerUnlocked: bestJumps >= 50
    readonly property bool coyoteUnlocked: bestJumps >= 100

    property FileView saveFile: FileView {
        path: `${Quickshell.shellDir}/game-progress.json`
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

    function load() {
        try {
            const raw = saveFile.text();
            if (raw.trim().length)
                bestJumps = Math.max(0, Number(JSON.parse(raw).bestJumps ?? 0));
        } catch (error) {
            console.warn(`Could not load game progress: ${error}`);
        }
    }

    function save() {
        saveFile.setText(JSON.stringify({ bestJumps }, null, 2));
    }

    function record(jumps) {
        if (jumps <= bestJumps)
            return;
        bestJumps = jumps;
        save();
    }

    function toggle(screen) {
        screenName = screen;
        open = !open;
        if (open)
            page = "library";
    }

    function close() {
        open = false;
        page = "library";
    }

    Component.onCompleted: load()
}
