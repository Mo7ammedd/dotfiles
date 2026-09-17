import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common.widgets

AbstractButton {
    id: root
    property string symbol: ""
    property bool primary: false
    property bool selected: false
    implicitHeight: 36
    implicitWidth: Math.max(36, contents.implicitWidth + 24)
    hoverEnabled: true
    opacity: enabled ? 1 : 0.35
    Accessible.name: text || symbol
    background: Rectangle {
        radius: 10
        color: root.primary || root.selected ? (root.down ? "#a9b7e7" : root.hovered ? "#d1daf9" : DeskTheme.accent)
            : root.down ? DeskTheme.tilePressed : root.hovered ? DeskTheme.tileHover : DeskTheme.tile
        border.width: root.primary || root.selected ? (root.activeFocus ? 1 : 0) : 1
        border.color: root.activeFocus ? DeskTheme.accent : DeskTheme.line
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    contentItem: Item {
        RowLayout {
            id: contents
            anchors.centerIn: parent
            spacing: 6
            MaterialSymbol {
                visible: root.symbol.length > 0
                text: root.symbol
                iconSize: 19
                color: root.primary || root.selected ? DeskTheme.accentInk : DeskTheme.ink
            }
            DeskText {
                visible: root.text.length > 0
                text: root.text
                font.pixelSize: 12
                font.weight: Font.Medium
                color: root.primary || root.selected ? DeskTheme.accentInk : DeskTheme.ink
            }
        }
    }
    ToolTip.visible: hovered && text.length === 0
    ToolTip.delay: 600
    ToolTip.text: Accessible.name
}
