pragma Singleton
import QtQuick

QtObject {
    readonly property color surface: "#ffffff"
    readonly property color ink: "#111416"
    readonly property color mutedInk: "#596164"
    readonly property color launcherBackground: "#111416"
    readonly property color searchBackground: "#24292c"
    readonly property color launcherText: "#f4f6f6"
    readonly property color launcherMuted: "#9da6a8"
    readonly property color launcherAccent: "#ffffff"

    // Use badgeText for emoji, or set badgeSource to an image/GIF file path.
    readonly property string badgeText: "🚀"
    readonly property string badgeSource: ""

    readonly property int frameWidth: 9
    readonly property int sidebarWidth: 76
    readonly property int innerRadius: 18
    readonly property int windowRadius: 14
    readonly property int launcherWidth: 668
    readonly property int launcherHeight: 500
    readonly property int launcherJoinRadius: 24
    readonly property int launcherResultCount: 7
}
