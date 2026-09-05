pragma Singleton
import QtQuick

QtObject {
    readonly property bool dark: ShellSettings.colorMode === "dark"
    readonly property color surface: dark ? "#111719" : "#ffffff"
    readonly property color ink: dark ? "#f4f7f6" : "#111416"
    readonly property color mutedInk: dark ? "#aeb9b8" : "#596164"
    readonly property color launcherBackground: surface
    readonly property color searchBackground: dark ? "#20282a" : "#edf0f0"
    readonly property color launcherText: ink
    readonly property color launcherMuted: dark ? "#9eabaa" : "#667073"
    readonly property color launcherAccent: ink

    // Use badgeText for emoji, or set badgeSource to an image/GIF file path.
    readonly property string badgeText: ShellSettings.badgeText
    readonly property string badgeSource: ShellSettings.badgeMode === "image" ? ShellSettings.badgeSource : ""

    readonly property int frameWidth: 9
    readonly property int sidebarWidth: 76
    readonly property int innerRadius: 18
    readonly property int windowRadius: 14
    readonly property int launcherWidth: 668
    readonly property int launcherHeight: 500
    readonly property int launcherJoinRadius: 24
    readonly property int launcherResultCount: 7
    readonly property int wallpaperDeckHeight: 350
    readonly property int wallpaperJoinRadius: 28
    readonly property int wallpaperCardRadius: 18
    readonly property int controlCenterHeight: 610
    readonly property int controlCenterJoinRadius: 28
    readonly property int badgeDeckWidth: 146
    readonly property int badgeDeckJoinRadius: 27
    readonly property int badgeDeckReserve: sidebarWidth + badgeDeckWidth - badgeDeckJoinRadius
}
