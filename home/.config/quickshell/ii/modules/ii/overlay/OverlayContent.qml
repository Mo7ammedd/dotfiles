import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.ii.desktopWidgets as Desk

Item {
    id: root
    focus: true
    property bool showUtilities: false
    Connections {
        target: GlobalStates
        function onOverlayOpenChanged() {
            if (!GlobalStates.overlayOpen) root.showUtilities = false;
        }
    }
    readonly property bool usePasswordChars: !PolkitService.flow?.responseVisible ?? true

    Keys.onPressed: (event) => { // Esc to close
        if (event.key === Qt.Key_Escape) {
            GlobalStates.overlayOpen = false;
        }
    }

    property real initScale: Config.options.overlay.openingZoomAnimation ? 1.08 : 1.000001
    scale: initScale
    Component.onCompleted: {
        scale = 1
    }
    Behavior on scale {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Appearance.colors.colScrim
        visible: Config.options.overlay.darkenScreen && opacity > 0
        opacity: (GlobalStates.overlayOpen && root.scale !== initScale) ? 1 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    MouseArea {
        anchors.fill: parent
        visible: Config.options.desktopWidgets.enable && GlobalStates.overlayOpen && !root.showUtilities
        onClicked: GlobalStates.overlayOpen = false
    }

    Item {
        id: dashboard
        visible: Config.options.desktopWidgets.enable && GlobalStates.overlayOpen && !root.showUtilities
        anchors.centerIn: parent
        width: 1054
        height: 548
        scale: Math.min(1, (root.width - 100) / width, (root.height - 96) / height)

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            height: 36
            spacing: 8
            Desk.DeskText {
                text: "WIDGETS"
                color: Desk.DeskTheme.muted
                font.family: Desk.DeskTheme.mono
                font.pixelSize: 11
                font.letterSpacing: 2
            }
            Item { Layout.fillWidth: true }
            Desk.DeskButton {
                objectName: "deskVisibility"
                symbol: Config.options.desktopWidgets.showOnDesktop ? "desktop_windows" : "hide_source"
                text: Config.options.desktopWidgets.showOnDesktop ? "On desktop" : "Hidden on desktop"
                Accessible.name: "Toggle widgets on the desktop"
                onClicked: Config.options.desktopWidgets.showOnDesktop = !Config.options.desktopWidgets.showOnDesktop
            }
            Desk.DeskButton {
                objectName: "deskUtilities"
                symbol: "tune"
                text: "Utilities"
                onClicked: root.showUtilities = true
            }
            Desk.DeskButton {
                symbol: "close"
                Accessible.name: "Close widgets"
                onClicked: GlobalStates.overlayOpen = false
            }
        }
        Desk.WidgetDeck {
            y: 62
            width: parent.width
            dashboard: true
        }
        Desk.DeskText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            text: "SUPER + D  /  ESC TO CLOSE"
            font.family: Desk.DeskTheme.mono
            font.pixelSize: 9
            font.letterSpacing: 1
            color: Desk.DeskTheme.faint
        }
    }

    Desk.DeskButton {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
        visible: Config.options.desktopWidgets.enable && GlobalStates.overlayOpen && root.showUtilities
        z: 1
        text: "Back to widgets"
        symbol: "arrow_back"
        onClicked: root.showUtilities = false
    }

    WidgetCanvas {
        visible: !Config.options.desktopWidgets.enable || root.showUtilities || !GlobalStates.overlayOpen
        anchors.fill: parent
        onClicked: GlobalStates.overlayOpen = false

        OverlayTaskbar {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 50
            }
        }

        Repeater {
            model: ScriptModel {
                values: Persistent.states.overlay.open.map(identifier => {
                    return OverlayContext.availableWidgets.find(w => w.identifier === identifier);
                })
                objectProp: "identifier"
            }
            delegate: OverlayWidgetDelegateChooser {
                
            }
        }
    }
}
