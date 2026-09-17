import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.effects
import qs.components.images
import qs.services

Item {
    id: root

    required property FileSystemEntry modelData
    required property ScreenState screenState
    required property real thumbnailWidth

    readonly property bool isApplied: modelData.path === Wallpapers.actualCurrent
    readonly property bool shouldLoadPalette: screenState.launcher && PathView.onPath && !(PathView.view?.moving ?? false)
    property var paletteColours: []
    property bool paletteLoaded: false

    onShouldLoadPaletteChanged: {
        if (shouldLoadPalette && !paletteLoaded)
            paletteDelay.restart();
    }

    onModelDataChanged: {
        paletteColours = [];
        paletteLoaded = false;
        if (shouldLoadPalette)
            paletteDelay.restart();
    }

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0 // qmllint disable missing-property

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.88 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
        if (shouldLoadPalette)
            paletteDelay.restart();
    }

    implicitWidth: image.width + Tokens.padding.medium * 2
    implicitHeight: image.height + label.height + swatches.height + Tokens.spacing.extraSmall + Tokens.spacing.small + Tokens.padding.large + Tokens.padding.medium

    Timer {
        id: paletteDelay
        interval: 120
        onTriggered: {
            if (root.shouldLoadPalette && !root.paletteLoaded && !paletteProc.running) {
                paletteProc.requestPath = root.modelData.path;
                paletteProc.running = true;
            }
        }
    }

    Process {
        id: paletteProc
        property string requestPath
        command: ["python3", Quickshell.shellPath("utils/scripts/wallpaper-palette.py"), requestPath]
        stdout: StdioCollector { id: paletteOutput }
        onExited: code => {
            if (requestPath !== root.modelData.path) {
                paletteDelay.restart();
                return;
            }
            root.paletteLoaded = true;
            if (code === 0) {
                try {
                    root.paletteColours = JSON.parse(paletteOutput.text);
                } catch (e) {
                    root.paletteColours = [];
                }
            }
        }
    }

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: {
            Wallpapers.setWallpaper(root.modelData.path);
            root.screenState.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    StyledClippingRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large

        implicitWidth: root.thumbnailWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: "image"
            color: Colours.tPalette.m3outline
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
        }

        CachingImage {
            anchors.fill: parent
            path: root.modelData.path
            smooth: !root.PathView.view.moving
            sourceSize: {
                const dpr = (QsWindow.window as QsWindow)?.devicePixelRatio ?? 1;
                return Qt.size(image.implicitWidth * dpr, image.implicitHeight * dpr);
            }
        }
    }

    Rectangle {
        anchors.fill: image
        anchors.margins: -5
        radius: image.radius + 5
        color: "transparent"
        border.width: root.isApplied ? 3 : 2
        border.color: root.isApplied ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
        opacity: root.isApplied || root.PathView.isCurrentItem ? 1 : 0

        Behavior on opacity { Anim { type: Anim.DefaultEffects } }
    }

    Rectangle {
        visible: root.isApplied
        anchors.top: image.top
        anchors.right: image.right
        anchors.margins: Tokens.padding.small
        width: currentLabel.implicitWidth + Tokens.padding.medium * 2
        height: currentLabel.implicitHeight + Tokens.padding.small * 2
        radius: height / 2
        color: Colours.palette.m3primary

        StyledText {
            id: currentLabel
            anchors.centerIn: parent
            text: "✓ Current"
            font: Tokens.font.label.small
            color: Colours.palette.m3onPrimary
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Tokens.spacing.extraSmall
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Tokens.padding.medium * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData.relativePath
        font: Tokens.font.label.medium
    }

    Item {
        id: swatches
        anchors.top: label.bottom
        anchors.topMargin: Tokens.spacing.small
        anchors.horizontalCenter: parent.horizontalCenter
        width: image.width
        height: 18

        Row {
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: root.paletteColours

                Rectangle {
                    required property string modelData
                    width: 18
                    height: 18
                    radius: 9
                    color: modelData
                    border.width: 1
                    border.color: Qt.alpha(Colours.palette.m3onSurface, 0.25)

                    MouseArea {
                        id: swatchHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    Controls.ToolTip.visible: swatchHover.containsMouse
                    Controls.ToolTip.text: modelData.toUpperCase()
                    Controls.ToolTip.delay: 500
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: root.paletteColours.length === 0
            text: root.paletteLoaded ? "Palette unavailable" : "Reading colours…"
            font: Tokens.font.label.small
            color: Colours.palette.m3outline
        }
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
