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
    readonly property bool deckOpen: BadgeDeckState.open && BadgeDeckState.screenName === monitor?.name
    readonly property int deckWidth: 118

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
        x: root.deckOpen ? 0 : -root.deckWidth - 8
        width: root.width
        height: root.height
        focus: root.deckOpen

        Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

        Shape {
            id: deckShape
            x: Theme.sidebarWidth - Theme.frameWidth
            y: 92
            width: root.deckWidth + Theme.frameWidth
            height: parent.height - 112
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: Theme.surface
                strokeColor: "transparent"
                startX: 0; startY: 0
                PathLine { x: deckShape.width - 24; y: 0 }
                PathQuad { x: deckShape.width; y: 24; controlX: deckShape.width; controlY: 0 }
                PathLine { x: deckShape.width; y: deckShape.height - 24 }
                PathQuad { x: deckShape.width - 24; y: deckShape.height; controlX: deckShape.width; controlY: deckShape.height }
                PathLine { x: 0; y: deckShape.height }
                PathLine { x: 0; y: 0 }
            }
        }

        Text {
            x: Theme.sidebarWidth + 15
            y: 108
            text: "BADGES"
            color: Theme.mutedInk
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 1.4
        }

        Flickable {
            id: badgeScroll
            x: Theme.sidebarWidth + 8
            y: 132
            width: root.deckWidth - 16
            height: parent.height - 164
            contentWidth: width
            contentHeight: 82 + Math.max(0, ShellSettings.badgePresets.length - 1) * 58
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Repeater {
                model: ShellSettings.badgePresets
                delegate: Item {
                    id: badgeCard
                    required property var modelData
                    required property int index
                    readonly property bool selected: ShellSettings.badgeMode === "image"
                        && ShellSettings.badgeSource === modelData.source.toString()
                    width: 82
                    height: 82
                    x: (badgeScroll.width - width) / 2 + (index % 2 ? 3 : -3)
                    y: index * 58
                    z: selected ? 100 : 50 + index

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: Theme.searchBackground
                        border.width: badgeCard.selected ? 3 : 1
                        border.color: badgeCard.selected ? Theme.ink : (Theme.dark ? "#405052" : "#d5dbdc")

                        AnimatedImage {
                            anchors { top: parent.top; topMargin: 7; horizontalCenter: parent.horizontalCenter }
                            width: 52; height: 52
                            source: badgeCard.modelData.source
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            playing: visible
                            paused: false
                            cache: false
                        }

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: 23
                            color: badgeCard.selected ? Theme.ink : Theme.surface
                            radius: 11
                            Text {
                                anchors.centerIn: parent
                                text: badgeCard.modelData.name
                                color: badgeCard.selected ? Theme.surface : Theme.ink
                                font.pixelSize: 8
                                font.weight: Font.Medium
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ShellSettings.setBadgePreset(badgeCard.modelData.source)
                            onDoubleClicked: {
                                ShellSettings.setBadgePreset(badgeCard.modelData.source);
                                BadgeDeckState.close();
                            }
                        }
                    }
                }
            }
        }

        Keys.onEscapePressed: BadgeDeckState.close()
    }

    onDeckOpenChanged: {
        if (deckOpen)
            Qt.callLater(() => movingSurface.forceActiveFocus());
    }
}
