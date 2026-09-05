import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root
    required property ShellScreen targetScreen

    readonly property var monitor: Hyprland.monitorFor(targetScreen)
    readonly property bool deckOpen: WallpaperState.open && WallpaperState.screenName === monitor?.name
    readonly property int cardWidth: Math.min(430, Math.round(width * 0.34))
    readonly property int cardHeight: Math.round(cardWidth * 0.5625)
    readonly property real deckStep: {
        const count = WallpaperState.wallpapers.length;
        const usable = width - 96;
        return count < 2 ? 0 : Math.min(cardWidth * 0.48, (usable - cardWidth) / (count - 1));
    }

    function signedDistance(index) {
        const count = WallpaperState.wallpapers.length;
        let distance = index - WallpaperState.selectedIndex;
        if (distance > count / 2)
            distance -= count;
        if (distance < -count / 2)
            distance += count;
        return distance;
    }

    screen: targetScreen
    color: "transparent"
    implicitWidth: Math.max(1, targetScreen.width - Theme.sidebarWidth)
    implicitHeight: Theme.wallpaperDeckHeight
    anchors { right: true; bottom: true }
    WlrLayershell.namespace: "supermachine-wallpaper-deck"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: deckOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: deckOpen ? null : closedMask

    Region { id: closedMask }

    Item {
        id: movingSurface
        width: parent.width
        height: parent.height
        y: root.deckOpen ? 0 : root.height

        Behavior on y {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Theme.surface
                strokeColor: "transparent"

                PathSvg {
                    path: {
                        const w = root.width;
                        const h = root.height;
                        const j = Theme.wallpaperJoinRadius;
                        const r = Theme.innerRadius;
                        const railTop = h - Theme.frameWidth;

                        return `M ${j + r} 0 H ${w - j - r} `
                            + `Q ${w - j} 0 ${w - j} ${r} `
                            + `V ${railTop - j} Q ${w - j} ${railTop} ${w} ${railTop} `
                            + `V ${h} H 0 V ${railTop} `
                            + `Q ${j} ${railTop} ${j} ${railTop - j} `
                            + `V ${r} Q ${j} 0 ${j + r} 0 Z`;
                    }
                }
            }
        }

        Text {
            anchors { top: parent.top; topMargin: 18; horizontalCenter: parent.horizontalCenter }
            text: WallpaperState.selectedName
            color: Theme.ink
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        Text {
            anchors { top: parent.top; topMargin: 43; horizontalCenter: parent.horizontalCenter }
            text: "CLICK A CARD TO PREVIEW  •  SCROLL TO GLIDE  •  ESC TO CLOSE"
            color: Theme.mutedInk
            font.pixelSize: 9
            font.letterSpacing: 1.2
        }

        Item {
            id: cardStage
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom }
            anchors { leftMargin: 36; rightMargin: 36; topMargin: 70; bottomMargin: Theme.frameWidth + 18 }

            Repeater {
                model: WallpaperState.wallpapers

                delegate: Item {
                    id: card
                    required property var modelData
                    required property int index
                    readonly property real distance: root.signedDistance(index)
                    readonly property bool selected: index === WallpaperState.selectedIndex

                    width: root.cardWidth
                    height: root.cardHeight
                    x: (cardStage.width - width) / 2 + distance * root.deckStep
                    y: (cardStage.height - height) / 2 + Math.abs(distance) * 10
                    scale: selected ? 1 : Math.max(0.82, 0.92 - Math.abs(distance) * 0.025)
                    opacity: selected ? 1 : Math.max(0.58, 0.88 - Math.abs(distance) * 0.08)
                    z: selected ? 100 : 50 - Math.abs(distance)

                    Behavior on x { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 220 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.wallpaperCardRadius
                        color: Theme.searchBackground
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: card.modelData.source
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            border.width: card.selected ? 4 : 1
                            border.color: card.selected ? Theme.surface : "#66ffffff"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperState.select(card.index)
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: wheel.angleDelta.y < 0 ? WallpaperState.step(1) : WallpaperState.step(-1)
        }

        Keys.onEscapePressed: WallpaperState.close()
        Keys.onLeftPressed: WallpaperState.step(-1)
        Keys.onRightPressed: WallpaperState.step(1)
    }
}
