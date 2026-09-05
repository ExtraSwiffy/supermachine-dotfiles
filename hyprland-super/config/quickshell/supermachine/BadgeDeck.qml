import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root
    required property ShellScreen targetScreen

    readonly property var monitor: Hyprland.monitorFor(targetScreen)
    readonly property bool deckOpen: BadgeDeckState.open && BadgeDeckState.screenName === monitor?.name
    readonly property int deckWidth: 126
    readonly property int cardSize: 88
    readonly property int cardStep: 43

    function signedDistance(index) {
        const count = ShellSettings.badgePresets.length;
        let distance = index - BadgeDeckState.selectedIndex;
        if (distance > count / 2)
            distance -= count;
        if (distance < -count / 2)
            distance += count;
        return distance;
    }

    screen: targetScreen
    color: "transparent"
    implicitWidth: Theme.sidebarWidth + deckWidth
    anchors { top: true; bottom: true; left: true }
    WlrLayershell.namespace: "supermachine-badge-deck"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: deckOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: deckOpen ? null : closedMask

    Region { id: closedMask }

    FocusScope {
        id: movingSurface
        x: root.deckOpen ? 0 : -root.width - 4
        width: root.width
        height: root.height
        focus: root.deckOpen
        opacity: root.deckOpen ? 1 : 0

        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: root.deckOpen ? 120 : 220 } }

        Shape {
            id: deckShape
            x: Theme.sidebarWidth - Theme.frameWidth
            width: root.deckWidth + Theme.frameWidth
            height: parent.height
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Theme.surface
                strokeColor: "transparent"
                startX: 0; startY: 0
                PathLine { x: deckShape.width; y: 0 }
                PathCubic {
                    x: deckShape.width - 27; y: 27
                    control1X: deckShape.width - 15; control1Y: 0
                    control2X: deckShape.width - 27; control2Y: 12
                }
                PathLine { x: deckShape.width - 27; y: deckShape.height - 27 }
                PathCubic {
                    x: deckShape.width; y: deckShape.height
                    control1X: deckShape.width - 27; control1Y: deckShape.height - 12
                    control2X: deckShape.width - 15; control2Y: deckShape.height
                }
                PathLine { x: 0; y: deckShape.height }
                PathLine { x: 0; y: 0 }
            }
        }

        Text {
            x: Theme.sidebarWidth + 17
            y: 20
            text: "BADGE DECK"
            color: Theme.mutedInk
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 1.35
        }

        Item {
            id: cardStage
            x: Theme.sidebarWidth + 8
            y: 48
            width: root.deckWidth - 16
            height: parent.height - 96
            clip: true

            Repeater {
                model: ShellSettings.badgePresets

                delegate: Item {
                    id: badgeCard
                    required property var modelData
                    required property int index
                    readonly property real distance: root.signedDistance(index)
                    readonly property bool selected: index === BadgeDeckState.selectedIndex
                    width: root.cardSize
                    height: root.cardSize
                    x: (cardStage.width - width) / 2
                    y: (cardStage.height - height) / 2 + distance * root.cardStep
                    scale: selected ? 1 : Math.max(0.82, 0.94 - Math.abs(distance) * 0.018)
                    opacity: selected ? 1 : Math.max(0.54, 0.9 - Math.abs(distance) * 0.055)
                    z: selected ? 100 : 60 - Math.abs(distance)

                    Behavior on x { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on y { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: 19
                        color: Theme.searchBackground
                        border.width: badgeCard.selected ? 3 : 1
                        border.color: badgeCard.selected ? "#ffffff" : (Theme.dark ? "#405052" : "#d5dbdc")

                        AnimatedImage {
                            anchors { top: parent.top; topMargin: 7; horizontalCenter: parent.horizontalCenter }
                            width: 57; height: 57
                            source: badgeCard.modelData.source
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            playing: visible
                            paused: false
                            cache: false
                        }

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 24
                            radius: 12
                            color: Theme.surface
                            Text {
                                anchors.centerIn: parent
                                width: parent.width - 8
                                text: badgeCard.modelData.name
                                color: Theme.ink
                                font.pixelSize: 8
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BadgeDeckState.select(badgeCard.index)
                            onDoubleClicked: {
                                BadgeDeckState.select(badgeCard.index);
                                BadgeDeckState.close();
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors { horizontalCenter: cardStage.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 }
            text: "↑  ↓  SELECT   •   ESC CLOSE"
            color: Theme.mutedInk
            font.pixelSize: 8
            font.letterSpacing: 0.8
        }

        Keys.onEscapePressed: BadgeDeckState.close()
        Keys.onUpPressed: BadgeDeckState.step(-1)
        Keys.onDownPressed: BadgeDeckState.step(1)
        Keys.onReturnPressed: BadgeDeckState.close()
        Keys.onEnterPressed: BadgeDeckState.close()
    }

    onDeckOpenChanged: {
        if (deckOpen)
            Qt.callLater(() => movingSurface.forceActiveFocus());
    }
}
