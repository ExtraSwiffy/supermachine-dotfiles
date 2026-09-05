import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property ShellScreen modelData

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // A click-through outline gives the desktop one continuous rounded edge.
    PanelWindow {
        screen: root.modelData
        color: "transparent"
        anchors { top: true; right: true; bottom: true; left: true }
        WlrLayershell.namespace: "supermachine-frame"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        Rectangle {
            anchors.fill: parent
            anchors.margins: Theme.frameInset
            color: "transparent"
            radius: Theme.outerRadius
            border.width: Theme.frameWidth
            border.color: Theme.border
        }
    }

    // The rail reserves only its own width. Everything else remains usable.
    PanelWindow {
        id: sidebar
        screen: root.modelData
        color: "transparent"
        implicitWidth: Theme.sidebarWidth
        anchors { top: true; bottom: true; left: true }
        margins {
            top: Theme.frameInset
            bottom: Theme.frameInset
            left: Theme.frameInset
        }
        WlrLayershell.namespace: "supermachine-sidebar"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: ExclusionMode.Normal

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            radius: Theme.sidebarRadius
            border.width: Theme.sidebarBorderWidth
            border.color: Theme.border

            Column {
                anchors.centerIn: parent
                spacing: 7

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "HH")
                    color: Theme.text
                    font.pixelSize: 25
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 24
                    height: 2
                    radius: 1
                    color: Theme.border
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "mm")
                    color: Theme.text
                    font.pixelSize: 25
                    font.weight: Font.DemiBold
                }

                Item { width: 1; height: 13 }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "ddd").toUpperCase()
                    color: Theme.muted
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "MMM d").toUpperCase()
                    color: Theme.text
                    font.pixelSize: 11
                    font.weight: Font.Medium
                }
            }
        }
    }
}
