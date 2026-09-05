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
                    duration: (1350 + (index % 7) * 125) / ShellSettings.rainSpeed
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: ShellSettings.snowEnabled

        Repeater {
            model: 64
            Item {
                id: flake
                required property int index
                property real baseX: root.spread(index, 21, root.width)
                x: baseX
                y: -40 - root.spread(index, 25, root.height)
                width: 5 + index % 5 * 1.5
                height: width

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#ffffff"
                    opacity: 0.48 + (flake.index % 4) * 0.12
                }

                NumberAnimation on y {
                    running: ShellSettings.snowEnabled
                    loops: Animation.Infinite
                    from: -60 - root.spread(index, 19, root.height)
                    to: root.height + 60
                    duration: (5200 + (index % 8) * 430) / ShellSettings.snowSpeed
                }
                SequentialAnimation on x {
                    running: ShellSettings.snowEnabled
                    loops: Animation.Infinite
                    NumberAnimation { from: flake.baseX - 18; to: flake.baseX + 18; duration: (1900 + flake.index % 6 * 150) / ShellSettings.snowSpeed; easing.type: Easing.InOutSine }
                    NumberAnimation { from: flake.baseX + 18; to: flake.baseX - 18; duration: (1900 + flake.index % 6 * 150) / ShellSettings.snowSpeed; easing.type: Easing.InOutSine }
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
                    duration: (6500 + (index % 8) * 520) / ShellSettings.leafSpeed
                }
                SequentialAnimation on x {
                    running: ShellSettings.leavesEnabled
                    loops: Animation.Infinite
                    NumberAnimation { from: leaf.baseX - 24; to: leaf.baseX + 24; duration: (1700 + leaf.index % 5 * 170) / ShellSettings.leafSpeed; easing.type: Easing.InOutSine }
                    NumberAnimation { from: leaf.baseX + 24; to: leaf.baseX - 24; duration: (1700 + leaf.index % 5 * 170) / ShellSettings.leafSpeed; easing.type: Easing.InOutSine }
                }
                RotationAnimation on rotation {
                    running: ShellSettings.leavesEnabled
                    loops: Animation.Infinite
                    from: 0
                    to: leaf.index % 2 ? 360 : -360
                    duration: (4200 + leaf.index % 6 * 360) / ShellSettings.leafSpeed
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: ShellSettings.batsEnabled

        Repeater {
            model: 11
            Item {
                id: bat
                required property int index
                property real baseY: 70 + root.spread(index, 37, Math.max(1, root.height * 0.62))
                x: -90 - root.spread(index, 31, root.width)
                y: baseY
                width: 34
                height: 24

                Text {
                    anchors.centerIn: parent
                    text: "🦇"
                    font.pixelSize: 25
                    opacity: 0.68 + (bat.index % 3) * 0.1
                }

                NumberAnimation on x {
                    running: ShellSettings.batsEnabled
                    loops: Animation.Infinite
                    from: -90 - root.spread(index, 31, root.width)
                    to: root.width + 90
                    duration: (9000 + (index % 6) * 850) / ShellSettings.batSpeed
                }
                SequentialAnimation on y {
                    running: ShellSettings.batsEnabled
                    loops: Animation.Infinite
                    NumberAnimation { from: bat.baseY - 14; to: bat.baseY + 14; duration: (1050 + bat.index % 4 * 130) / ShellSettings.batSpeed; easing.type: Easing.InOutSine }
                    NumberAnimation { from: bat.baseY + 14; to: bat.baseY - 14; duration: (1050 + bat.index % 4 * 130) / ShellSettings.batSpeed; easing.type: Easing.InOutSine }
                }
            }
        }
    }
}
