pragma Singleton
import QtQuick

QtObject {
    readonly property color surface: "#ffffff"
    readonly property color ink: "#111416"
    readonly property color mutedInk: "#596164"
    readonly property color launcherBackground: "#ffffff"
    readonly property color searchBackground: "#edf0f0"
    readonly property color launcherText: "#111416"
    readonly property color launcherMuted: "#667073"
    readonly property color launcherAccent: "#111416"

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
