pragma Singleton
import QtQuick

QtObject {
    property bool open: false
    property string screenName: ""
    property real requestedX: 100
    property real requestedY: 100
    property bool configOpen: false

    function show(screen, x, y) {
        screenName = screen;
        requestedX = x;
        requestedY = y;
        configOpen = false;
        open = true;
    }

    function close() {
        open = false;
        configOpen = false;
    }
}
