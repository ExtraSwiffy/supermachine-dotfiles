import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root
    required property ShellScreen targetScreen

    function spread(index, salt, span) {
        return ((index * 197 + salt * 83) % 997) / 997 * span;
    }

    screen: targetScreen
    color: "transparent"
    anchors { top: true; right: true; bottom: true; left: true }
    WlrLayershell.namespace: "supermachine-wallpaper-effects"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    Item {
        anchors.fill: parent
        visible: ShellSettings.rainEnabled

        Repeater {
            model: 70
            Rectangle {
                required property int index
                x: root.spread(index, 4, root.width)
                y: -height - root.spread(index, 8, root.height)
                width: index % 4 === 0 ? 2 : 1
                height: 16 + index % 5 * 6
                radius: width
                color: index % 3 === 0 ? "#b9eeff" : "#e5f8ff"
                opacity: 0.34 + (index % 5) * 0.08
                rotation: 10

                NumberAnimation on y {
                    running: ShellSettings.rainEnabled
                    loops: Animation.Infinite
                    from: -80 - root.spread(index, 2, root.height)
                    to: root.height + 100
                    duration: 1350 + (index % 7) * 125
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: ShellSettings.leavesEnabled

        Repeater {
            model: 28
            Item {
                id: leaf
                required property int index
                property real baseX: root.spread(index, 11, root.width)
                x: baseX
                y: -50 - root.spread(index, 15, root.height)
                width: 20
                height: 14

                Rectangle {
                    anchors.centerIn: parent
                    width: 16
                    height: 10
                    radius: 8
                    color: ShellSettings.leafColor
                    opacity: 0.62 + (leaf.index % 4) * 0.09
                    transform: Rotation { origin.x: 8; origin.y: 5; angle: leaf.index * 31 }
                }

                NumberAnimation on y {
                    running: ShellSettings.leavesEnabled
                    loops: Animation.Infinite
                    from: -80 - root.spread(index, 3, root.height)
                    to: root.height + 80
                    duration: 6500 + (index % 8) * 520
                }
                SequentialAnimation on x {
                    running: ShellSettings.leavesEnabled
                    loops: Animation.Infinite
                    NumberAnimation { from: leaf.baseX - 24; to: leaf.baseX + 24; duration: 1700 + leaf.index % 5 * 170; easing.type: Easing.InOutSine }
                    NumberAnimation { from: leaf.baseX + 24; to: leaf.baseX - 24; duration: 1700 + leaf.index % 5 * 170; easing.type: Easing.InOutSine }
                }
                RotationAnimation on rotation {
                    running: ShellSettings.leavesEnabled
                    loops: Animation.Infinite
                    from: 0
                    to: leaf.index % 2 ? 360 : -360
                    duration: 4200 + leaf.index % 6 * 360
                }
            }
        }
    }
}
