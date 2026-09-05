import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets

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
        return count < 2 ? 0 : Math.min(cardWidth * 0.34, (usable - cardWidth) / (count - 1));
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

    FocusScope {
        id: movingSurface
        width: parent.width
        height: parent.height
        y: root.deckOpen ? 0 : root.height
        focus: root.deckOpen

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

                        return `M 0 0 `
                            + `C ${j} 0 ${j} ${j} ${j * 2} ${j} `
                            + `H ${w - j * 2} `
                            + `C ${w - j} ${j} ${w - j} 0 ${w} 0 `
                            + `V ${h} H 0 Z`;
                    }
                }
            }
        }

        Text {
            anchors { top: parent.top; topMargin: Theme.wallpaperJoinRadius + 10; horizontalCenter: parent.horizontalCenter }
            text: WallpaperState.selectedName
            color: Theme.ink
            font.pixelSize: 17
            font.weight: Font.DemiBold
        }

        Text {
            anchors { top: parent.top; topMargin: Theme.wallpaperJoinRadius + 35; horizontalCenter: parent.horizontalCenter }
            text: "CLICK A CARD TO PREVIEW  •  SCROLL TO GLIDE  •  ESC TO CLOSE"
            color: Theme.mutedInk
            font.pixelSize: 9
            font.letterSpacing: 1.2
        }

        MouseArea {
            anchors.fill: parent
            z: 1
            acceptedButtons: Qt.NoButton
            onWheel: wheel.angleDelta.y < 0 ? WallpaperState.step(1) : WallpaperState.step(-1)
        }

        Item {
            id: cardStage
            z: 2
            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom }
            anchors { leftMargin: 36; rightMargin: 36; topMargin: Theme.wallpaperJoinRadius + 62; bottomMargin: Theme.frameWidth + 12 }

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

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: Theme.wallpaperCardRadius
                        color: Theme.searchBackground
                        contentUnderBorder: true
                        border.width: card.selected ? 4 : 1
                        border.color: card.selected ? Theme.surface : "#66ffffff"

                        Image {
                            anchors.fill: parent
                            source: card.modelData.source
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperState.select(card.index)
                        onDoubleClicked: {
                            WallpaperState.select(card.index);
                            WallpaperState.close();
                        }
                    }
                }
            }
        }

        Keys.onEscapePressed: WallpaperState.close()
        Keys.onLeftPressed: WallpaperState.step(-1)
        Keys.onRightPressed: WallpaperState.step(1)
        Keys.onReturnPressed: WallpaperState.close()
        Keys.onEnterPressed: WallpaperState.close()
    }

    onDeckOpenChanged: {
        if (deckOpen)
            Qt.callLater(() => movingSurface.forceActiveFocus());
    }
}
