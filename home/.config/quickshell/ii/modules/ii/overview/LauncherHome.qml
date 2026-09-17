pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ColumnLayout {
    id: root
    spacing: 12
    signal browseRequested()

    // Existing pins come first. Fill the remaining slots with installed daily apps.
    readonly property var apps: {
        const available = AppSearch.list;
        const ids = [...Config.options.launcher.pinnedApps, "zen", "code", "thunar", "spotify", "kitty"];
        const found = ids.map(id => available.find(app => app.id === id)).filter(Boolean);
        const unique = found.filter((app, index) => found.findIndex(other => other.id === app.id) === index);
        if (unique.length < 6) {
            for (const app of available) {
                if (!unique.some(other => other.id === app.id)) unique.push(app);
                if (unique.length >= 6) break;
            }
        }
        return unique.slice(0, 6);
    }

    function resetSelection() { grid.currentIndex = -1; }
    function navigate(step) {
        if (grid.count === 0) return;
        grid.currentIndex = Math.max(0, Math.min(grid.count - 1, grid.currentIndex + step));
    }
    function launch(app) {
        if (!app) return;
        GlobalStates.overviewOpen = false;
        if (app.runInTerminal) {
            Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(app.command.join(' '))}'`]);
        } else {
            app.execute();
        }
    }
    function activateSelected() {
        if (grid.currentIndex >= 0) root.launch(root.apps[grid.currentIndex]);
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Quick launch")
            font.pixelSize: 12
            color: Appearance.colors.colSubtext
        }
        RippleButton {
            implicitWidth: browseLabel.implicitWidth + 12
            implicitHeight: 24
            buttonRadius: 6
            onClicked: root.browseRequested()
            contentItem: StyledText {
                id: browseLabel
                text: Translation.tr("All apps") + "  →"
                font.pixelSize: 12
                color: Appearance.colors.colPrimary
            }
        }
    }

    GridView {
        id: grid
        Layout.fillWidth: true
        readonly property int columns: width >= 560 ? 6 : 3
        cellWidth: width / columns
        cellHeight: 106
        implicitHeight: Math.ceil(count / columns) * cellHeight
        interactive: false
        currentIndex: -1
        model: root.apps

        delegate: Item {
            id: appTile
            required property var modelData
            required property int index
            width: grid.cellWidth
            height: grid.cellHeight

            RippleButton {
                id: appButton
                anchors.fill: parent
                anchors.margins: 3
                readonly property bool selected: appTile.GridView.isCurrentItem || hovered || activeFocus
                buttonRadius: Appearance.rounding.normal
                colBackground: selected ? Appearance.colors.colSecondaryContainer : Appearance.m3colors.m3surfaceContainerLow
                colBackgroundHover: Appearance.colors.colSecondaryContainer
                onClicked: root.launch(appTile.modelData)
                onHoveredChanged: if (hovered) grid.currentIndex = appTile.index

                Rectangle {
                    anchors.fill: parent
                    radius: appButton.buttonRadius
                    color: "transparent"
                    border.width: 1
                    border.color: appButton.selected ? ColorUtils.transparentize(Appearance.colors.colPrimary, 0.65) : "transparent"
                }

                contentItem: ColumnLayout {
                    spacing: 10
                    IconImage {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        source: Quickshell.iconPath(appTile.modelData.icon, "application-x-executable")
                    }
                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: 3
                        Layout.rightMargin: 3
                        text: ({ "code": "VS Code", "thunar": "Thunar" })[appTile.modelData.id] ?? appTile.modelData.name
                        textFormat: Text.PlainText
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        color: appButton.selected ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurface
                    }
                }
                MaterialSymbol {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 7
                    visible: LauncherApps.isPinned(appTile.modelData.id)
                    text: "keep"
                    iconSize: 11
                    color: Appearance.colors.colSubtext
                }
                StyledToolTip { text: appTile.modelData.name }
            }
        }
    }
}
