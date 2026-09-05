import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property ShellScreen modelData

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    // One continuous surface: a wide left rail flowing into thin screen edges.
    PanelWindow {
        id: frame
        screen: root.modelData
        color: "transparent"
        anchors { top: true; right: true; bottom: true; left: true }
        WlrLayershell.namespace: "supermachine-frame"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        mask: Region {}

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Theme.surface
                strokeColor: "transparent"
                fillRule: ShapePath.OddEvenFill

                PathSvg {
                    path: {
                        const w = frame.width;
                        const h = frame.height;
                        const x = Theme.sidebarWidth;
                        const y = Theme.frameWidth;
                        const right = w - Theme.frameWidth;
                        const bottom = h - Theme.frameWidth;
                        const r = Theme.innerRadius;

                        return `M 0 0 H ${w} V ${h} H 0 Z `
                            + `M ${x + r} ${y} H ${right - r} `
                            + `Q ${right} ${y} ${right} ${y + r} `
                            + `V ${bottom - r} Q ${right} ${bottom} ${right - r} ${bottom} `
                            + `H ${x + r} Q ${x} ${bottom} ${x} ${bottom - r} `
                            + `V ${y + r} Q ${x} ${y} ${x + r} ${y} Z`;
                    }
                }
            }
        }

        Column {
            x: Math.round((Theme.sidebarWidth - width) / 2)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "HH")
                color: Theme.ink
                font.pixelSize: 25
                font.weight: Font.DemiBold
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 24
                height: 2
                radius: 1
                color: Theme.ink
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "mm")
                color: Theme.ink
                font.pixelSize: 25
                font.weight: Font.DemiBold
            }

            Item { width: 1; height: 13 }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "ddd").toUpperCase()
                color: Theme.mutedInk
                font.pixelSize: 10
                font.letterSpacing: 1.5
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDateTime(clock.date, "MMM d").toUpperCase()
                color: Theme.ink
                font.pixelSize: 11
                font.weight: Font.Medium
            }
        }
    }

    // This invisible layer reserves the same width as the visible rail.
    PanelWindow {
        screen: root.modelData
        color: "transparent"
        implicitWidth: Theme.sidebarWidth
        anchors { top: true; bottom: true; left: true }
        WlrLayershell.namespace: "supermachine-sidebar-reserve"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: ExclusionMode.Normal
        mask: Region {}
    }
}
