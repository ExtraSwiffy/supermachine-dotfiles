import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    required property ShellScreen targetScreen

    screen: targetScreen
    color: "#101416"
    anchors { top: true; right: true; bottom: true; left: true }
    WlrLayershell.namespace: "supermachine-wallpaper"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    Image {
        anchors.fill: parent
        source: WallpaperState.selectedSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true

        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }
    }
}
