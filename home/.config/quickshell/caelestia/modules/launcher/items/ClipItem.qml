pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.images
import qs.services
import qs.modules.launcher.services

Item {
    id: root
    required property Clipboard.Entry modelData
    required property var list
    required property int index

    readonly property bool expanded: modelData !== null && list.expandedClipId === modelData.clipId
    readonly property string kind: inspectedKind || modelData?.kind || "text"
    readonly property string kindIcon: ({ code: "code", link: "link", colour: "palette", image: "image", text: "notes" })[kind] ?? "notes"
    readonly property string kindLabel: ({ code: "Code", link: "Link", colour: "Colour", image: "Image", text: "Text" })[kind] ?? "Text"
    property string fullText
    property string inspectedKind
    property bool textLoaded: false
    property bool truncated: false
    property bool loadFailed: false

    function togglePreview(): void {
        if (!modelData)
            return;
        list.currentIndex = index;
        list.expandedClipId = expanded ? -1 : modelData.clipId;
        list.search?.forceActiveFocus();
        Qt.callLater(() => list.positionViewAtIndex(index, ListView.Contain));
    }

    onExpandedChanged: {
        if (expanded && modelData && !modelData.image && !textLoaded && !inspectProc.running) {
            inspectProc.requestId = modelData.clipId;
            inspectProc.running = true;
        }
    }

    implicitHeight: 104 + (expanded ? 228 : 0)
    anchors.left: parent?.left
    anchors.right: parent?.right

    Process {
        id: inspectProc
        property int requestId
        command: ["python3", Quickshell.shellPath("utils/scripts/cliphist-list.py"), "inspect", String(requestId)]
        stdout: StdioCollector { id: inspectedOutput }
        onExited: code => {
            if (!root.modelData || requestId !== root.modelData.clipId)
                return;
            root.loadFailed = code !== 0;
            if (code === 0) {
                try {
                    const result = JSON.parse(inspectedOutput.text);
                    root.fullText = result.text;
                    root.truncated = result.truncated;
                    root.inspectedKind = result.kind;
                    root.textLoaded = true;
                } catch (e) {
                    root.loadFailed = true;
                }
            }
        }
    }

    Item {
        id: header
        width: parent.width
        height: 104

        StateLayer {
            radius: Tokens.rounding.large
            onClicked: root.modelData.onClicked(root.list)
        }

        StyledClippingRect {
            id: thumbnail
            anchors.left: parent.left
            anchors.leftMargin: Tokens.padding.medium
            anchors.verticalCenter: parent.verticalCenter
            width: (root.modelData?.image ?? false) ? 144 : 48
            height: (root.modelData?.image ?? false) ? 80 : 48
            radius: Tokens.rounding.medium
            color: root.kind === "colour" ? (root.modelData?.colour || Colours.tPalette.m3surfaceContainerHigh) : Colours.tPalette.m3surfaceContainerHigh

            MaterialIcon {
                anchors.centerIn: parent
                text: root.kindIcon
                color: root.kind === "colour" ? Colours.on(thumbnail.color) : Colours.palette.m3primary
                fontStyle: Tokens.font.icon.large
            }

            CachingImage {
                anchors.fill: parent
                visible: (root.modelData?.image ?? false)
                path: (root.modelData?.image ?? false) ? (root.modelData?.path ?? "") : ""
                fillMode: Image.PreserveAspectFit
            }
        }

        Column {
            anchors.left: thumbnail.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: buttons.left
            anchors.rightMargin: Tokens.spacing.small
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Rectangle {
                width: badgeLabel.implicitWidth + 14
                height: badgeLabel.implicitHeight + 4
                radius: height / 2
                color: Qt.alpha(Colours.palette.m3primary, 0.14)

                StyledText {
                    id: badgeLabel
                    anchors.centerIn: parent
                    text: root.kindLabel
                    color: Colours.palette.m3primary
                    font: Tokens.font.label.small
                }
            }

            StyledText {
                width: parent.width
                text: (root.modelData?.title ?? "")
                font: root.kind === "code" ? Tokens.font.mono.small : Tokens.font.body.medium
                wrapMode: Text.WrapAnywhere
                maximumLineCount: 2
                elide: Text.ElideRight
            }

            StyledText {
                visible: (root.modelData?.image ?? false)
                width: parent.width
                text: (root.modelData?.subtitle ?? "")
                font: Tokens.font.label.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
            }
        }

        Row {
            id: buttons
            anchors.right: parent.right
            anchors.rightMargin: Tokens.padding.small
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            ActionButton {
                icon: root.expanded ? "expand_less" : "expand_more"
                hint: root.expanded ? "Collapse preview (Ctrl+Space)" : "Expand preview (Ctrl+Space)"
                onClicked: root.togglePreview()
            }

            ActionButton {
                icon: "delete"
                hint: "Delete item (Ctrl+Delete)"
                onClicked: Clipboard.remove(root.modelData.clipId)
            }
        }
    }

    StyledClippingRect {
        id: expandedPreview
        visible: root.expanded
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Tokens.padding.medium
        height: 208
        radius: Tokens.rounding.medium
        color: Colours.tPalette.m3surfaceContainerHigh

        CachingImage {
            anchors.fill: parent
            anchors.margins: Tokens.padding.small
            visible: (root.modelData?.image ?? false)
            path: (root.modelData?.image ?? false) ? (root.modelData?.path ?? "") : ""
            fillMode: Image.PreserveAspectFit
        }

        Flickable {
            id: textScroll
            visible: !(root.modelData?.image ?? false)
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            anchors.bottomMargin: root.truncated ? 30 : Tokens.padding.medium
            clip: true
            contentWidth: width
            contentHeight: previewText.height
            boundsBehavior: Flickable.StopAtBounds
            Controls.ScrollBar.vertical: Controls.ScrollBar {}

            TextEdit {
                id: previewText
                width: textScroll.width
                height: Math.max(textScroll.height, contentHeight)
                readOnly: true
                selectByMouse: true
                textFormat: TextEdit.PlainText
                wrapMode: TextEdit.WrapAnywhere
                text: root.loadFailed ? "Unable to load this item. Refresh the clipboard and try again." : root.textLoaded ? root.fullText : "Loading preview…"
                font: root.kind === "code" ? Tokens.font.mono.small : Tokens.font.body.medium
                color: Colours.palette.m3onSurface
                selectionColor: Colours.palette.m3primary
                selectedTextColor: Colours.palette.m3onPrimary
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Space && (event.modifiers & Qt.ControlModifier)) {
                        root.togglePreview();
                        event.accepted = true;
                    }
                }
            }
        }

        StyledText {
            visible: root.truncated
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 6
            text: "Preview shortened · Copy keeps the complete text"
            font: Tokens.font.label.small
            color: Colours.palette.m3outline
        }
    }

    component ActionButton: Rectangle {
        id: button
        required property string icon
        required property string hint
        signal clicked()
        width: 32
        height: 32
        radius: 16
        color: Qt.alpha(Colours.palette.m3onSurface, 0.05)

        StateLayer {
            id: hover
            radius: parent.radius
            onClicked: button.clicked()
        }

        MaterialIcon {
            anchors.centerIn: parent
            text: button.icon
            fontStyle: Tokens.font.icon.medium
            color: Colours.palette.m3onSurfaceVariant
        }

        Controls.ToolTip.visible: hover.containsMouse
        Controls.ToolTip.text: hint
        Controls.ToolTip.delay: 500
    }
}
