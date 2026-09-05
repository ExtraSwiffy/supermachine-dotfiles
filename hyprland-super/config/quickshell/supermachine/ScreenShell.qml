import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property ShellScreen modelData

    Variants {
        model: ["top", "right", "bottom"]
        Edge {
            required property string modelData
            targetScreen: root.modelData
            edge: modelData
        }
    }

    PanelWindow {
        id: sidebar
        screen: root.modelData
        color: "transparent"
        implicitWidth: Theme.sidebarWidth
        anchors { top: true; bottom: true; left: true }
        margins { top: Theme.frameWidth; bottom: Theme.frameWidth; left: Theme.frameWidth }
        WlrLayershell.namespace: "supermachine-sidebar"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: ExclusionMode.Normal

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            radius: Theme.radius
            border.width: Theme.frameWidth
            border.color: Theme.border

            Column {
                anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 16 }
                spacing: 12

                Rectangle {
                    width: 34; height: 34; radius: 12
                    color: launcher.containsMouse ? Theme.surfaceHover : Theme.surface
                    Text { anchors.centerIn: parent; text: "◆"; color: Theme.border; font.pixelSize: 16 }
                    MouseArea { id: launcher; anchors.fill: parent; hoverEnabled: true }
                }

                Repeater {
                    model: 5
                    Rectangle {
                        width: 30; height: 30; radius: 10
                        color: index === 0 ? Theme.border : Theme.surface
                        Text { anchors.centerIn: parent; text: index + 1; color: index === 0 ? "#0a1012" : Theme.text }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: topMenu
        screen: root.modelData
        color: "transparent"
        implicitWidth: 420
        implicitHeight: menuOpen ? 92 : 8
        anchors { top: true }
        margins { top: Theme.frameWidth }
        WlrLayershell.namespace: "supermachine-top-menu"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: ExclusionMode.Ignore

        property bool menuOpen: hover.containsMouse
        Behavior on implicitHeight { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            radius: Theme.radius
            border.width: Theme.frameWidth
            border.color: Theme.border
            clip: true

            Row {
                anchors.centerIn: parent
                spacing: 34
                opacity: topMenu.menuOpen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Repeater {
                    model: ["WORK", "MEDIA", "SYSTEM"]
                    Text { required property string modelData; text: modelData; color: Theme.text; font.pixelSize: 12; font.letterSpacing: 2 }
                }
            }
            MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true }
        }
    }
}
