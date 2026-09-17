pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    required property var screen
    property string searchingText: LauncherSearch.query
    property bool workspacesVisible: false
    readonly property bool showResults: searchingText !== "" && !workspacesVisible
    readonly property real panelWidth: Math.min(680, (screen?.width ?? 1920) - 64)
    readonly property real resultsHeight: Math.max(120, Math.min(440, (screen?.height ?? 1080) - 380))
    readonly property int typingResultLimit: 15
    readonly property var modes: [
        { name: Translation.tr("Apps"), icon: "apps", prefix: "" },
        { name: Translation.tr("Clipboard"), icon: "content_paste", prefix: Config.options.search.prefix.clipboard },
        { name: Translation.tr("Emoji"), icon: "mood", prefix: Config.options.search.prefix.emojis },
        { name: Translation.tr("Workspaces"), icon: "grid_view", prefix: "workspaces" }
    ]
    readonly property int activeMode: workspacesVisible ? 3
        : searchingText.startsWith(Config.options.search.prefix.clipboard) ? 1
        : searchingText.startsWith(Config.options.search.prefix.emojis) ? 2 : 0
    implicitWidth: panelWidth + 40
    implicitHeight: searchWidgetContent.implicitHeight + 40

    function focusFirstItem() { appResults.currentIndex = appResults.count > 0 ? 0 : -1; }
    function focusSearchInput() { searchBar.forceFocus(); }
    function disableExpandAnimation() { debounceTimer.stop(); }
    function cancelSearch() {
        workspacesVisible = false;
        setSearchingText("");
        quickLaunch.resetSelection();
    }
    function setSearchingText(text) {
        workspacesVisible = false;
        searchBar.searchInput.text = text;
        LauncherSearch.query = text;
        searchBar.searchInput.cursorPosition = text.length;
    }
    function selectMode(index) {
        if (index === 3) {
            setSearchingText("");
            workspacesVisible = true;
        } else {
            setSearchingText(root.modes[index].prefix);
        }
        focusSearchInput();
    }
    function activateSelected() {
        if (root.showResults) {
            const item = appResults.itemAtIndex(appResults.currentIndex);
            if (item) item.clicked();
        } else if (!root.workspacesVisible) {
            quickLaunch.activateSelected();
        }
    }
    function navigate(step) {
        if (!root.showResults) {
            if (!root.workspacesVisible) quickLaunch.navigate(step);
            return;
        }
        if (appResults.count === 0) return;
        appResults.currentIndex = Math.max(0, Math.min(appResults.count - 1, appResults.currentIndex + step));
        appResults.positionViewAtIndex(appResults.currentIndex, ListView.Contain);
    }
    function completeSelected() {
        const entry = appResults.currentItem?.entry;
        if (!root.showResults || !entry) return;
        setSearchingText(entry.name);
        focusSearchInput();
    }

    // Return typing to the field after clicking a result or a mode.
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) return;
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
            root.navigate(event.key === Qt.Key_Down ? 1 : -1);
            event.accepted = true;
        } else if (!searchBar.searchInput.activeFocus && event.key === Qt.Key_Backspace) {
            root.focusSearchInput();
            const field = searchBar.searchInput;
            if (field.selectionStart !== field.selectionEnd) {
                field.remove(field.selectionStart, field.selectionEnd);
            } else if (field.cursorPosition > 0) {
                const left = field.text.slice(0, field.cursorPosition);
                const length = event.modifiers & Qt.ControlModifier ? (left.match(/(\s*\S+)\s*$/)?.[0].length ?? 1) : 1;
                field.remove(field.cursorPosition - length, field.cursorPosition);
            }
            event.accepted = true;
        } else if (!searchBar.searchInput.activeFocus && event.text.length === 1
            && event.text.charCodeAt(0) >= 0x20 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            root.focusSearchInput();
            searchBar.searchInput.insert(searchBar.searchInput.cursorPosition, event.text);
            event.accepted = true;
        }
    }

    Timer {
        id: debounceTimer
        interval: 180
        onTriggered: resultModel.values = LauncherSearch.results ?? []
    }
    Connections {
        target: LauncherSearch
        function onResultsChanged() {
            resultModel.values = LauncherSearch.results.slice(0, root.typingResultLimit);
            root.focusFirstItem();
            debounceTimer.restart();
        }
        function onQueryChanged() {
            if (LauncherSearch.query !== "") root.workspacesVisible = false;
        }
    }

    StyledRectangularShadow {
        target: searchWidgetContent
        blur: 20
        spread: 0
        offset: Qt.vector2d(0, 6)
    }
    Rectangle {
        id: searchWidgetContent
        anchors.centerIn: parent
        implicitWidth: root.panelWidth
        implicitHeight: content.implicitHeight + 36
        radius: Appearance.rounding.verylarge
        color: ColorUtils.transparentize(Appearance.colors.colLayer0Base, Math.min(0.12, Appearance.backgroundTransparency))
        border.width: 1
        border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.76)

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                spacing: 8
                MaterialSymbol {
                    text: "orbit"
                    iconSize: 20
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Launcher")
                    font.pixelSize: 16
                    font.variableAxes: ({ "wght": 600 })
                    color: Appearance.colors.colOnSurface
                }
                StyledText {
                    text: "SUPER + SPACE"
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: 10
                    font.letterSpacing: 1
                    color: Appearance.colors.colSubtext
                }
            }

            SearchBar {
                id: searchBar
                Layout.fillWidth: true
                searchingText: root.searchingText
                onAccepted: root.activateSelected()
                onNavigate: step => root.navigate(step)
                onCompleteRequested: root.completeSelected()
                onDeleteRequested: {
                    if (!root.showResults) return;
                    const action = appResults.currentItem?.entry?.actions?.find(action => action.name === Translation.tr("Delete"));
                    if (action) action.execute();
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: root.modes
                    delegate: RippleButton {
                        id: modeButton
                        required property var modelData
                        required property int index
                        readonly property bool activeMode: root.activeMode === index
                        visible: index !== 3 || Config.options.overview.enable
                        Layout.fillWidth: true
                        implicitHeight: 36
                        implicitWidth: modeContent.implicitWidth + 20
                        buttonRadius: Appearance.rounding.small
                        colBackground: activeMode ? Appearance.colors.colSecondaryContainer : "transparent"
                        colBackgroundHover: activeMode ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colLayer1Hover
                        onClicked: root.selectMode(index)
                        contentItem: RowLayout {
                            id: modeContent
                            spacing: 7
                            MaterialSymbol {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignRight
                                text: modeButton.modelData.icon
                                iconSize: 17
                                color: modeButton.activeMode ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: modeButton.modelData.name
                                font.pixelSize: 12
                                color: modeButton.activeMode ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
                            }
                        }
                    }
                }
            }

            LauncherHome {
                id: quickLaunch
                Layout.fillWidth: true
                visible: !root.showResults && !root.workspacesVisible
                onBrowseRequested: {
                    root.setSearchingText(Config.options.search.prefix.app);
                    root.focusSearchInput();
                }
            }
            Loader {
                Layout.fillWidth: true
                Layout.preferredHeight: item?.implicitHeight ?? 0
                visible: root.workspacesVisible
                active: root.workspacesVisible && GlobalStates.overviewOpen
                sourceComponent: OverviewWidget {
                    screen: root.screen
                    scale: Math.min(Config.options.overview.scale,
                        (root.panelWidth - 90 - (Config.options.overview.columns - 1) * workspaceSpacing)
                        / (Math.max(1, root.screen.width) * Config.options.overview.columns))
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.showResults
                spacing: 8
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 8
                    Layout.rightMargin: 8
                    StyledText {
                        Layout.fillWidth: true
                        text: root.activeMode === 1 ? Translation.tr("Clipboard history")
                            : root.activeMode === 2 ? Translation.tr("Emoji") : Translation.tr("Results")
                        font.pixelSize: 12
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: String(appResults.count)
                        font.pixelSize: 12
                        color: Appearance.colors.colSubtext
                    }
                }
                ListView {
                    id: appResults
                    Layout.fillWidth: true
                    implicitHeight: Math.min(root.resultsHeight, contentHeight)
                    visible: count > 0
                    clip: true
                    spacing: 5
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 100
                    reuseItems: true
                    model: ScriptModel {
                        id: resultModel
                        objectProp: "key"
                    }
                    ScrollBar.vertical: ScrollBar {
                        width: 3
                        policy: ScrollBar.AsNeeded
                        contentItem: Rectangle {
                            implicitWidth: 3
                            radius: 2
                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.4)
                        }
                    }
                    delegate: SearchItem {
                        id: searchItem
                        required property var modelData
                        required property int index
                        width: appResults.width
                        entry: modelData
                        highlighted: ListView.isCurrentItem
                        query: StringUtils.cleanOnePrefix(root.searchingText, [Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch])
                        onHoveredChanged: if (hovered) appResults.currentIndex = index
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Tab) {
                                root.completeSelected();
                                event.accepted = true;
                            }
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 22
                    Layout.bottomMargin: 22
                    visible: appResults.count === 0
                    spacing: 8
                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "search_off"
                        iconSize: 32
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("No matches")
                        color: Appearance.colors.colOnSurface
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Try another name or switch a category.")
                        font.pixelSize: 12
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.45)
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                spacing: 14
                Repeater {
                    model: root.workspacesVisible ? [
                        { key: "click", label: Translation.tr("Switch") },
                        { key: "drag", label: Translation.tr("Move window") },
                        { key: "esc", label: Translation.tr("Close") }
                    ] : [
                        { key: "↑ ↓", label: Translation.tr("Navigate") },
                        { key: "↵", label: root.activeMode === 1 || root.activeMode === 2 ? Translation.tr("Copy") : Translation.tr("Open") },
                        { key: "esc", label: Translation.tr("Close") }
                    ]
                    delegate: RowLayout {
                        id: shortcut
                        required property var modelData
                        spacing: 5
                        Rectangle {
                            implicitWidth: keyLabel.implicitWidth + 10
                            implicitHeight: 21
                            radius: 5
                            color: Appearance.m3colors.m3surfaceContainerHigh
                            StyledText {
                                id: keyLabel
                                anchors.centerIn: parent
                                text: shortcut.modelData.key
                                font.pixelSize: 10
                                color: Appearance.colors.colOnSurfaceVariant
                            }
                        }
                        StyledText {
                            text: shortcut.modelData.label
                            font.pixelSize: 11
                            color: Appearance.colors.colSubtext
                        }
                    }
                }
                Item { Layout.fillWidth: true }
                StyledText {
                    text: Config.options.search.prefix.math + " " + Translation.tr("calculate")
                        + "   " + Config.options.search.prefix.action + " " + Translation.tr("actions")
                    font.pixelSize: 11
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}
