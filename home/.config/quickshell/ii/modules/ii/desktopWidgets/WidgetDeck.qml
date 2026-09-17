import QtQuick
import qs.modules.common

Item {
    id: root
    property bool dashboard: false
    implicitWidth: 1054
    implicitHeight: 452
    readonly property real desktopScale: Math.min(1, width / 1260, height / 720)
    readonly property real insetLeft: Config.options.bar.vertical ? 102 : 54
    readonly property real insetRight: 46
    readonly property real insetTop: Config.options.bar.vertical ? 64 : 88
    readonly property real insetBottom: Config.options.bar.bottom && !Config.options.bar.vertical ? 86 : 52

    ClockWidget {
        x: root.dashboard ? (root.width - width) / 2 : root.insetLeft
        y: root.dashboard ? 0 : root.insetTop
        centered: root.dashboard
        scale: root.dashboard ? 1 : root.desktopScale
        transformOrigin: Item.TopLeft
    }
    MediaWidget {
        x: root.dashboard ? 0 : root.insetLeft
        y: root.dashboard ? 198 : root.height - height * scale - root.insetBottom
        scale: root.dashboard ? 1 : root.desktopScale
        transformOrigin: Item.TopLeft
    }
    SystemWidget {
        x: root.dashboard ? 410 : root.width - width * scale - root.insetRight
        y: root.dashboard ? 198 : root.insetTop
        scale: root.dashboard ? 1 : root.desktopScale
        transformOrigin: Item.TopLeft
    }
    FocusWidget {
        x: root.dashboard ? 754 : root.width - width * scale - root.insetRight
        y: root.dashboard ? 198 : root.height - height * scale - root.insetBottom
        scale: root.dashboard ? 1 : root.desktopScale
        transformOrigin: Item.TopLeft
    }
}
