import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

PanelWindow {
    id: root
    required property ShellScreen targetScreen

    readonly property var monitor: Hyprland.monitorFor(targetScreen)
    readonly property bool launcherOpen: LauncherState.open && LauncherState.screenName === monitor?.name
    readonly property var filteredApps: {
        const query = search.text.trim().toLowerCase();
        return [...DesktopEntries.applications.values]
            .filter(app => !app.noDisplay && (!query
                || app.name.toLowerCase().includes(query)
                || app.genericName.toLowerCase().includes(query)
                || app.comment.toLowerCase().includes(query)))
            .sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, Theme.launcherResultCount);
    }

    function launchSelected() {
        const app = filteredApps[results.currentIndex];
        if (!app)
            return;
        app.execute();
        LauncherState.close();
    }

    screen: targetScreen
    color: "transparent"
    implicitWidth: Theme.launcherWidth
    implicitHeight: launcherOpen ? Theme.launcherHeight : 1
    anchors { bottom: true }
    WlrLayershell.namespace: "supermachine-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: launcherOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Behavior on implicitHeight {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }

    Item {
        anchors.fill: parent
        opacity: root.launcherOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            radius: Theme.innerRadius
        }

        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: Theme.innerRadius
            color: Theme.surface
        }

        Rectangle {
            anchors.fill: parent
            anchors { leftMargin: Theme.frameWidth; rightMargin: Theme.frameWidth; topMargin: Theme.frameWidth }
            color: Theme.launcherBackground
            radius: Theme.windowRadius

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Rectangle {
                    width: parent.width
                    height: 48
                    radius: 14
                    color: Theme.searchBackground

                    Text {
                        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        text: "⌕"
                        color: Theme.launcherMuted
                        font.pixelSize: 22
                    }

                    TextInput {
                        id: search
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                        anchors { leftMargin: 48; rightMargin: 16 }
                        color: Theme.launcherText
                        selectionColor: Theme.launcherAccent
                        selectedTextColor: Theme.launcherBackground
                        font.pixelSize: 16
                        clip: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !search.text.length
                            text: "Search applications"
                            color: Theme.launcherMuted
                            font.pixelSize: 16
                        }

                        Keys.onEscapePressed: LauncherState.close()
                        Keys.onUpPressed: results.currentIndex = Math.max(0, results.currentIndex - 1)
                        Keys.onDownPressed: results.currentIndex = Math.min(root.filteredApps.length - 1, results.currentIndex + 1)
                        Keys.onReturnPressed: root.launchSelected()
                        Keys.onEnterPressed: root.launchSelected()
                    }
                }

                ListView {
                    id: results
                    width: parent.width
                    height: parent.height - 62
                    spacing: 6
                    clip: true
                    model: root.filteredApps
                    currentIndex: 0

                    onModelChanged: currentIndex = 0

                    delegate: Rectangle {
                        id: appRow
                        required property var modelData
                        required property int index

                        width: ListView.view.width
                        height: 52
                        radius: 13
                        color: index === results.currentIndex || appMouse.containsMouse
                            ? Theme.searchBackground : "transparent"

                        IconImage {
                            id: appIcon
                            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                            implicitSize: 32
                            source: Quickshell.iconPath(appRow.modelData.icon, "application-x-executable")
                        }

                        Column {
                            anchors { left: appIcon.right; right: parent.right; leftMargin: 12; rightMargin: 12; verticalCenter: parent.verticalCenter }
                            spacing: 1

                            Text {
                                width: parent.width
                                text: appRow.modelData.name
                                color: Theme.launcherText
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: appRow.modelData.comment || appRow.modelData.genericName || ""
                                color: Theme.launcherMuted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: appMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: results.currentIndex = appRow.index
                            onClicked: root.launchSelected()
                        }
                    }
                }
            }
        }
    }

    onLauncherOpenChanged: {
        if (launcherOpen)
            Qt.callLater(() => search.forceActiveFocus());
        else
            search.text = "";
    }
}
