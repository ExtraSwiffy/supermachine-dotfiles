pragma Singleton
import QtQuick

QtObject {
    property bool open: false
    property string screenName: ""
    property int selectedIndex: 0

    function syncSelection() {
        const current = ShellSettings.badgeSource;
        for (let index = 0; index < ShellSettings.badgePresets.length; index++) {
            if (ShellSettings.badgePresets[index].source.toString() === current) {
                selectedIndex = index;
                return;
            }
        }
        selectedIndex = 0;
    }

    function select(index) {
        const count = ShellSettings.badgePresets.length;
        if (count < 1)
            return;
        selectedIndex = (index + count) % count;
        ShellSettings.setBadgePreset(ShellSettings.badgePresets[selectedIndex].source);
    }

    function step(amount) {
        select(selectedIndex + amount);
    }

    function toggle(name) {
        if (open && screenName === name) {
            open = false;
            return;
        }
        screenName = name;
        syncSelection();
        open = true;
    }

    function close() {
        open = false;
    }
}
