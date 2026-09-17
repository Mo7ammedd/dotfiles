pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.modules.common.widgets
import qs.services

WidgetCard {
    id: root
    implicitWidth: 392
    implicitHeight: 254
    readonly property var player: MprisController.activePlayer
    readonly property real trackLength: Math.max(0, player?.length ?? 0)
    readonly property real trackPosition: Math.max(0, player?.position ?? 0)
    readonly property real progress: trackLength > 0 ? Math.min(1, trackPosition / trackLength) : 0

    function timestamp(seconds: real): string {
        const value = Math.floor(Number.isFinite(seconds) ? seconds : 0);
        return Math.floor(value / 60) + ":" + (value % 60).toString().padStart(2, "0");
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.visible && (root.player?.isPlaying ?? false) && (root.player?.positionSupported ?? false)
        onTriggered: root.player.positionChanged()
    }
    DeskText {
        x: 22; y: 19
        text: "NOW PLAYING"
        font.family: DeskTheme.mono
        font.pixelSize: 10
        font.letterSpacing: 1.5
        color: DeskTheme.muted
    }
    MaterialSymbol {
        anchors.right: parent.right
        anchors.rightMargin: 22
        y: 17
        text: root.player?.isPlaying ? "graphic_eq" : "headphones"
        iconSize: 18
        color: DeskTheme.accent
    }
    ClippingRectangle {
        id: artwork
        x: 22; y: 53
        width: 96; height: 96
        radius: 10
        color: DeskTheme.tile
        Repeater {
            model: 4
            delegate: Rectangle {
                required property int index
                anchors.centerIn: parent
                width: 82 - index * 16
                height: width
                radius: width / 2
                color: "transparent"
                border.color: DeskTheme.line
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: 20; height: 20; radius: 10
            color: DeskTheme.accent
            Rectangle { anchors.centerIn: parent; width: 5; height: 5; radius: 3; color: "#1b2233" }
        }
        Image {
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            sourceSize.width: 240
            sourceSize.height: 240
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            visible: status === Image.Ready
        }
    }
    Column {
        x: 135; y: 55
        width: root.width - x - 22
        spacing: 6
        DeskText {
            width: parent.width
            text: root.player?.identity?.toUpperCase() || "YOUR SOUNDTRACK"
            font.family: DeskTheme.mono
            font.pixelSize: 9
            font.letterSpacing: 0.8
            color: DeskTheme.accent
        }
        DeskText {
            width: parent.width
            text: root.player ? (root.player.trackTitle || "Untitled track") : "Nothing playing"
            font.pixelSize: 17
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: 2
        }
        DeskText {
            width: parent.width
            text: root.player ? (root.player.trackArtist || root.player.trackAlbum || "") : "Play something in your music app."
            font.pixelSize: 11
            color: DeskTheme.muted
            maximumLineCount: 2
            wrapMode: Text.Wrap
        }
    }
    Item {
        id: seekBar
        x: 22; y: 166
        width: root.width - 44; height: 18
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width; height: 3; radius: 2
            color: DeskTheme.track
            Rectangle { height: parent.height; width: parent.width * root.progress; radius: 2; color: DeskTheme.accent }
        }
        MouseArea {
            anchors.fill: parent
            enabled: (root.player?.canSeek ?? false) && root.trackLength > 0
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: mouse => root.player.position = Math.max(0, Math.min(1, mouse.x / width)) * root.trackLength
        }
    }
    DeskText {
        x: 22; y: 205
        text: root.player ? root.timestamp(root.trackPosition) : "—:—"
        font.family: DeskTheme.mono; font.pixelSize: 10; color: DeskTheme.muted
    }
    DeskText {
        anchors.right: parent.right; anchors.rightMargin: 22
        y: 205
        text: root.trackLength > 0 ? root.timestamp(root.trackLength) : "—:—"
        font.family: DeskTheme.mono; font.pixelSize: 10; color: DeskTheme.muted
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 193
        spacing: 8
        DeskButton {
            symbol: "skip_previous"
            Accessible.name: "Previous track"
            enabled: MprisController.canGoPrevious
            onClicked: MprisController.previous()
        }
        DeskButton {
            width: 50
            primary: true
            symbol: root.player?.isPlaying ? "pause" : "play_arrow"
            Accessible.name: root.player?.isPlaying ? "Pause music" : "Play music"
            enabled: MprisController.canTogglePlaying
            onClicked: MprisController.togglePlaying()
        }
        DeskButton {
            symbol: "skip_next"
            Accessible.name: "Next track"
            enabled: MprisController.canGoNext
            onClicked: MprisController.next()
        }
    }
}
