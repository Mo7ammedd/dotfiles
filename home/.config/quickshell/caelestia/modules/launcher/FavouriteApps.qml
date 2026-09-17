pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

StyledRect {
    id: root
    required property ScreenState screenState
    readonly property var favourites: DesktopEntries.applications.values.filter(entry => Strings.testRegexList(GlobalConfig.launcher.favouriteApps, entry.id) && !Strings.testRegexList(GlobalConfig.launcher.hiddenApps, entry.id))

    implicitHeight: 62
    radius: Tokens.rounding.large
    color: Qt.alpha(Colours.palette.m3onSurface, 0.045)

    StyledText {
        id: label
        anchors.left: parent.left
        anchors.leftMargin: Tokens.padding.medium
        anchors.verticalCenter: parent.verticalCenter
        text: "Favourites"
        font: Tokens.font.label.medium
        color: Colours.palette.m3outline
    }

    Flickable {
        anchors.left: label.right
        anchors.leftMargin: Tokens.spacing.medium
        anchors.right: parent.right
        anchors.rightMargin: Tokens.padding.small
        anchors.verticalCenter: parent.verticalCenter
        height: 48
        contentWidth: icons.implicitWidth
        contentHeight: height
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
        clip: true

        Row {
            id: icons
            spacing: Tokens.spacing.small

            Repeater {
                model: root.favourites

                Rectangle {
                    id: favourite
                    required property var modelData
                    width: 48
                    height: 48
                    radius: Tokens.rounding.medium
                    color: Qt.alpha(Colours.palette.m3primary, 0.08)

                    StateLayer {
                        id: hover
                        radius: parent.radius
                        onClicked: {
                            Apps.launch(favourite.modelData);
                            root.screenState.launcher = false;
                        }
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 30
                        asynchronous: true
                        source: Quickshell.iconPath(favourite.modelData.icon, "image-missing")
                    }

                    Controls.ToolTip.visible: hover.containsMouse
                    Controls.ToolTip.text: modelData.name
                    Controls.ToolTip.delay: 400
                }
            }
        }
    }
}
