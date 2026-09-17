import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root
    required property var fileModelData
    property bool selected: false
    property bool isCurrent: false
    property color accentColor: Appearance.colors.colPrimary
    property string thumbnailSizeName: "x-large"
    readonly property bool isDirectory: fileModelData.fileIsDir
    readonly property string extension: fileModelData.fileName.split(".").pop().toLowerCase()
    readonly property bool isVideo: !isDirectory && Wallpapers.videoExtensions.includes(extension)
    readonly property string displayName: isDirectory ? fileModelData.fileName : fileModelData.fileName.replace(/\.[^.]+$/, "").replace(/[_-]+/g, " ")

    signal activated
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()
    Accessible.role: Accessible.Button
    Accessible.name: fileModelData.fileName
    Accessible.onPressAction: root.activated()
    ToolTip.visible: containsMouse
    ToolTip.text: fileModelData.fileName
    ToolTip.delay: 900

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 6
        radius: 14
        color: root.selected || root.containsMouse ? "#272b34" : "#1b1f27"
        border.width: 1
        border.color: root.selected || root.isCurrent ? ColorUtils.applyAlpha(root.accentColor, 0.8) : "#2d313a"
        Behavior on color {
            ColorAnimation {
                duration: 130
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 130
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0
            Rectangle {
                id: preview
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 9
                color: "#14171d"
                clip: true

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: root.isDirectory ? "folder_open" : root.isVideo ? "slow_motion_video" : "image"
                    iconSize: root.isDirectory ? 52 : 36
                    color: root.isDirectory ? root.accentColor : "#535c6c"
                }
                Loader {
                    anchors.fill: parent
                    active: !root.isDirectory
                    sourceComponent: ThumbnailImage {
                        id: thumbnailImage
                        sourcePath: root.fileModelData.filePath
                        thumbnailSizeName: root.thumbnailSizeName
                        generateThumbnail: false
                        cache: false
                        fillMode: Image.PreserveAspectCrop

                        function refreshThumbnail() {
                            source = "";
                            source = thumbnailPath;
                        }
                        Connections {
                            target: Wallpapers
                            function onThumbnailGenerated(directory) {
                                if (thumbnailImage.status !== Image.Ready && FileUtils.parentDirectory(thumbnailImage.sourcePath) === FileUtils.trimFileProtocol(directory))
                                    thumbnailImage.refreshThumbnail();
                            }
                            function onThumbnailGeneratedFile(filePath) {
                                if (thumbnailImage.sourcePath === filePath)
                                    thumbnailImage.refreshThumbnail();
                            }
                        }
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: preview.width
                                height: preview.height
                                radius: preview.radius
                            }
                        }
                    }
                }
                Rectangle {
                    visible: root.isVideo
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 9
                    implicitWidth: videoBadge.implicitWidth + 14
                    implicitHeight: 26
                    radius: 7
                    color: "#dd11141a"
                    RowLayout {
                        id: videoBadge
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            text: "play_arrow"
                            iconSize: 16
                            color: "#f2f4f9"
                        }
                        StyledText {
                            text: Translation.tr("VIDEO")
                            color: "#f2f4f9"
                            font.pixelSize: 9
                            font.letterSpacing: 0.8
                            font.weight: Font.DemiBold
                        }
                    }
                }
                Rectangle {
                    visible: root.isCurrent
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 9
                    implicitWidth: currentBadge.implicitWidth + 14
                    implicitHeight: 26
                    radius: 7
                    color: root.accentColor
                    RowLayout {
                        id: currentBadge
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            text: "check"
                            iconSize: 14
                            color: "#14171d"
                        }
                        StyledText {
                            text: Translation.tr("Current")
                            color: "#14171d"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                Layout.leftMargin: 5
                Layout.rightMargin: 5
                spacing: 8
                StyledText {
                    Layout.fillWidth: true
                    text: root.displayName
                    color: "#e9ecf4"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                StyledText {
                    text: root.isDirectory ? Translation.tr("FOLDER") : root.extension.toUpperCase()
                    color: root.isVideo ? root.accentColor : "#929bab"
                    font.pixelSize: 9
                    font.letterSpacing: 0.8
                }
            }
        }
    }
}
