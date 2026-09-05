pragma Singleton
import QtQuick

QtObject {
    property bool open: false
    property string screenName: ""

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
}
