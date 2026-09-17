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

Rectangle {
    id: root
    property bool animateWidth: false
    property alias searchInput: searchInput
    property string searchingText: ""
    signal accepted()
    signal navigate(int step)
    signal completeRequested()
    signal deleteRequested()

    implicitWidth: 620
    implicitHeight: 64
    radius: Appearance.rounding.normal
    color: ColorUtils.mix(Appearance.m3colors.m3surfaceContainerHigh, Appearance.m3colors.m3surface, 0.7)
    border.width: 1
    border.color: ColorUtils.transparentize(searchInput.activeFocus ? Appearance.colors.colPrimary : Appearance.colors.colOutline, 0.7)

    function forceFocus() { searchInput.forceActiveFocus(); }

    enum SearchPrefixType { Action, App, Clipboard, Emojis, Math, ShellCommand, WebSearch, DefaultSearch }
    readonly property int searchPrefixType: {
        const prefix = Config.options.search.prefix;
        if (root.searchingText.startsWith(prefix.action)) return SearchBar.SearchPrefixType.Action;
        if (root.searchingText.startsWith(prefix.app)) return SearchBar.SearchPrefixType.App;
        if (root.searchingText.startsWith(prefix.clipboard)) return SearchBar.SearchPrefixType.Clipboard;
        if (root.searchingText.startsWith(prefix.emojis)) return SearchBar.SearchPrefixType.Emojis;
        if (root.searchingText.startsWith(prefix.math)) return SearchBar.SearchPrefixType.Math;
        if (root.searchingText.startsWith(prefix.shellCommand)) return SearchBar.SearchPrefixType.ShellCommand;
        if (root.searchingText.startsWith(prefix.webSearch)) return SearchBar.SearchPrefixType.WebSearch;
        return SearchBar.SearchPrefixType.DefaultSearch;
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 10
        spacing: 14

        MaterialSymbol {
            Layout.alignment: Qt.AlignVCenter
            iconSize: 26
            color: Appearance.colors.colPrimary
            text: {
                switch (root.searchPrefixType) {
                case SearchBar.SearchPrefixType.Action: return "bolt";
                case SearchBar.SearchPrefixType.App: return "apps";
                case SearchBar.SearchPrefixType.Clipboard: return "content_paste";
                case SearchBar.SearchPrefixType.Emojis: return "mood";
                case SearchBar.SearchPrefixType.Math: return "calculate";
                case SearchBar.SearchPrefixType.ShellCommand: return "terminal";
                case SearchBar.SearchPrefixType.WebSearch: return "travel_explore";
                default: return "search";
                }
            }
        }

        TextField {
            id: searchInput
            Layout.fillWidth: true
            Layout.fillHeight: true
            focus: GlobalStates.overviewOpen
            padding: 0
            color: Appearance.colors.colOnSurface
            placeholderText: Translation.tr("Search apps, commands, and more…")
            placeholderTextColor: Appearance.colors.colSubtext
            selectedTextColor: Appearance.colors.colOnPrimaryContainer
            selectionColor: Appearance.colors.colPrimaryContainer
            font.family: Appearance.font.family.main
            font.pixelSize: 18
            font.variableAxes: Appearance.font.variableAxes.main
            renderType: Text.NativeRendering
            background: Item {}
            onTextChanged: LauncherSearch.query = text
            onAccepted: root.accepted()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                    root.navigate(event.key === Qt.Key_Down ? 1 : -1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ControlModifier)) {
                    root.completeRequested();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                    root.deleteRequested();
                    event.accepted = true;
                }
            }
            Connections {
                target: LauncherSearch
                function onQueryChanged() {
                    if (searchInput.text !== LauncherSearch.query)
                        searchInput.text = LauncherSearch.query;
                }
            }
        }

        IconToolbarButton {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            buttonRadius: Appearance.rounding.small
            text: "image_search"
            onClicked: {
                GlobalStates.overviewOpen = false;
                Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "search"]);
            }
            StyledToolTip { text: Translation.tr("Google Lens") }
        }
        IconToolbarButton {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            buttonRadius: Appearance.rounding.small
            text: "music_cast"
            toggled: SongRec.running
            onClicked: SongRec.toggleRunning()
            StyledToolTip { text: Translation.tr("Recognize music") }
        }
    }
}
