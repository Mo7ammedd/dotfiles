pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets
import qs.services

WidgetCard {
    id: root
    implicitWidth: 326
    implicitHeight: 254
    readonly property real cpu: Math.max(0, Math.min(1, ResourceUsage.cpuUsage))
    readonly property real memory: Math.max(0, Math.min(1, ResourceUsage.memoryUsedPercentage))
    readonly property bool connected: Network.ethernet || Network.networkName.length > 0

    DeskText {
        x: 22; y: 19
        text: "SYSTEM"
        font.family: DeskTheme.mono; font.pixelSize: 10; font.letterSpacing: 1.5
        color: DeskTheme.muted
    }
    DeskText {
        anchors.right: parent.right; anchors.rightMargin: 22
        y: 20
        text: "UP " + DateTime.uptime.toUpperCase()
        font.family: DeskTheme.mono; font.pixelSize: 9
        color: DeskTheme.faint
    }
    Row {
        x: 22; y: 63; spacing: 8
        Rectangle { y: 5; width: 6; height: 6; radius: 3; color: DeskTheme.mint }
        DeskText { text: "CPU"; font.pixelSize: 12; color: DeskTheme.muted }
    }
    DeskText {
        anchors.right: parent.right; anchors.rightMargin: 22
        y: 42
        text: Math.round(root.cpu * 100) + "%"
        font.family: "Inter Display"; font.pixelSize: 42; font.weight: Font.Medium; font.letterSpacing: -1
    }
    Canvas {
        id: graph
        x: 22; y: 98
        width: root.width - 44; height: 44
        property var samples: ResourceUsage.cpuUsageHistory
        onSamplesChanged: requestPaint()
        onWidthChanged: requestPaint()
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = "#18d2d8eb";
            ctx.lineWidth = 1;
            for (let i = 1; i <= 2; i++) {
                ctx.beginPath();
                ctx.moveTo(0, height * i / 3);
                ctx.lineTo(width, height * i / 3);
                ctx.stroke();
            }
            if (samples.length < 2) return;
            const values = samples.slice(-48);
            const step = width / (values.length - 1);
            const yFor = value => height - 3 - Math.max(0, Math.min(1, value)) * (height - 6);
            ctx.beginPath();
            ctx.moveTo(0, height);
            for (let i = 0; i < values.length; i++) ctx.lineTo(i * step, yFor(values[i]));
            ctx.lineTo(width, height);
            ctx.closePath();
            const fill = ctx.createLinearGradient(0, 0, 0, height);
            fill.addColorStop(0, "#40bdc8f4");
            fill.addColorStop(1, "#03bdc8f4");
            ctx.fillStyle = fill;
            ctx.fill();
            ctx.beginPath();
            ctx.moveTo(0, yFor(values[0]));
            for (let i = 1; i < values.length; i++) ctx.lineTo(i * step, yFor(values[i]));
            ctx.strokeStyle = DeskTheme.mint;
            ctx.lineWidth = 1.6;
            ctx.lineJoin = "round";
            ctx.stroke();
        }
    }
    DeskText { x: 22; y: 157; text: "Memory"; font.pixelSize: 12; color: DeskTheme.muted }
    DeskText {
        anchors.right: parent.right; anchors.rightMargin: 22; y: 158
        text: (ResourceUsage.memoryUsed / 1048576).toFixed(1) + " / " + (ResourceUsage.memoryTotal / 1048576).toFixed(0) + " GB"
        font.family: DeskTheme.mono; font.pixelSize: 10
    }
    Row {
        x: 22; y: 184
        spacing: 3
        Repeater {
            model: 28
            delegate: Rectangle {
                required property int index
                width: (root.width - 44 - 27 * 3) / 28
                height: 7; radius: 2
                color: index / 28 < root.memory ? DeskTheme.accent : DeskTheme.tile
            }
        }
    }
    Rectangle { x: 22; y: 207; width: root.width - 44; height: 1; color: DeskTheme.line }
    Row {
        x: 22; y: 221; spacing: 6
        MaterialSymbol {
            text: Battery.available ? (Battery.isPluggedIn ? "battery_charging_full" : "battery_horiz_075") : "power"
            iconSize: 16
            color: Battery.isLow ? "#edb2a1" : DeskTheme.muted
        }
        DeskText {
            text: Battery.available ? Math.round(Battery.percentage * 100) + "%" : "AC"
            font.family: DeskTheme.mono; font.pixelSize: 10; color: DeskTheme.muted
        }
    }
    Row {
        anchors.right: parent.right; anchors.rightMargin: 22
        y: 221; spacing: 6
        MaterialSymbol {
            text: Network.ethernet ? "lan" : root.connected ? "wifi" : "wifi_off"
            iconSize: 16
            color: root.connected ? DeskTheme.mint : DeskTheme.faint
        }
        DeskText {
            width: Math.min(implicitWidth, root.width - 170)
            text: Network.ethernet ? "Ethernet" : root.connected ? Network.networkName : "Offline"
            font.pixelSize: 10; color: DeskTheme.muted
        }
    }
}
