import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root
    required property ShellScreen targetScreen
    readonly property var monitor: Hyprland.monitorFor(targetScreen)
    readonly property bool menuOpen: QuickMenuState.open && QuickMenuState.screenName === monitor?.name
    property var configFiles: []
    property int hoveredRow: -1

    function run(command) {
        Quickshell.execDetached(command);
        QuickMenuState.close();
    }

    function openConfig(path) {
        Quickshell.execDetached(["code", "--reuse-window", path]);
        QuickMenuState.close();
    }

    screen: targetScreen
    color: "transparent"
    anchors { top: true; right: true; bottom: true; left: true }
    WlrLayershell.namespace: "supermachine-quick-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: menuOpen ? null : closedMask

    Region { id: closedMask }

    Process {
        id: configReader
        command: [`${Quickshell.env("HOME")}/.local/bin/supermachine-config-files`]
        stdout: StdioCollector {
            onStreamFinished: {
                root.configFiles = text.trim().length === 0 ? [] : text.trim().split("\n").map(line => {
                    const split = line.indexOf("\t");
                    return { label: line.slice(0, split), path: line.slice(split + 1) };
                });
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.menuOpen
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: QuickMenuState.close()
    }

    Rectangle {
        id: mainMenu
        width: 224
        height: menuColumn.height + 16
        x: Math.max(Theme.sidebarWidth + 8, Math.min(root.width - width - 527, QuickMenuState.requestedX))
        y: Math.max(Theme.frameWidth + 8, Math.min(root.height - height - 12, QuickMenuState.requestedY))
        radius: 15
        color: Theme.surface
        border.width: 1
        border.color: Theme.dark ? "#303a3c" : "#d9dede"
        visible: root.menuOpen

        Column {
            id: menuColumn
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
            spacing: 2

            Repeater {
                model: [
                    { title: "Config files", icon: "◆", submenu: true, command: [] },
                    { title: "Terminal", icon: ">_", command: ["foot"] },
                    { title: "Applications", icon: "⌕", command: ["qs", "-c", "supermachine", "ipc", "call", "launcher", "toggle"] },
                    { title: "Wallpaper decks", icon: "▧", command: ["qs", "-c", "supermachine", "ipc", "call", "wallpapers", "toggle"] },
                    { title: "SuperOS Arcade", icon: "★", command: ["qs", "-c", "supermachine", "ipc", "call", "games", "toggle"] },
                    { title: "System settings", icon: "⚙", command: ["qs", "-c", "supermachine", "ipc", "call", "controlcenter", "toggle"] },
                    { title: "Open diagnostics", icon: "◫", command: ["foot", "-e", "bash", "-lc", "supermachine-diagnostics; exec bash"] },
                    { title: "Restart shell", icon: "↻", command: ["systemctl", "--user", "restart", "supermachine-shell.service"] }
                ]

                delegate: Rectangle {
                    id: row
                    required property var modelData
                    required property int index
                    width: menuColumn.width
                    height: 39
                    radius: 10
                    color: rowMouse.containsMouse ? Theme.searchBackground : "transparent"

                    Text {
                        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                        width: 24
                        text: row.modelData.icon
                        color: Theme.mutedInk
                        font.pixelSize: 14
                        font.family: "monospace"
                    }
                    Text {
                        anchors { left: parent.left; leftMargin: 42; verticalCenter: parent.verticalCenter }
                        text: row.modelData.title
                        color: Theme.ink
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    Text {
                        anchors { right: parent.right; rightMargin: 11; verticalCenter: parent.verticalCenter }
                        visible: row.modelData.submenu === true
                        text: "›"
                        color: Theme.mutedInk
                        font.pixelSize: 20
                    }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: {
                            root.hoveredRow = row.index;
                            QuickMenuState.configOpen = row.modelData.submenu === true;
                            if (QuickMenuState.configOpen && !configReader.running)
                                configReader.running = true;
                        }
                        onClicked: {
                            if (row.modelData.submenu === true)
                                QuickMenuState.configOpen = true;
                            else
                                root.run(row.modelData.command);
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: configMenu
        width: Math.min(510, root.width - mainMenu.x - mainMenu.width - 24)
        height: Math.min(580, 53 + root.configFiles.length * 38)
        x: mainMenu.x + mainMenu.width + 7
        y: Math.max(12, Math.min(root.height - height - 12, mainMenu.y))
        radius: 15
        color: Theme.surface
        border.width: 1
        border.color: Theme.dark ? "#303a3c" : "#d9dede"
        visible: root.menuOpen && QuickMenuState.configOpen

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 5

            Text {
                width: parent.width
                height: 32
                leftPadding: 8
                verticalAlignment: Text.AlignVCenter
                text: `MAIN CONFIGS  ·  ${root.configFiles.length}`
                color: Theme.mutedInk
                font.pixelSize: 10
                font.letterSpacing: 1.1
            }

            ListView {
                width: parent.width
                height: parent.height - 37
                model: root.configFiles
                clip: true
                spacing: 2
                ScrollBar.vertical: ScrollBar {}

                delegate: Rectangle {
                    id: configRow
                    required property var modelData
                    width: ListView.view.width - 8
                    height: 36
                    radius: 9
                    color: configMouse.containsMouse ? Theme.searchBackground : "transparent"

                    Text {
                        anchors { left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 8; verticalCenter: parent.verticalCenter }
                        text: configRow.modelData.label
                        color: Theme.ink
                        font.pixelSize: 12
                        elide: Text.ElideMiddle
                    }
                    MouseArea {
                        id: configMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.openConfig(configRow.modelData.path)
                    }
                }
            }
        }
    }

    onMenuOpenChanged: {
        if (menuOpen && !configReader.running)
            configReader.running = true;
    }
}
