import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root
    required property ShellScreen targetScreen

    readonly property var monitor: Hyprland.monitorFor(targetScreen)
    readonly property bool centerOpen: ControlCenterState.open && ControlCenterState.screenName === monitor?.name
    readonly property var sections: [
        { key: "appearance", icon: "✦", name: "Appearance", detail: "Badge & shell" },
        { key: "effects", icon: "☂", name: "Effects", detail: "Rain & falling leaves" },
        { key: "network", icon: "⌁", name: "Network", detail: "Wi-Fi & connections" },
        { key: "power", icon: "ϟ", name: "Power", detail: "Profiles & battery" },
        { key: "system", icon: "◉", name: "System", detail: "Hardware & software" }
    ]

    screen: targetScreen
    color: "transparent"
    implicitWidth: Math.max(1, targetScreen.width - Theme.sidebarWidth)
    implicitHeight: Theme.controlCenterHeight
    anchors { right: true; bottom: true }
    WlrLayershell.namespace: "supermachine-control-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: centerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: centerOpen ? null : closedMask

    Region { id: closedMask }

    FocusScope {
        id: movingSurface
        width: parent.width
        height: parent.height
        y: root.centerOpen ? 0 : root.height
        focus: root.centerOpen

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
                        const j = Theme.controlCenterJoinRadius;
                        const f = Theme.frameWidth;
                        const k = j * 0.55228475;

                        return `M 0 0 C 0 ${k} ${j - k} ${j} ${j} ${j} `
                            + `H ${w - f - j} `
                            + `C ${w - f - j + k} ${j} ${w - f} ${k} ${w - f} 0 `
                            + `H ${w} V ${h} H 0 Z`;
                    }
                }
            }
        }

        Row {
            anchors.fill: parent
            anchors { topMargin: Theme.controlCenterJoinRadius + 18; leftMargin: 20; rightMargin: 20; bottomMargin: Theme.frameWidth + 16 }
            spacing: 18

            Rectangle {
                width: Math.min(230, parent.width * 0.24)
                height: parent.height
                radius: Theme.windowRadius
                color: Theme.searchBackground

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: "SUPERMACHINE"
                        color: Theme.ink
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        font.letterSpacing: 1.6
                    }

                    Text {
                        text: "CONTROL CENTER"
                        color: Theme.mutedInk
                        font.pixelSize: 9
                        font.letterSpacing: 1.2
                    }

                    Item { width: 1; height: 8 }

                    Repeater {
                        model: root.sections

                        delegate: Rectangle {
                            id: sectionRow
                            required property var modelData
                            width: parent.width
                            height: 58
                            radius: 14
                            color: ControlCenterState.section === modelData.key ? Theme.surface : "transparent"

                            Text {
                                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                                text: sectionRow.modelData.icon
                                color: Theme.ink
                                font.pixelSize: 20
                            }

                            Column {
                                anchors { left: parent.left; leftMargin: 44; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                spacing: 2
                                Text { text: sectionRow.modelData.name; color: Theme.ink; font.pixelSize: 13; font.weight: Font.DemiBold }
                                Text { text: sectionRow.modelData.detail; color: Theme.mutedInk; font.pixelSize: 9 }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ControlCenterState.show(sectionRow.modelData.key)
                            }
                        }
                    }

                    Item { width: 1; height: 1 }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "SUPER + TAB"
                        color: Theme.mutedInk
                        font.pixelSize: 9
                        font.letterSpacing: 1.1
                    }
                }
            }

            Rectangle {
                width: parent.width - parent.spacing - Math.min(230, parent.width * 0.24)
                height: parent.height
                radius: Theme.windowRadius
                color: Theme.surface

                Flickable {
                    id: settingsScroll
                    anchors.fill: parent
                    anchors.margins: 6
                    contentWidth: width
                    contentHeight: settingsColumn.implicitHeight + 28
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: settingsColumn
                        width: settingsScroll.width
                        spacing: 14
                        topPadding: 8
                        leftPadding: 14
                        rightPadding: 14

                        Text {
                            width: parent.width - 28
                            text: root.sections.find(item => item.key === ControlCenterState.section)?.name ?? "Settings"
                            color: Theme.ink
                            font.pixelSize: 22
                            font.weight: Font.Bold
                        }

                        Text {
                            width: parent.width - 28
                            visible: ControlCenterState.section === "appearance"
                            text: "Customize the shell without editing configuration files. Changes preview instantly and persist after restart."
                            color: Theme.mutedInk
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        Column {
                            visible: ControlCenterState.section === "appearance"
                            width: parent.width - 28
                            spacing: 8
                            Text { text: "Shell color mode"; color: Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }
                            Row {
                                spacing: 10
                                Repeater {
                                    model: [{ key: "light", name: "☀  Light" }, { key: "dark", name: "☾  Dark" }]
                                    delegate: Rectangle {
                                        id: colorModeButton
                                        required property var modelData
                                        width: 126; height: 42; radius: 13
                                        color: ShellSettings.colorMode === modelData.key ? Theme.ink : Theme.searchBackground
                                        Text { anchors.centerIn: parent; text: colorModeButton.modelData.name; color: ShellSettings.colorMode === colorModeButton.modelData.key ? Theme.surface : Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellSettings.setColorMode(colorModeButton.modelData.key) }
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width - 28
                            visible: ControlCenterState.section === "effects"
                            text: "Layer gentle motion over the wallpaper. Effects stay behind your windows and remember their settings."
                            color: Theme.mutedInk
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: ControlCenterState.section === "effects" ? [
                                { key: "rain", title: "Rain drops", detail: "Fine glassy rain with varied speed", enabled: ShellSettings.rainEnabled },
                                { key: "leaves", title: "Falling leaves", detail: "Slow drifting and rotating leaves", enabled: ShellSettings.leavesEnabled }
                            ] : []
                            delegate: Rectangle {
                                id: effectCard
                                required property var modelData
                                width: settingsColumn.width - 28; height: 82; radius: 18
                                color: Theme.searchBackground
                                Column {
                                    anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                                    spacing: 4
                                    Text { text: effectCard.modelData.title; color: Theme.ink; font.pixelSize: 15; font.weight: Font.DemiBold }
                                    Text { text: effectCard.modelData.detail; color: Theme.mutedInk; font.pixelSize: 11 }
                                }
                                Rectangle {
                                    anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                                    width: 52; height: 30; radius: 15
                                    color: effectCard.modelData.enabled ? Theme.ink : (Theme.dark ? "#3a4547" : "#cbd1d2")
                                    Rectangle {
                                        width: 22; height: 22; radius: 11; y: 4
                                        x: effectCard.modelData.enabled ? 26 : 4
                                        color: Theme.surface
                                        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: effectCard.modelData.key === "rain"
                                            ? ShellSettings.setRainEnabled(!ShellSettings.rainEnabled)
                                            : ShellSettings.setLeavesEnabled(!ShellSettings.leavesEnabled)
                                    }
                                }
                            }
                        }

                        Column {
                            visible: ControlCenterState.section === "effects"
                            width: parent.width - 28; spacing: 9
                            Text { text: "Leaf color"; color: Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }
                            Row {
                                spacing: 10
                                Repeater {
                                    model: ["#e58a45", "#e9b949", "#d45b52", "#83ad62", "#b77ad8", "#64bfc4"]
                                    delegate: Rectangle {
                                        id: leafColorButton
                                        required property string modelData
                                        width: 46; height: 46; radius: 15; color: modelData
                                        border.width: ShellSettings.leafColor === modelData ? 3 : 0
                                        border.color: Theme.ink
                                        Rectangle { anchors.centerIn: parent; width: 14; height: 9; radius: 7; color: "#ffffff"; opacity: ShellSettings.leafColor === leafColorButton.modelData ? 0.92 : 0 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellSettings.setLeafColor(leafColorButton.modelData) }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width - 28
                            height: 132
                            radius: 18
                            color: Theme.searchBackground
                            visible: ControlCenterState.section === "appearance"

                            Row {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 18

                                Rectangle {
                                    width: 88
                                    height: 88
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 24
                                    color: Theme.surface

                                    AnimatedImage {
                                        anchors.centerIn: parent
                                        width: ShellSettings.badgeSize + 18
                                        height: width
                                        visible: ShellSettings.badgeMode === "image" && ShellSettings.badgeSource.length > 0
                                        source: ShellSettings.badgeSource
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        playing: visible
                                        paused: false
                                        cache: false
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: ShellSettings.badgeMode !== "image" || !ShellSettings.badgeSource.length
                                        text: ShellSettings.badgeText
                                        font.pixelSize: ShellSettings.badgeSize + 8
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 5
                                    Text { text: "Launcher badge"; color: Theme.ink; font.pixelSize: 16; font.weight: Font.DemiBold }
                                    Text { text: "Shown at the top of the sidebar"; color: Theme.mutedInk; font.pixelSize: 11 }
                                    Text {
                                        text: ShellSettings.badgeMode === "image" ? "IMAGE / ANIMATED GIF" : "EMOJI"
                                        color: Theme.ink
                                        font.pixelSize: 9
                                        font.letterSpacing: 1.2
                                    }
                                }
                            }
                        }

                        Row {
                            visible: ControlCenterState.section === "appearance"
                            spacing: 10

                            Repeater {
                                model: [{ key: "emoji", name: "Emoji" }, { key: "image", name: "Image / GIF" }]
                                delegate: Rectangle {
                                    id: modeButton
                                    required property var modelData
                                    width: 126
                                    height: 38
                                    radius: 12
                                    color: ShellSettings.badgeMode === modelData.key ? Theme.ink : Theme.searchBackground
                                    Text { anchors.centerIn: parent; text: modeButton.modelData.name; color: ShellSettings.badgeMode === modeButton.modelData.key ? Theme.surface : Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellSettings.setBadgeMode(modeButton.modelData.key) }
                                }
                            }
                        }

                        Column {
                            visible: ControlCenterState.section === "appearance"
                            width: parent.width - 28
                            spacing: 8

                            Text { text: "SuperMachine badge collection"; color: Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }

                            Flow {
                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: ShellSettings.badgePresets

                                    delegate: Rectangle {
                                        id: presetCard
                                        required property var modelData
                                        width: 92
                                        height: 90
                                        radius: 15
                                        color: Theme.searchBackground
                                        border.width: ShellSettings.badgeSource === modelData.source.toString() ? 2 : 0
                                        border.color: Theme.ink

                                        AnimatedImage {
                                            anchors { top: parent.top; topMargin: 8; horizontalCenter: parent.horizontalCenter }
                                            width: 54
                                            height: 54
                                            source: presetCard.modelData.source
                                            fillMode: Image.PreserveAspectFit
                                            asynchronous: true
                                            playing: visible
                                            paused: false
                                            cache: false
                                        }

                                        Text {
                                            anchors { bottom: parent.bottom; bottomMargin: 7; horizontalCenter: parent.horizontalCenter }
                                            text: presetCard.modelData.animated ? `${presetCard.modelData.name}  •` : presetCard.modelData.name
                                            color: Theme.ink
                                            font.pixelSize: 9
                                            font.weight: Font.Medium
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: ShellSettings.setBadgePreset(presetCard.modelData.source)
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            visible: ControlCenterState.section === "appearance"
                            width: parent.width - 28
                            spacing: 8

                            Text { text: "Quick emoji"; color: Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }

                            Row {
                                spacing: 7
                                Repeater {
                                    model: ShellSettings.emojiPresets
                                    delegate: Rectangle {
                                        id: emojiCard
                                        required property string modelData
                                        width: 42
                                        height: 42
                                        radius: 12
                                        color: ShellSettings.badgeMode === "emoji" && ShellSettings.badgeText === modelData ? Theme.ink : Theme.searchBackground
                                        Text { anchors.centerIn: parent; text: emojiCard.modelData; font.pixelSize: 21 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellSettings.setEmojiPreset(emojiCard.modelData) }
                                    }
                                }
                            }
                        }

                        Column {
                            visible: ControlCenterState.section === "appearance" && ShellSettings.badgeMode === "emoji"
                            width: parent.width - 28
                            spacing: 7
                            Text { text: "Emoji or sticker character"; color: Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }
                            Rectangle {
                                width: parent.width
                                height: 46
                                radius: 13
                                color: Theme.searchBackground
                                TextInput {
                                    id: emojiInput
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    text: ShellSettings.badgeText
                                    color: Theme.ink
                                    font.pixelSize: 19
                                    verticalAlignment: TextInput.AlignVCenter
                                    onEditingFinished: ShellSettings.setBadgeText(text)
                                }
                            }
                        }

                        Column {
                            visible: ControlCenterState.section === "appearance" && ShellSettings.badgeMode === "image"
                            width: parent.width - 28
                            spacing: 7
                            Text { text: "Local image or animated GIF path"; color: Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }
                            Rectangle {
                                width: parent.width
                                height: 46
                                radius: 13
                                color: Theme.searchBackground
                                TextInput {
                                    id: sourceInput
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    text: ShellSettings.badgeSource
                                    color: Theme.ink
                                    font.pixelSize: 12
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true
                                    onEditingFinished: ShellSettings.setBadgeSource(text)
                                }
                            }
                            Text { text: "Example: ~/Pictures/my-badge.gif"; color: Theme.mutedInk; font.pixelSize: 10 }
                        }

                        Column {
                            visible: ControlCenterState.section === "appearance"
                            width: parent.width - 28
                            spacing: 7
                            Text { text: `Badge size  ${ShellSettings.badgeSize}px`; color: Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }
                            Rectangle {
                                width: parent.width
                                height: 34
                                radius: 12
                                color: Theme.searchBackground
                                Rectangle {
                                    x: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 16
                                    height: 4
                                    radius: 2
                                    color: "#cbd1d2"
                                    Rectangle {
                                        width: (ShellSettings.badgeSize - 20) / 22 * parent.width
                                        height: parent.height
                                        radius: 2
                                        color: Theme.ink
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: mouse => ShellSettings.setBadgeSize(20 + Math.round(22 * mouse.x / width))
                                    onPositionChanged: mouse => { if (pressed) ShellSettings.setBadgeSize(20 + Math.round(22 * mouse.x / width)); }
                                }
                            }
                        }

                        Rectangle {
                            visible: ControlCenterState.section === "appearance"
                            width: 122
                            height: 38
                            radius: 12
                            color: Theme.searchBackground
                            Text { anchors.centerIn: parent; text: "Reset badge"; color: Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellSettings.resetBadge() }
                        }

                        Rectangle {
                            visible: ControlCenterState.section !== "appearance" && ControlCenterState.section !== "effects"
                            width: parent.width - 28
                            height: 150
                            radius: 18
                            color: Theme.searchBackground
                            Column {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "◌"; color: Theme.ink; font.pixelSize: 28 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Foundation ready"; color: Theme.ink; font.pixelSize: 15; font.weight: Font.DemiBold }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Controls for this section come next."; color: Theme.mutedInk; font.pixelSize: 11 }
                            }
                        }
                    }
                }
            }
        }

        Keys.onEscapePressed: ControlCenterState.close()
    }

    onCenterOpenChanged: {
        if (centerOpen)
            Qt.callLater(() => movingSurface.forceActiveFocus());
    }
}
