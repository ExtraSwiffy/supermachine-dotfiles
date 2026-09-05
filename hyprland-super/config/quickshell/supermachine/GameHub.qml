import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root
    required property ShellScreen targetScreen

    readonly property var monitor: Hyprland.monitorFor(targetScreen)
    readonly property bool hubOpen: GameState.open && GameState.screenName === monitor?.name
    property bool running: false
    property bool gameOver: false
    property int jumps: 0
    property real jumpLift: 0
    property real velocity: 0
    property real obstacleX: 900
    property real obstacleWidth: 32
    property real obstacleHeight: 56
    property bool obstaclePassed: false
    property real parallaxX: 0
    property int clearNumber: 0
    readonly property real gameSpeed: Math.min(19, 8.2 + Math.floor(jumps / 5) * 1.25)
    property real survivorX: 440
    property real survivorY: 300
    property real aimAngle: 0
    property bool moveUp: false
    property bool moveDown: false
    property bool moveLeft: false
    property bool moveRight: false

    function startGame() {
        GameState.page = "desert-dash";
        running = false;
        gameOver = false;
        jumps = 0;
        jumpLift = 0;
        velocity = 0;
        obstacleX = gameStage.width + 180;
        obstaclePassed = false;
        parallaxX = 0;
        Qt.callLater(() => focusArea.forceActiveFocus());
    }

    function startZombieFusion() {
        running = false;
        GameState.page = "zombie-fusion";
        survivorX = Math.max(120, zombieWorld.width / 2);
        survivorY = Math.max(120, zombieWorld.height / 2);
        moveUp = false;
        moveDown = false;
        moveLeft = false;
        moveRight = false;
        Qt.callLater(() => focusArea.forceActiveFocus());
    }

    function beginRun() {
        gameOver = false;
        jumps = 0;
        jumpLift = 0;
        velocity = 0;
        obstacleX = gameStage.width + 160;
        obstaclePassed = false;
        running = true;
    }

    function jump() {
        if (GameState.page !== "desert-dash")
            return;
        if (gameOver || !running)
            beginRun();
        if (jumpLift <= 1)
            velocity = 18;
    }

    function returnToLibrary() {
        running = false;
        gameOver = false;
        GameState.page = "library";
    }

    function collide() {
        const playerLeft = runner.x;
        const playerRight = runner.x + runner.width;
        const obstacleLeft = obstacle.x;
        const obstacleRight = obstacle.x + obstacle.width;
        return playerRight > obstacleLeft + 5
            && playerLeft < obstacleRight - 5
            && jumpLift < obstacle.height - 8;
    }

    screen: targetScreen
    color: "transparent"
    anchors { top: true; right: true; bottom: true; left: true }
    WlrLayershell.namespace: "supermachine-games"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: hubOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: hubOpen ? null : closedMask

    Region { id: closedMask }

    Rectangle {
        id: surface
        x: Theme.sidebarWidthFor(targetScreen)
        y: Theme.frameWidth
        width: root.width - Theme.sidebarWidthFor(targetScreen) - Theme.frameWidth
        height: root.height - Theme.frameWidth * 2
        color: Theme.dark ? "#1b2224" : "#e9eded"
        visible: root.hubOpen
        radius: Theme.innerRadius
        clip: true

        FocusScope {
            id: focusArea
            anchors.fill: parent
            focus: root.hubOpen

            Keys.onSpacePressed: root.jump()
            Keys.onPressed: event => {
                if (GameState.page !== "zombie-fusion")
                    return;
                if (event.key === Qt.Key_W) root.moveUp = true;
                if (event.key === Qt.Key_S) root.moveDown = true;
                if (event.key === Qt.Key_A) root.moveLeft = true;
                if (event.key === Qt.Key_D) root.moveRight = true;
            }
            Keys.onReleased: event => {
                if (event.key === Qt.Key_W) root.moveUp = false;
                if (event.key === Qt.Key_S) root.moveDown = false;
                if (event.key === Qt.Key_A) root.moveLeft = false;
                if (event.key === Qt.Key_D) root.moveRight = false;
            }
            Keys.onEscapePressed: {
                if (GameState.page !== "library")
                    root.returnToLibrary();
                else
                    GameState.close();
            }

            Item {
                anchors.fill: parent
                visible: GameState.page === "library"

                Column {
                    anchors { left: parent.left; top: parent.top; margins: 42 }
                    spacing: 7
                    Text {
                        text: "SUPEROS ARCADE"
                        color: Theme.ink
                        font.pixelSize: 28
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.4
                    }
                    Text {
                        text: "Play. Collect. Make the desktop yours."
                        color: Theme.mutedInk
                        font.pixelSize: 13
                    }
                }

                Grid {
                    anchors { left: parent.left; top: parent.top; leftMargin: 42; topMargin: 126 }
                    columns: Math.max(1, Math.floor((parent.width - 84) / 250))
                    spacing: 20

                    Rectangle {
                        id: gameCard
                        width: 224
                        height: 294
                        radius: 21
                        color: Theme.surface
                        border.width: gameCardMouse.containsMouse ? 3 : 1
                        border.color: gameCardMouse.containsMouse ? ShellSettings.windowBorderColor : (Theme.dark ? "#344043" : "#d0d7d7")
                        scale: gameCardMouse.containsMouse ? 1.025 : 1
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: 238
                            radius: 20
                            color: Theme.dark ? "#283638" : "#d9e4df"
                            clip: true

                            Rectangle { x: 0; y: 174; width: parent.width; height: 64; color: Theme.dark ? "#b67b46" : "#dfad70" }
                            Rectangle { x: 0; y: 170; width: parent.width; height: 4; color: Theme.dark ? "#d8ad6c" : "#a86d3e" }
                            Repeater {
                                model: [32, 82, 151, 194]
                                Rectangle {
                                    required property int modelData
                                    x: modelData; y: 139; width: 10; height: 34; radius: 4
                                    color: Theme.dark ? "#6f8e6b" : "#61845c"
                                }
                            }
                            Rectangle {
                                x: 49; y: 135; width: 31; height: 35; radius: 7
                                color: Theme.ink
                                Rectangle { x: 21; y: 7; width: 22; height: 7; radius: 4; rotation: -8; color: parent.color }
                                Rectangle { x: 4; y: 29; width: 7; height: 15; color: parent.color }
                                Rectangle { x: 21; y: 29; width: 7; height: 15; color: parent.color }
                            }
                            Text {
                                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 28 }
                                text: "50  ◇  100"
                                color: Theme.ink
                                font.pixelSize: 20
                                font.weight: Font.Bold
                            }
                        }

                        Column {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
                            spacing: 3
                            Text { text: "Desert Dash"; color: Theme.ink; font.pixelSize: 15; font.weight: Font.DemiBold }
                            Text { text: `Best  ${GameState.bestJumps} clears`; color: Theme.mutedInk; font.pixelSize: 11 }
                        }

                        MouseArea {
                            id: gameCardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startGame()
                        }
                    }

                    Rectangle {
                        id: zombieCard
                        width: 224
                        height: 294
                        radius: 21
                        color: Theme.surface
                        border.width: zombieCardMouse.containsMouse ? 3 : 1
                        border.color: zombieCardMouse.containsMouse ? "#8fc37a" : (Theme.dark ? "#344043" : "#d0d7d7")
                        scale: zombieCardMouse.containsMouse ? 1.025 : 1
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: 238
                            radius: 20
                            color: Theme.dark ? "#26332d" : "#c9ddbd"
                            clip: true
                            Repeater {
                                model: 14
                                Rectangle {
                                    required property int index
                                    x: (index * 47) % 210; y: 38 + ((index * 71) % 170)
                                    width: 9; height: 22; radius: 5
                                    color: index % 2 ? "#547d4d" : "#719860"
                                    rotation: index * 31
                                }
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 66; height: 66; radius: 24
                                color: "#252a2b"
                                rotation: 45
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: 30; height: 60; radius: 13
                                color: "#bfc6bd"
                            }
                            Rectangle {
                                x: parent.width / 2 + 8; y: parent.height / 2 - 48
                                width: 7; height: 57; radius: 3
                                color: "#d8b777"
                                rotation: 28
                            }
                            Text {
                                anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 24 }
                                text: "Z  F"
                                color: Theme.ink
                                font.pixelSize: 22
                                font.weight: Font.Black
                                font.letterSpacing: 6
                            }
                        }

                        Column {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 14 }
                            spacing: 3
                            Text { text: "Zombie Fusion"; color: Theme.ink; font.pixelSize: 15; font.weight: Font.DemiBold }
                            Text { text: "Top-down survival · prototype"; color: Theme.mutedInk; font.pixelSize: 10 }
                        }

                        MouseArea {
                            id: zombieCardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.startZombieFusion()
                        }
                    }
                }

                Text {
                    anchors { left: parent.left; bottom: parent.bottom; margins: 42 }
                    text: "ESC  CLOSE"
                    color: Theme.mutedInk
                    font.pixelSize: 10
                    font.letterSpacing: 1.2
                }
            }

            Item {
                anchors.fill: parent
                visible: GameState.page === "desert-dash"

                Row {
                    anchors { left: parent.left; top: parent.top; margins: 30 }
                    spacing: 24
                    Text { text: "DESERT DASH"; color: Theme.ink; font.pixelSize: 18; font.weight: Font.Bold; font.letterSpacing: 1.2 }
                    Text { text: `CLEARS  ${root.jumps}`; color: Theme.ink; font.pixelSize: 14 }
                    Text { text: `BEST  ${GameState.bestJumps}`; color: Theme.mutedInk; font.pixelSize: 14 }
                }

                Item {
                    id: gameStage
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 42 }
                    height: Math.min(430, parent.height - 150)
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        radius: 22
                        color: Theme.dark ? "#222e30" : "#f3e4c7"
                        border.width: 1
                        border.color: Theme.dark ? "#3b494b" : "#d7c29c"
                    }

                    Item {
                        anchors.fill: parent
                        clip: true
                        opacity: 0.34
                        Repeater {
                            model: 9
                            Rectangle {
                                required property int index
                                readonly property real span: gameStage.width + 420
                                x: (((index * 260 + root.parallaxX * 0.22) % span) + span) % span - 210
                                y: gameStage.height - 190 - (index % 3) * 30
                                width: 190 + (index % 2) * 70
                                height: width
                                rotation: 45
                                radius: 12
                                color: Theme.dark ? "#53686a" : "#b5c8bd"
                            }
                        }
                        Repeater {
                            model: 11
                            Rectangle {
                                required property int index
                                readonly property real span: gameStage.width + 330
                                x: (((index * 190 + root.parallaxX * 0.48) % span) + span) % span - 165
                                y: gameStage.height - 142 - (index % 2) * 24
                                width: 135 + (index % 3) * 34
                                height: width
                                rotation: 45
                                radius: 9
                                color: Theme.dark ? "#765e4b" : "#cca477"
                            }
                        }
                    }

                    Rectangle { x: 0; y: parent.height - 76; width: parent.width; height: 76; color: Theme.dark ? "#8b633f" : "#d4a56d" }
                    Rectangle { x: 0; y: parent.height - 79; width: parent.width; height: 4; color: Theme.dark ? "#d3a266" : "#9f6c3f" }

                    Item {
                        id: runner
                        x: Math.max(80, gameStage.width * 0.14)
                        y: gameStage.height - 79 - height - root.jumpLift
                        width: 42; height: 48
                        Rectangle { x: 4; y: 5; width: 31; height: 31; radius: 8; color: Theme.ink }
                        Rectangle { x: 28; y: 0; width: 25; height: 9; radius: 5; rotation: -7; color: Theme.ink }
                        Rectangle { x: 8; y: 33; width: 7; height: 15; radius: 2; color: Theme.ink }
                        Rectangle { x: 28; y: 33; width: 7; height: 15; radius: 2; color: Theme.ink }
                    }

                    Rectangle {
                        id: obstacle
                        x: root.obstacleX
                        y: gameStage.height - 79 - height
                        width: root.obstacleWidth
                        height: root.obstacleHeight
                        radius: 6
                        color: Theme.dark ? "#71906c" : "#547c51"
                        Rectangle { x: -10; y: 17; width: 13; height: 8; radius: 4; color: parent.color }
                        Rectangle { x: width - 3; y: 29; width: 14; height: 8; radius: 4; color: parent.color }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: !root.running
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.gameOver ? "RUN ENDED" : "READY?"
                            color: Theme.ink
                            font.pixelSize: 28
                            font.weight: Font.Bold
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.gameOver ? `You cleared ${root.jumps} obstacles · Space to retry` : "Press Space to run and jump"
                            color: Theme.mutedInk
                            font.pixelSize: 13
                        }
                    }

                    Rectangle {
                        id: clearPopup
                        anchors.centerIn: parent
                        width: 92; height: 92
                        radius: 46
                        color: Theme.surface
                        border.width: 4
                        border.color: ShellSettings.windowBorderColor
                        opacity: 0
                        scale: 0.55
                        z: 200
                        Text {
                            anchors.centerIn: parent
                            text: root.clearNumber
                            color: Theme.ink
                            font.pixelSize: 31
                            font.weight: Font.Bold
                        }
                    }
                }

                Row {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 30 }
                    spacing: 34
                    Text { text: GameState.roadrunnerUnlocked ? "✓ 50  ROADRUNNER" : "◇ 50  LOCKED"; color: GameState.roadrunnerUnlocked ? "#86d9d9" : Theme.mutedInk; font.pixelSize: 11 }
                    Text { text: GameState.coyoteUnlocked ? "✓ 100  COYOTE" : "◇ 100  LOCKED"; color: GameState.coyoteUnlocked ? "#e3b968" : Theme.mutedInk; font.pixelSize: 11 }
                    Text { text: "ESC  GAMES"; color: Theme.mutedInk; font.pixelSize: 11 }
                }
            }

            Item {
                anchors.fill: parent
                visible: GameState.page === "zombie-fusion"

                Row {
                    anchors { left: parent.left; top: parent.top; margins: 28 }
                    spacing: 24
                    Text { text: "ZOMBIE FUSION"; color: Theme.ink; font.pixelSize: 18; font.weight: Font.Bold; font.letterSpacing: 1.2 }
                    Text { text: "WORLD 01 · GREENWARD"; color: Theme.mutedInk; font.pixelSize: 12 }
                }

                Rectangle {
                    id: zombieWorld
                    anchors { fill: parent; leftMargin: 36; rightMargin: 36; topMargin: 76; bottomMargin: 44 }
                    radius: 22
                    color: "#789b62"
                    border.width: 7
                    border.color: "#344839"
                    clip: true

                    Repeater {
                        model: 42
                        Rectangle {
                            required property int index
                            x: 20 + ((index * 137) % Math.max(40, zombieWorld.width - 50))
                            y: 20 + ((index * 83) % Math.max(40, zombieWorld.height - 50))
                            width: 5 + index % 5; height: 2; radius: 1
                            rotation: (index * 47) % 180
                            color: index % 3 ? "#9ab57b" : "#607f50"
                            opacity: 0.72
                        }
                    }

                    Repeater {
                        model: 18
                        Item {
                            required property int index
                            x: index < 5 ? 12 + index * (zombieWorld.width - 80) / 4
                                : index < 10 ? 12 + (index - 5) * (zombieWorld.width - 80) / 4
                                : index % 2 ? 9 : zombieWorld.width - 63
                            y: index < 5 ? 8 : index < 10 ? zombieWorld.height - 70 : 54 + (index - 10) * (zombieWorld.height - 150) / 7
                            width: 54; height: 62
                            z: 20
                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: 34; width: 11; height: 27; radius: 4; color: "#554536" }
                            Rectangle { x: 5; y: 3; width: 44; height: 44; radius: 22; color: index % 2 ? "#355943" : "#416b47" }
                            Rectangle { x: 14; y: 0; width: 28; height: 29; radius: 15; color: index % 2 ? "#4d7950" : "#527e54" }
                        }
                    }

                    Item {
                        id: survivor
                        x: root.survivorX - width / 2
                        y: root.survivorY - height / 2
                        width: 58; height: 58
                        z: 100
                        rotation: root.aimAngle
                        Rectangle {
                            anchors.centerIn: parent
                            width: 38; height: 44; radius: 15
                            color: "#24282c"
                            border.width: 3; border.color: "#6b3943"
                        }
                        Rectangle {
                            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 1 }
                            width: 25; height: 25; radius: 13
                            color: "#d0b39a"
                            Rectangle { x: 4; y: 3; width: 17; height: 8; radius: 5; color: "#342d30" }
                        }
                        Rectangle {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.top; bottomMargin: -5 }
                            width: 5; height: 39; radius: 3
                            color: "#d5b76f"
                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: -9; width: 15; height: 13; radius: 7; color: "#aeb5ad" }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                        onPositionChanged: mouse => {
                            root.aimAngle = Math.atan2(mouse.y - root.survivorY, mouse.x - root.survivorX) * 180 / Math.PI + 90;
                        }
                    }
                }

                Text {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 16 }
                    text: "WASD  MOVE    ·    MOUSE  AIM    ·    ESC  GAMES"
                    color: Theme.mutedInk
                    font.pixelSize: 10
                    font.letterSpacing: 1.1
                }
            }
        }
    }

    Timer {
        interval: 16
        repeat: true
        running: root.hubOpen && root.running && GameState.page === "desert-dash"
        onTriggered: {
            root.jumpLift += root.velocity;
            root.velocity -= 0.92;
            if (root.jumpLift < 0) {
                root.jumpLift = 0;
                root.velocity = 0;
            }
            root.obstacleX -= root.gameSpeed;
            root.parallaxX -= root.gameSpeed;
            if (!root.obstaclePassed && root.obstacleX + root.obstacleWidth < runner.x) {
                root.obstaclePassed = true;
                root.jumps += 1;
                GameState.record(root.jumps);
                root.clearNumber = root.jumps;
                clearSound.play();
                clearAnimation.restart();
            }
            if (root.obstacleX < -root.obstacleWidth) {
                root.obstacleX = gameStage.width + 55 + Math.random() * 125;
                root.obstacleHeight = 42 + Math.random() * 38;
                root.obstacleWidth = 24 + Math.random() * 18;
                root.obstaclePassed = false;
            }
            if (root.collide()) {
                root.running = false;
                root.gameOver = true;
                GameState.record(root.jumps);
            }
        }
    }

    Timer {
        interval: 16
        repeat: true
        running: root.hubOpen && GameState.page === "zombie-fusion"
        onTriggered: {
            let dx = (root.moveRight ? 1 : 0) - (root.moveLeft ? 1 : 0);
            let dy = (root.moveDown ? 1 : 0) - (root.moveUp ? 1 : 0);
            if (dx !== 0 && dy !== 0) {
                dx *= 0.7071;
                dy *= 0.7071;
            }
            root.survivorX = Math.max(82, Math.min(zombieWorld.width - 82, root.survivorX + dx * 4.8));
            root.survivorY = Math.max(82, Math.min(zombieWorld.height - 82, root.survivorY + dy * 4.8));
        }
    }

    SoundEffect {
        id: clearSound
        source: Qt.resolvedUrl("assets/audio/clear.wav")
        volume: 0.92
    }

    MediaPlayer {
        id: music
        source: Qt.resolvedUrl("assets/audio/desert-loop.ogg")
        loops: MediaPlayer.Infinite
        property bool shouldPlay: root.hubOpen && GameState.page === "desert-dash"
        onShouldPlayChanged: shouldPlay ? play() : pause()
        audioOutput: AudioOutput { volume: 0.68 }
    }

    SequentialAnimation {
        id: clearAnimation
        ParallelAnimation {
            NumberAnimation { target: clearPopup; property: "opacity"; from: 0; to: 0.96; duration: 100 }
            NumberAnimation { target: clearPopup; property: "scale"; from: 0.55; to: 1.08; duration: 150; easing.type: Easing.OutBack }
        }
        PauseAnimation { duration: 230 }
        ParallelAnimation {
            NumberAnimation { target: clearPopup; property: "opacity"; to: 0; duration: 220 }
            NumberAnimation { target: clearPopup; property: "scale"; to: 1.3; duration: 220; easing.type: Easing.InCubic }
        }
    }

    onHubOpenChanged: {
        if (hubOpen)
            Qt.callLater(() => focusArea.forceActiveFocus());
        else
            running = false;
    }
}
