pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common
import qs.services

WidgetCard {
    id: root
    implicitWidth: 300
    implicitHeight: 254
    readonly property int secondsLeft: Math.max(0, TimerService.pomodoroSecondsLeft)
    readonly property real progress: Math.max(0, Math.min(1, secondsLeft / Math.max(1, TimerService.pomodoroLapDuration)))
    readonly property string timeText: Math.floor(secondsLeft / 60).toString().padStart(2, "0") + ":" + (secondsLeft % 60).toString().padStart(2, "0")
    readonly property bool started: secondsLeft !== TimerService.pomodoroLapDuration || TimerService.pomodoroBreak

    DeskText {
        x: 22; y: 19; text: "FOCUS"
        font.family: DeskTheme.mono; font.pixelSize: 10; font.letterSpacing: 1.5
        color: DeskTheme.muted
    }
    DeskText {
        anchors.right: parent.right; anchors.rightMargin: 22; y: 20
        text: (TimerService.pomodoroCycle + 1).toString().padStart(2, "0") + " / " + TimerService.cyclesBeforeLongBreak.toString().padStart(2, "0")
        font.family: DeskTheme.mono; font.pixelSize: 9; color: DeskTheme.faint
    }
    DeskText {
        x: 19; y: 40
        text: root.timeText
        font.family: "Inter Display"
        font.pixelSize: 65
        font.weight: Font.Medium
        font.letterSpacing: -2
    }
    DeskText {
        x: 22; y: 119
        text: TimerService.pomodoroBreak ? "TAKE A BREAK" : TimerService.pomodoroRunning ? "IN SESSION" : root.started ? "PAUSED" : "READY WHEN YOU ARE"
        font.family: DeskTheme.mono
        font.pixelSize: 9
        font.letterSpacing: 1
        color: DeskTheme.muted
    }
    Rectangle {
        x: 22; y: 145; width: root.width - 44; height: 2; radius: 1
        color: DeskTheme.track
        Rectangle {
            height: parent.height; width: parent.width * root.progress; radius: 1
            color: DeskTheme.accent
        }
    }
    Row {
        x: 22; y: 163; spacing: 9
        DeskButton {
            objectName: "deskFocusToggle"
            width: root.width - 111
            height: 32
            text: TimerService.pomodoroRunning ? "Pause focus" : root.started ? "Resume focus" : "Start focus"
            symbol: TimerService.pomodoroRunning ? "pause" : "play_arrow"
            onClicked: TimerService.togglePomodoro()
        }
        DeskButton {
            objectName: "deskFocusReset"
            width: 58
            height: 32
            Accessible.name: "Reset focus timer"
            symbol: "restart_alt"
            enabled: root.started || TimerService.pomodoroRunning || TimerService.pomodoroCycle > 0
            onClicked: TimerService.resetPomodoro()
        }
    }
    Row {
        x: 22; y: 210; spacing: 8
        Repeater {
            model: [25, 50, 90]
            delegate: DeskButton {
                required property int modelData
                width: (root.width - 60) / 3
                height: 28
                text: modelData + " min"
                selected: TimerService.focusTime === modelData * 60
                enabled: !TimerService.pomodoroRunning
                onClicked: {
                    Config.options.time.pomodoro.focus = modelData * 60;
                    TimerService.resetPomodoro();
                }
            }
        }
    }
}
