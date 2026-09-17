pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property ScreenState screenState
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge
    readonly property bool clipboardMode: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}clipboard `)
    readonly property bool showFavourites: !search.text.startsWith(GlobalConfig.launcher.actionPrefix) && favourites.favourites.length > 0
    readonly property real favouritesHeight: showFavourites ? favourites.implicitHeight + Tokens.spacing.small + padding : 0

    Keys.onEscapePressed: root.screenState.launcher = false

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: search.height + listWrapper.height + padding + search.anchors.bottomMargin + favouritesHeight

    FavouriteApps {
        id: favourites
        screenState: root.screenState
        visible: root.showFavourites
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: root.padding
        anchors.bottom: listWrapper.top
        anchors.bottomMargin: Tokens.spacing.small
    }

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: search.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight - search.implicitHeight - root.padding * 3 - root.favouritesHeight - (root.clipboardMode ? clipboardHelp.implicitHeight + Tokens.spacing.small : 0)
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    StyledText {
        id: clipboardHelp

        visible: root.clipboardMode
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)
        text: "Enter Copy · Ctrl+Space Preview · Ctrl+Delete Remove · Ctrl+R Refresh"
        font: Tokens.font.body.small
        color: Colours.palette.m3outline
    }

    SearchBar {
        id: search

        objectName: "launcherSearch"

        function applyInitialSearch(): void {
            if (ShellState.launcherInitialSearch) {
                text = ShellState.launcherInitialSearch;
                ShellState.launcherInitialSearch = "";
            }
        }

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding) + (root.clipboardMode ? clipboardHelp.implicitHeight + Tokens.spacing.small : 0)

        topPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)
        bottomPadding: Math.round((Tokens.padding.medium + Tokens.padding.large) / 2)

        placeholderText: Tr.tr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

        onAccepted: {
            const currentItem = list.currentList?.currentItem;
            if (currentItem) {
                if (list.showWallpapers) {
                    if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                        Wallpapers.previewColourLock = true;
                    Wallpapers.setWallpaper(currentItem.modelData.path);
                    root.screenState.launcher = false;
                } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                    if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                        currentItem.onClicked();
                    else
                        currentItem.modelData.onClicked(list.currentList);
                } else {
                    Apps.launch(currentItem.modelData);
                    root.screenState.launcher = false;
                }
            }
        }

        Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
        Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

        Keys.onEscapePressed: root.screenState.launcher = false

        Keys.onPressed: event => {
            if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}clipboard `) && (event.modifiers & Qt.ControlModifier)) {
                if (event.key === Qt.Key_Space) {
                    list.currentList?.currentItem?.togglePreview();
                } else if (event.key === Qt.Key_Delete) {
                    const entry = list.currentList?.currentItem?.modelData;
                    if (entry && entry.clipId !== undefined)
                        Clipboard.remove(entry.clipId);
                } else if (event.key === Qt.Key_R) {
                    Clipboard.reload();
                } else if (event.key === Qt.Key_N || event.key === Qt.Key_J) {
                    list.currentList?.incrementCurrentIndex();
                } else if (event.key === Qt.Key_P || event.key === Qt.Key_K) {
                    list.currentList?.decrementCurrentIndex();
                } else {
                    return;
                }
                event.accepted = true;
                return;
            }
            if (!GlobalConfig.launcher.vimKeybinds)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            } else if (event.key === Qt.Key_Tab) {
                list.currentList?.incrementCurrentIndex();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                list.currentList?.decrementCurrentIndex();
                event.accepted = true;
            }
        }

        Component.onCompleted: {
            applyInitialSearch();
            forceActiveFocus();
        }

        Connections {
            function onLauncherChanged(): void {
                if (root.screenState.launcher && ShellState.launcherInitialSearch) {
                    search.applyInitialSearch();
                } else if (!root.screenState.launcher) {
                    search.text = "";
                }
            }

            function onSessionChanged(): void {
                if (!root.screenState.session)
                    search.forceActiveFocus();
            }

            target: root.screenState
        }
    }
}
