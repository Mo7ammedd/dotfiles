pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services

Item {
    id: root
    property bool centered: false
    implicitWidth: 392
    implicitHeight: 190
    readonly property date today: DateTime.clock.date
    readonly property int weekday: (today.getDay() + 6) % 7

    DeskText {
        x: root.centered ? (root.width - width) / 2 : 4
        y: 0
        text: Qt.formatDateTime(root.today, "dddd, dd MMMM").toUpperCase()
        font.family: DeskTheme.mono
        font.pixelSize: 11
        font.letterSpacing: 1.2
        color: "#d2d8eb"
    }
    DeskText {
        x: root.centered ? (root.width - width) / 2 : 0
        y: 19
        text: DateTime.time
        font.family: "Inter Display"
        font.pixelSize: 94
        font.weight: Font.Medium
        font.letterSpacing: -4
        color: "#f4f5fd"
    }
    Row {
        id: week
        x: root.centered ? (root.width - width) / 2 : 4
        y: 140
        spacing: 9
        Repeater {
            model: ["M", "T", "W", "T", "F", "S", "S"]
            delegate: Rectangle {
                required property int index
                required property string modelData
                width: 33
                height: 31
                radius: 10
                color: index === root.weekday ? DeskTheme.accent : "#59151b29"
                border.width: index === root.weekday ? 0 : 1
                border.color: "#20ffffff"
                DeskText {
                    anchors.centerIn: parent
                    text: parent.modelData
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: parent.index === root.weekday ? "#151b29" : "#c5ccdf"
                }
            }
        }
    }
}
