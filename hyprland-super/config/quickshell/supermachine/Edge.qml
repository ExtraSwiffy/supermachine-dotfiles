import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property ShellScreen targetScreen
    property string edge: "top"

    screen: targetScreen
    color: "transparent"
    WlrLayershell.namespace: "supermachine-frame"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    anchors {
        top: root.edge === "top"
        bottom: root.edge === "bottom"
        left: root.edge === "left"
        right: root.edge === "right"
    }
    implicitWidth: Theme.frameWidth
    implicitHeight: Theme.frameWidth

    Rectangle {
        anchors.fill: parent
        color: Theme.border
    }
}
