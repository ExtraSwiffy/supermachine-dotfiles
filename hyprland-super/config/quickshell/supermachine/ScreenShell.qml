import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property ShellScreen modelData
    readonly property int railWidth: Theme.sidebarWidthFor(root.modelData)
    readonly property bool railVisible: railWidth > Theme.frameWidth

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    WallpaperBackground {
        targetScreen: root.modelData
    }

    WallpaperEffects {
        targetScreen: root.modelData
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
                        const x = root.railWidth;
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

        Canvas {
            id: frameTexture
            anchors.fill: parent
            visible: Theme.frameTexture !== "solid"
            opacity: Theme.dark ? 0.22 : 0.15

            function roundedPath(context, x, y, width, height, radius) {
                context.beginPath();
                context.moveTo(x + radius, y);
                context.lineTo(x + width - radius, y);
                context.quadraticCurveTo(x + width, y, x + width, y + radius);
                context.lineTo(x + width, y + height - radius);
                context.quadraticCurveTo(x + width, y + height, x + width - radius, y + height);
                context.lineTo(x + radius, y + height);
                context.quadraticCurveTo(x, y + height, x, y + height - radius);
                context.lineTo(x, y + radius);
                context.quadraticCurveTo(x, y, x + radius, y);
                context.closePath();
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.globalCompositeOperation = "source-over";
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = Theme.dark ? "#ffffff" : "#000000";
                ctx.fillStyle = ctx.strokeStyle;
                ctx.lineWidth = 1;
                const parts = Theme.frameTexture.split("-");
                const family = parts[0];
                const legacyLevel = (family === "dots" || family === "grain" || family === "diagonal" || family === "grid") ? 3 : 1;
                const level = parts.length > 1 ? Number(parts[1]) : legacyLevel;
                const step = 5 + level * 3;

                if (family === "dots" || family === "grain") {
                    for (let y = 3; y < height; y += step) {
                        for (let x = 3 + ((y / step) % 2) * step / 2; x < width; x += step) {
                            ctx.beginPath();
                            ctx.arc(x, y, family === "grain" ? 0.5 + level * 0.12 : 0.8 + level * 0.18, 0, Math.PI * 2);
                            ctx.fill();
                        }
                    }
                } else if (family === "vertical" || family === "horizontal") {
                    for (let position = 0; position < (family === "vertical" ? width : height); position += step) {
                        ctx.beginPath();
                        ctx.moveTo(family === "vertical" ? position : 0, family === "vertical" ? 0 : position);
                        ctx.lineTo(family === "vertical" ? position : width, family === "vertical" ? height : position);
                        ctx.stroke();
                    }
                } else if (family === "checker") {
                    for (let y = 0; y < height; y += step) {
                        for (let x = 0; x < width; x += step) {
                            if ((Math.floor(x / step) + Math.floor(y / step)) % 2 === 0)
                                ctx.fillRect(x, y, step, step);
                        }
                    }
                } else if (family === "wave") {
                    for (let y = step; y < height; y += step * 1.6) {
                        ctx.beginPath();
                        ctx.moveTo(0, y);
                        for (let x = 0; x < width; x += 4)
                            ctx.lineTo(x, y + Math.sin(x / (step * 0.8)) * (2 + level));
                        ctx.stroke();
                    }
                } else if (family === "dash") {
                    for (let y = 3; y < height; y += step) {
                        for (let x = (Math.floor(y / step) % 2) * step; x < width; x += step * 2)
                            ctx.fillRect(x, y, step * 0.8, 1 + level * 0.25);
                    }
                } else {
                    const lineStep = family === "diamond" ? step * 1.45 : step;
                    for (let x = -height; x < width + height; x += lineStep) {
                        ctx.beginPath();
                        ctx.moveTo(x, 0);
                        ctx.lineTo(x + height, height);
                        ctx.stroke();
                    }
                    if (family === "grid" || family === "diamond") {
                        for (let x = 0; x < width + height; x += lineStep) {
                            ctx.beginPath();
                            ctx.moveTo(x, 0);
                            ctx.lineTo(x - height, height);
                            ctx.stroke();
                        }
                    }
                }

                ctx.globalCompositeOperation = "destination-out";
                roundedPath(ctx, root.railWidth, Theme.frameWidth,
                    width - root.railWidth - Theme.frameWidth,
                    height - Theme.frameWidth * 2, Theme.innerRadius);
                ctx.fill();
                ctx.globalCompositeOperation = "source-over";
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: ShellSettings
                function onShellTextureChanged() { frameTexture.requestPaint(); }
                function onColorModeChanged() { frameTexture.requestPaint(); }
                function onSecondarySidebarEnabledChanged() { frameTexture.requestPaint(); }
            }
        }

        Column {
            x: Math.round((root.railWidth - width) / 2)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 7
            visible: root.railVisible

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

    // Interactive surfaces are created after the frame so they render above it.
    Launcher {
        targetScreen: root.modelData
    }

    WallpaperDeck {
        targetScreen: root.modelData
    }

    ControlCenter {
        targetScreen: root.modelData
    }

    BadgeDeck {
        targetScreen: root.modelData
    }

    QuickMenu {
        targetScreen: root.modelData
    }

    GameHub {
        targetScreen: root.modelData
    }

    PanelWindow {
        screen: root.modelData
        color: "transparent"
        implicitWidth: root.railWidth
        implicitHeight: 92
        anchors { top: true; left: true }
        WlrLayershell.namespace: "supermachine-badge"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        visible: root.railVisible

        Item {
            anchors.centerIn: parent
            width: 48
            height: 48

            AnimatedImage {
                anchors.centerIn: parent
                width: ShellSettings.badgeSize + 12
                height: width
                visible: Theme.badgeSource.length > 0
                source: Theme.badgeSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                playing: visible
                paused: false
                cache: false
            }

            Text {
                anchors.centerIn: parent
                visible: Theme.badgeSource.length === 0
                text: Theme.badgeText
                font.pixelSize: ShellSettings.badgeSize
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    WallpaperState.close();
                    ControlCenterState.close();
                    BadgeDeckState.close();
                    LauncherState.toggle(root.modelData.name);
                }
            }
        }
    }

    // This invisible layer reserves the same width as the visible rail.
    PanelWindow {
        readonly property bool badgeReserve: BadgeDeckState.open
            && BadgeDeckState.screenName === root.modelData.name
        readonly property int reservedWidth: badgeReserve ? Theme.badgeDeckReserveFor(root.modelData) : root.railWidth

        screen: root.modelData
        color: "transparent"
        implicitWidth: reservedWidth
        anchors { top: true; bottom: true; left: true }
        WlrLayershell.namespace: "supermachine-sidebar-reserve"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: ExclusionMode.Normal
        exclusiveZone: reservedWidth
        mask: Region {}
    }

    // Keep tiled and maximized windows evenly inside the visible frame.
    Variants {
        model: ["top", "right", "bottom"]

        PanelWindow {
            required property string modelData
            readonly property bool wallpaperReserve: modelData === "bottom"
                && WallpaperState.open
                && WallpaperState.screenName === root.modelData.name
            readonly property bool controlCenterReserve: modelData === "bottom"
                && ControlCenterState.open
                && ControlCenterState.screenName === root.modelData.name
            readonly property int bottomReserve: controlCenterReserve ? Theme.controlCenterHeight
                : wallpaperReserve ? Theme.wallpaperDeckHeight : Theme.frameWidth

            screen: root.modelData
            color: "transparent"
            implicitWidth: Theme.frameWidth
            implicitHeight: bottomReserve
            anchors {
                top: modelData === "top" || modelData === "right"
                right: true
                bottom: modelData === "bottom" || modelData === "right"
                left: modelData === "top" || modelData === "bottom"
            }
            WlrLayershell.namespace: `supermachine-${modelData}-reserve`
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.exclusionMode: ExclusionMode.Normal
            exclusiveZone: bottomReserve
            mask: Region {}
        }
    }
}
