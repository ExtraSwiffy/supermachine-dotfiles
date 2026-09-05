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
        { key: "effects", icon: "☂", name: "Effects", detail: "Weather & atmosphere" },
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

                        Repeater {
                            model: ControlCenterState.section === "appearance" ? [
                                { key: "frame", name: "Screen border thickness", value: ShellSettings.frameWidth, minimum: 5, maximum: 18, suffix: "px" },
                                { key: "gap", name: "Application gap", value: ShellSettings.windowGap, minimum: 4, maximum: 30, suffix: "px" }
                            ] : []
                            delegate: Column {
                                id: layoutControl
                                required property var modelData
                                width: settingsColumn.width - 28
                                spacing: 7
                                Text { text: `${layoutControl.modelData.name}  ${layoutControl.modelData.value}${layoutControl.modelData.suffix}`; color: Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }
                                Rectangle {
                                    width: parent.width; height: 36; radius: 12; color: Theme.searchBackground
                                    Rectangle {
                                        x: 9; anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 18; height: 4; radius: 2
                                        color: Theme.dark ? "#445052" : "#cbd1d2"
                                        Rectangle {
                                            width: (layoutControl.modelData.value - layoutControl.modelData.minimum) / (layoutControl.modelData.maximum - layoutControl.modelData.minimum) * parent.width
                                            height: parent.height; radius: 2; color: Theme.ink
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        function applyAt(position) {
                                            const item = layoutControl.modelData;
                                            const value = item.minimum + Math.round((item.maximum - item.minimum) * position / width);
                                            if (item.key === "frame") ShellSettings.setFrameWidth(value);
                                            else ShellSettings.setWindowGap(value);
                                        }
                                        onPressed: mouse => applyAt(mouse.x)
                                        onPositionChanged: mouse => { if (pressed) applyAt(mouse.x); }
                                    }
                                }
                            }
                        }

                        Column {
                            visible: ControlCenterState.section === "appearance"
                            width: parent.width - 28; spacing: 9
                            Text { text: "Application outline color"; color: Theme.ink; font.pixelSize: 12; font.weight: Font.Medium }
                            Row {
                                spacing: 10
                                Repeater {
                                    model: ["#86d9d9", "#8ab4f8", "#b69df8", "#f19bb4", "#efb66f", "#9bc987", "#f2f4f3"]
                                    delegate: Rectangle {
                                        id: borderColorButton
                                        required property string modelData
                                        width: 46; height: 46; radius: 15; color: modelData
                                        border.width: ShellSettings.windowBorderColor === modelData ? 3 : 0
                                        border.color: Theme.ink
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellSettings.setWindowBorderColor(borderColorButton.modelData) }
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
                                { key: "snow", title: "Snow", detail: "Soft white flakes with gentle drift", enabled: ShellSettings.snowEnabled },
                                { key: "leaves", title: "Falling leaves", detail: "Slow drifting and rotating leaves", enabled: ShellSettings.leavesEnabled },
                                { key: "bats", title: "Bat flight", detail: "A sparse Halloween flight across the sky", enabled: ShellSettings.batsEnabled }
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
                                        onClicked: {
                                            if (effectCard.modelData.key === "rain")
                                                ShellSettings.setRainEnabled(!ShellSettings.rainEnabled);
                                            else if (effectCard.modelData.key === "snow")
                                                ShellSettings.setSnowEnabled(!ShellSettings.snowEnabled);
                                            else if (effectCard.modelData.key === "leaves")
                                                ShellSettings.setLeavesEnabled(!ShellSettings.leavesEnabled);
                                            else
                                                ShellSettings.setBatsEnabled(!ShellSettings.batsEnabled);
                                        }
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

                        Column {
                            visible: ControlCenterState.section === "effects"
                            width: parent.width - 28
                            spacing: 14

                            Repeater {
                                model: [
                                    { key: "rain", name: "Rain drop speed", value: ShellSettings.rainSpeed },
                                    { key: "snow", name: "Snow fall speed", value: ShellSettings.snowSpeed },
                                    { key: "leaves", name: "Leaf fall speed", value: ShellSettings.leafSpeed },
                                    { key: "bats", name: "Bat flight speed", value: ShellSettings.batSpeed }
                                ]
                                delegate: Column {
                                    id: speedControl
                                    required property var modelData
                                    width: settingsColumn.width - 28
                                    spacing: 7
                                    Text {
                                        text: `${speedControl.modelData.name}  ${speedControl.modelData.value.toFixed(1)}×`
                                        color: Theme.ink
                                        font.pixelSize: 12
                                        font.weight: Font.Medium
                                    }
                                    Rectangle {
                                        width: parent.width
                                        height: 36
                                        radius: 12
                                        color: Theme.searchBackground
                                        Rectangle {
                                            x: 9
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 18
                                            height: 4
                                            radius: 2
                                            color: Theme.dark ? "#445052" : "#cbd1d2"
                                            Rectangle {
                                                width: (speedControl.modelData.value - 0.5) / 1.5 * parent.width
                                                height: parent.height
                                                radius: 2
                                                color: Theme.ink
                                            }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            function applyAt(position) {
                                                const value = Math.round((0.5 + 1.5 * position / width) * 10) / 10;
                                                if (speedControl.modelData.key === "rain")
                                                    ShellSettings.setRainSpeed(value);
                                                else if (speedControl.modelData.key === "snow")
                                                    ShellSettings.setSnowSpeed(value);
                                                else if (speedControl.modelData.key === "leaves")
                                                    ShellSettings.setLeafSpeed(value);
                                                else
                                                    ShellSettings.setBatSpeed(value);
                                            }
                                            onPressed: mouse => applyAt(mouse.x)
                                            onPositionChanged: mouse => { if (pressed) applyAt(mouse.x); }
                                        }
                                    }
                                }
                            }
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

                        Text {
                            visible: ControlCenterState.section === "power"
                            width: parent.width - 28
                            text: "Choose how aggressively the system uses power. The selected profile persists across restarts."
                            color: Theme.mutedInk; font.pixelSize: 12; wrapMode: Text.WordWrap
                        }

                        Row {
                            visible: ControlCenterState.section === "power"
                            width: parent.width - 28
                            spacing: 10
                            Repeater {
                                model: [
                                    { key: "power-saver", icon: "♧", name: "Low", detail: "Quiet & efficient" },
                                    { key: "balanced", icon: "◐", name: "Balanced", detail: "Everyday use" },
                                    { key: "performance", icon: "ϟ", name: "High", detail: "Maximum speed" }
                                ]
                                delegate: Rectangle {
                                    id: profileCard
                                    required property var modelData
                                    width: (settingsColumn.width - 48) / 3; height: 112; radius: 18
                                    color: ShellSettings.powerProfile === modelData.key ? Theme.ink : Theme.searchBackground
                                    Column {
                                        anchors.centerIn: parent; spacing: 5
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: profileCard.modelData.icon; color: ShellSettings.powerProfile === profileCard.modelData.key ? Theme.surface : Theme.ink; font.pixelSize: 25 }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: profileCard.modelData.name; color: ShellSettings.powerProfile === profileCard.modelData.key ? Theme.surface : Theme.ink; font.pixelSize: 13; font.weight: Font.DemiBold }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: profileCard.modelData.detail; color: ShellSettings.powerProfile === profileCard.modelData.key ? Theme.surface : Theme.mutedInk; opacity: 0.78; font.pixelSize: 9 }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellSettings.setPowerProfile(profileCard.modelData.key) }
                                }
                            }
                        }

                        Rectangle {
                            visible: ControlCenterState.section === "power"
                            width: parent.width - 28; height: 112; radius: 18; color: Theme.searchBackground
                            Column {
                                anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                                spacing: 5
                                Text { text: "Steam Console Mode"; color: Theme.ink; font.pixelSize: 15; font.weight: Font.DemiBold }
                                Text { text: "Close Hyprland and launch Steam Gamepad UI in Gamescope."; color: Theme.mutedInk; font.pixelSize: 11 }
                                Text { text: "This choice remains active after a shutdown until Desktop Mode is selected in Steam."; color: Theme.mutedInk; font.pixelSize: 10 }
                            }
                            Rectangle {
                                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                                width: 142; height: 42; radius: 14; color: Theme.ink
                                Text { anchors.centerIn: parent; text: "Enter console mode"; color: Theme.surface; font.pixelSize: 11; font.weight: Font.DemiBold }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: ShellSettings.enterConsoleMode() }
                            }
                        }

                        Grid {
                            visible: ControlCenterState.section === "system"
                            width: parent.width - 28
                            columns: 3; spacing: 10
                            Repeater {
                                model: [
                                    { name: "CPU activity", value: `${SystemInfo.cpuPercent}%` },
                                    { name: "Memory", value: `${SystemInfo.memoryPercent}%` },
                                    { name: "Disk", value: `${SystemInfo.diskPercent}%` }
                                ]
                                delegate: Rectangle {
                                    id: activityCard
                                    required property var modelData
                                    width: (settingsColumn.width - 48) / 3; height: 102; radius: 18; color: Theme.searchBackground
                                    Column { anchors.centerIn: parent; spacing: 5
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: activityCard.modelData.value; color: Theme.ink; font.pixelSize: 24; font.weight: Font.Bold }
                                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: activityCard.modelData.name; color: Theme.mutedInk; font.pixelSize: 10 }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: ControlCenterState.section === "system"
                            width: parent.width - 28; height: 230; radius: 18; color: Theme.searchBackground
                            Column {
                                anchors.fill: parent; anchors.margins: 18; spacing: 13
                                Repeater {
                                    model: [
                                        { name: "Processor", value: SystemInfo.cpuName },
                                        { name: "Graphics", value: SystemInfo.gpuName },
                                        { name: "Memory used", value: SystemInfo.memoryUsage },
                                        { name: "Root storage", value: SystemInfo.diskUsage },
                                        { name: "Uptime", value: SystemInfo.uptime },
                                        { name: "Kernel", value: SystemInfo.kernel }
                                    ]
                                    delegate: Row {
                                        id: infoRow
                                        required property var modelData
                                        width: parent.width
                                        Text { width: 110; text: infoRow.modelData.name; color: Theme.mutedInk; font.pixelSize: 11 }
                                        Text { width: infoRow.width - 110; text: infoRow.modelData.value; color: Theme.ink; font.pixelSize: 11; elide: Text.ElideRight }
                                    }
                                }
                            }
                        }

                        Row {
                            visible: ControlCenterState.section === "system"
                            width: parent.width - 28; spacing: 10
                            Repeater {
                                model: [
                                    { name: "View live shell log", action: "logs" },
                                    { name: "Build diagnostic report", action: "report" }
                                ]
                                delegate: Rectangle {
                                    id: diagnosticButton
                                    required property var modelData
                                    width: (settingsColumn.width - 38) / 2; height: 46; radius: 14; color: Theme.ink
                                    Text { anchors.centerIn: parent; text: diagnosticButton.modelData.name; color: Theme.surface; font.pixelSize: 11; font.weight: Font.DemiBold }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: diagnosticButton.modelData.action === "logs" ? ShellSettings.viewLogs() : ShellSettings.createDiagnosticReport()
                                    }
                                }
                            }
                        }

                        Rectangle {
                            visible: ControlCenterState.section === "network"
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
