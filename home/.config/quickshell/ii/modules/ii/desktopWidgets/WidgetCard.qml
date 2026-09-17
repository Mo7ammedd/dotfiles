import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    radius: 16
    antialiasing: true
    color: "transparent"
    // The clock's open layout: floating type with no enclosing panel.
    // A small shadow keeps the same pale type legible over a moving wallpaper.
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#11101b"
        shadowOpacity: 0.65
        shadowBlur: 0.25
        shadowVerticalOffset: 1
        shadowHorizontalOffset: 0
    }
    // Keep clicks inside a card from dismissing the surrounding dashboard.
    MouseArea { anchors.fill: parent }
}
