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

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: mouse => {
            LauncherState.close();
            WallpaperState.close();
            ControlCenterState.close();
            BadgeDeckState.close();
            QuickMenuState.show(targetScreen.name, mouse.x, mouse.y);
        }
    }
}
