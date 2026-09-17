import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell

MouseArea {
    id: root
    property bool monitorIsFocused: true
    property bool useDarkMode: Appearance.m3colors.darkmode
    property bool editingDirectory: false
    readonly property int columns: Math.max(1, Math.min(3, Math.floor(grid.width / 300)))
    readonly property color accent: ColorUtils.colorWithLightness(Appearance.colors.colPrimary, 0.76)
    readonly property color panelColor: ColorUtils.mix("#12151b", accent, 0.985)
    readonly property color raisedColor: ColorUtils.mix("#1c2028", accent, 0.975)
    readonly property color lineColor: "#2c3039"
    readonly property color textColor: "#eef0f6"
    readonly property color mutedColor: "#989fab"
    readonly property string thumbnailSizeName: Images.thumbnailSizeNameForDimensions(Math.ceil(Math.max(1, grid.cellWidth - 24) * (QsWindow.window?.devicePixelRatio ?? 1)), Math.ceil(Math.max(1, grid.cellWidth - 24) * 9 / 16 * (QsWindow.window?.devicePixelRatio ?? 1)))
    readonly property string currentPath: Config.options.background.wallpaperPath
    readonly property bool currentIsVideo: Wallpapers.videoExtensions.includes(currentPath.split(".").pop().toLowerCase())
    readonly property string currentName: currentPath.split("/").pop().replace(/\.[^.]+$/, "").replace(/[_-]+/g, " ")
    readonly property string displayDirectory: Wallpapers.effectiveDirectory === FileUtils.trimFileProtocol(Wallpapers.defaultFolder) ? Translation.tr("Wallpaper collection") : Wallpapers.effectiveDirectory.replace(Directories.home, "~")

    implicitWidth: 1380
    implicitHeight: 880
    acceptedButtons: Qt.BackButton | Qt.ForwardButton
    onPressed: event => {
        if (event.button === Qt.BackButton)
            Wallpapers.navigateBack();
        else if (event.button === Qt.ForwardButton)
            Wallpapers.navigateForward();
    }

    function updateThumbnails() {
        if (grid.width > 0)
            thumbnailTimer.restart();
    }
    function focusCurrentWallpaper() {
        if (Wallpapers.folderModel.status !== FolderListModel.Ready || grid.width <= 0 || grid.height <= 0)
            return;

        const wallpaperPath = FileUtils.trimFileProtocol(root.currentPath);
        let selectedIndex = grid.count > 0 ? 0 : -1;
        for (let i = 0; i < grid.count; i++) {
            if (Wallpapers.folderModel.get(i, "filePath") === wallpaperPath) {
                selectedIndex = i;
                break;
            }
        }
        grid.currentIndex = selectedIndex;
        // Apply pending model/layout changes before scrolling to the selection.
        grid.forceLayout();
        if (selectedIndex >= 0)
            grid.positionViewAtIndex(selectedIndex, GridView.Center);
        else
            grid.positionViewAtBeginning();
    }
    function openDirectory(path) {
        filterField.clear();
        root.editingDirectory = false;
        Wallpapers.setDirectory(path.replace(/^~(?=\/|$)/, Directories.home));
    }
    function editDirectory() {
        root.editingDirectory = true;
        addressField.text = Wallpapers.effectiveDirectory;
        addressField.forceActiveFocus();
        addressField.selectAll();
    }
    function handleFilePasting(event) {
        const entry = Cliphist.entries[0] ?? "";
        if (/^\d+\tfile:\/\//.test(entry)) {
            root.openDirectory(FileUtils.trimFileProtocol(decodeURIComponent(StringUtils.cleanCliphistEntry(entry))));
            event.accepted = true;
        } else
            event.accepted = false;
    }
    function selectWallpaperPath(filePath) {
        if (!filePath)
            return;
        Wallpapers.select(filePath, root.useDarkMode);
        filterField.clear();
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
            root.handleFilePasting(event);
            return;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_L) {
            root.editDirectory();
        } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Up) {
            Wallpapers.navigateUp();
        } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Left) {
            Wallpapers.navigateBack();
        } else if ((event.modifiers & Qt.AltModifier) && event.key === Qt.Key_Right) {
            Wallpapers.navigateForward();
        } else if (event.key === Qt.Key_Left) {
            grid.moveSelection(-1);
        } else if (event.key === Qt.Key_Right) {
            grid.moveSelection(1);
        } else if (event.key === Qt.Key_Up) {
            grid.moveSelection(-root.columns);
        } else if (event.key === Qt.Key_Down) {
            grid.moveSelection(root.columns);
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            grid.activateCurrent();
        } else if (event.key === Qt.Key_Slash) {
            filterField.forceActiveFocus();
        } else if (event.key === Qt.Key_Backspace) {
            filterField.text = filterField.text.slice(0, -1);
            filterField.forceActiveFocus();
        } else if (event.text.length > 0 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
            filterField.text += event.text;
            filterField.cursorPosition = filterField.text.length;
            filterField.forceActiveFocus();
        } else {
            event.accepted = false;
            return;
        }
        event.accepted = true;
    }

    component PickerButton: Button {
        id: button
        property string iconName: ""
        property string hint: text
        property bool selected: false
        property bool quiet: false
        implicitHeight: 38
        implicitWidth: contentItem.implicitWidth + 24
        padding: 10
        horizontalPadding: 12
        focusPolicy: Qt.TabFocus
        opacity: enabled ? 1 : 0.35
        background: Rectangle {
            radius: 10
            color: button.selected ? ColorUtils.mix(root.raisedColor, root.accent, 0.86) : button.hovered || button.down ? "#292e38" : button.quiet ? "transparent" : root.raisedColor
            border.width: 1
            border.color: button.activeFocus ? root.accent : button.selected ? ColorUtils.applyAlpha(root.accent, 0.3) : button.quiet ? "transparent" : root.lineColor
            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
        contentItem: RowLayout {
            spacing: 7
            MaterialSymbol {
                visible: button.iconName.length > 0
                text: button.iconName
                iconSize: 18
                color: button.selected ? root.accent : root.mutedColor
            }
            StyledText {
                visible: button.text.length > 0
                Layout.fillWidth: true
                text: button.text
                color: button.selected ? root.accent : root.textColor
                font.pixelSize: 12
                font.weight: Font.Medium
                elide: Text.ElideMiddle
            }
        }
        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }
        ToolTip.visible: hovered && hint.length > 0
        ToolTip.text: hint
        ToolTip.delay: 700
        Accessible.name: text || hint
    }

    Timer {
        id: thumbnailTimer
        interval: 120
        onTriggered: Wallpapers.generateThumbnail(root.thumbnailSizeName)
    }
    onThumbnailSizeNameChanged: root.updateThumbnails()
    StyledRectangularShadow {
        target: panel
    }

    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.margins: 12
        color: root.panelColor
        radius: 22
        border.width: 1
        border.color: root.lineColor

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 24

            ColumnLayout {
                id: sidebar
                visible: root.width >= 980
                Layout.preferredWidth: 190
                Layout.maximumWidth: 190
                Layout.fillHeight: true
                spacing: 10
                RowLayout {
                    Layout.topMargin: 6
                    Layout.bottomMargin: 22
                    spacing: 10
                    Rectangle {
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: 12
                        color: ColorUtils.applyAlpha(root.accent, 0.12)
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: "wallpaper"
                            iconSize: 22
                            color: root.accent
                        }
                    }
                    ColumnLayout {
                        spacing: 2
                        StyledText {
                            text: Translation.tr("Your space")
                            color: root.textColor
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            text: Translation.tr("Wallpaper library")
                            color: root.mutedColor
                            font.pixelSize: 11
                        }
                    }
                }
                StyledText {
                    Layout.leftMargin: 12
                    Layout.bottomMargin: 4
                    text: Translation.tr("COLLECTIONS")
                    color: root.mutedColor
                    font.pixelSize: 10
                    font.letterSpacing: 1.5
                    font.weight: Font.Medium
                }
                Repeater {
                    model: [
                        {
                            name: Translation.tr("All wallpapers"),
                            symbol: "grid_view",
                            path: FileUtils.trimFileProtocol(Wallpapers.defaultFolder)
                        },
                        {
                            name: Translation.tr("Video wallpapers"),
                            symbol: "slow_motion_video",
                            path: `${Directories.videos}/Wallpapers`
                        },
                        {
                            name: Translation.tr("Pictures"),
                            symbol: "image",
                            path: Directories.pictures
                        },
                        {
                            name: Translation.tr("Downloads"),
                            symbol: "download",
                            path: Directories.downloads
                        },
                        {
                            name: Translation.tr("Home"),
                            symbol: "home",
                            path: Directories.home
                        }
                    ]
                    delegate: PickerButton {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 42
                        text: modelData.name
                        iconName: modelData.symbol
                        hint: modelData.path
                        quiet: true
                        selected: Wallpapers.effectiveDirectory === modelData.path
                        onClicked: {
                            Wallpapers.mediaFilter = "all";
                            root.openDirectory(modelData.path);
                        }
                    }
                }
                Item {
                    Layout.fillHeight: true
                }
                StyledText {
                    Layout.leftMargin: 2
                    text: Translation.tr("ON YOUR DESKTOP")
                    color: root.mutedColor
                    font.pixelSize: 10
                    font.letterSpacing: 1.2
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: currentPreviewColumn.implicitHeight + 16
                    radius: 13
                    color: root.raisedColor
                    border.color: root.lineColor
                    border.width: 1
                    ColumnLayout {
                        id: currentPreviewColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        spacing: 8
                        Image {
                            Layout.fillWidth: true
                            Layout.preferredHeight: width * 9 / 16
                            source: root.currentIsVideo ? Config.options.background.thumbnailPath : root.currentPath
                            sourceSize.width: 384
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            clip: true
                        }
                        RowLayout {
                            spacing: 6
                            Rectangle {
                                implicitWidth: 5
                                implicitHeight: 5
                                radius: 3
                                color: root.accent
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: root.currentName || Translation.tr("No wallpaper selected")
                                color: root.textColor
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
                PickerButton {
                    Layout.fillWidth: true
                    quiet: true
                    iconName: "folder_open"
                    text: Translation.tr("Open its folder")
                    enabled: root.currentPath.length > 0
                    onClicked: {
                        Wallpapers.mediaFilter = "all";
                        root.openDirectory(FileUtils.parentDirectory(root.currentPath));
                    }
                }
            }

            Rectangle {
                visible: sidebar.visible
                Layout.fillHeight: true
                implicitWidth: 1
                color: root.lineColor
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        StyledText {
                            text: Translation.tr("Wallpapers")
                            color: root.textColor
                            font.pixelSize: 28
                            font.weight: Font.DemiBold
                        }
                        StyledText {
                            text: Translation.tr("Images and video wallpapers")
                            color: root.mutedColor
                            font.pixelSize: 12
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    PickerButton {
                        iconName: "open_in_new"
                        hint: Translation.tr("Open system file picker")
                        onClicked: {
                            Wallpapers.openFallbackPicker(root.useDarkMode);
                            GlobalStates.wallpaperSelectorOpen = false;
                        }
                    }
                    PickerButton {
                        iconName: "close"
                        hint: Translation.tr("Close · Esc")
                        quiet: true
                        onClicked: GlobalStates.wallpaperSelectorOpen = false
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    PickerButton {
                        iconName: "arrow_back"
                        hint: Translation.tr("Back · Alt+Left")
                        enabled: Wallpapers.folderModel.currentFolderHistoryIndex > 0
                        onClicked: Wallpapers.navigateBack()
                    }
                    PickerButton {
                        iconName: "arrow_upward"
                        hint: Translation.tr("Parent folder · Alt+Up")
                        enabled: Wallpapers.effectiveDirectory !== "/"
                        onClicked: Wallpapers.navigateUp()
                    }
                    PickerButton {
                        visible: !root.editingDirectory
                        Layout.fillWidth: true
                        iconName: "folder_open"
                        text: root.displayDirectory
                        hint: Translation.tr("Edit folder path · Ctrl+L")
                        onClicked: root.editDirectory()
                    }
                    TextField {
                        id: addressField
                        visible: root.editingDirectory
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        padding: 10
                        color: root.textColor
                        selectionColor: root.accent
                        selectedTextColor: root.panelColor
                        font.family: Appearance.font.family.main
                        font.pixelSize: 12
                        background: Rectangle {
                            radius: 10
                            color: root.raisedColor
                            border.width: 1
                            border.color: root.accent
                        }
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.openDirectory(text);
                                grid.forceActiveFocus();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                root.editingDirectory = false;
                                grid.forceActiveFocus();
                                event.accepted = true;
                            } else event.accepted = false;
                        }
                    }
                }
                TextField {
                    id: filterField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    leftPadding: 42
                    rightPadding: 42
                    color: root.textColor
                    placeholderText: Translation.tr("Search wallpapers")
                    placeholderTextColor: root.mutedColor
                    selectionColor: root.accent
                    selectedTextColor: root.panelColor
                    font.family: Appearance.font.family.main
                    font.pixelSize: 13
                    selectByMouse: true
                    background: Rectangle {
                        color: root.raisedColor
                        radius: 11
                        border.width: 1
                        border.color: filterField.activeFocus ? ColorUtils.applyAlpha(root.accent, 0.65) : root.lineColor
                    }
                    MaterialSymbol {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "search"
                        iconSize: 20
                        color: root.mutedColor
                    }
                    PickerButton {
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        visible: filterField.text.length > 0
                        implicitHeight: 34
                        iconName: "close"
                        hint: Translation.tr("Clear search")
                        quiet: true
                        onClicked: filterField.clear()
                    }
                    onTextChanged: Wallpapers.searchQuery = text
                    Keys.onPressed: event => {
                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) {
                            root.handleFilePasting(event);
                            return;
                        }
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                            grid.forceActiveFocus();
                            if (event.key === Qt.Key_Up)
                                grid.moveSelection(-root.columns);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            grid.activateCurrent();
                            event.accepted = true;
                        } else
                            event.accepted = false;
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Repeater {
                        model: [
                            {
                                label: Translation.tr("All"),
                                value: "all",
                                symbol: "grid_view"
                            },
                            {
                                label: Translation.tr("Images"),
                                value: "images",
                                symbol: "image"
                            },
                            {
                                label: Translation.tr("Videos"),
                                value: "videos",
                                symbol: "videocam"
                            }
                        ]
                        delegate: PickerButton {
                            required property var modelData
                            text: modelData.label
                            iconName: modelData.symbol
                            selected: Wallpapers.mediaFilter === modelData.value
                            quiet: true
                            implicitHeight: 34
                            onClicked: Wallpapers.mediaFilter = modelData.value
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    StyledText {
                        text: grid.count + " " + Translation.tr(grid.count === 1 ? "item" : "items")
                        color: root.mutedColor
                        font.pixelSize: 11
                    }
                }
                Item {
                    id: gallery
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    GridView {
                        id: grid
                        anchors.fill: parent
                        anchors.rightMargin: 8
                        cellWidth: width / root.columns
                        cellHeight: (cellWidth - 24) * 9 / 16 + 62
                        model: Wallpapers.folderModel
                        currentIndex: count > 0 ? 0 : -1
                        interactive: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        cacheBuffer: cellHeight
                        ScrollBar.vertical: ScrollBar {
                            width: 4
                            policy: ScrollBar.AsNeeded
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: ColorUtils.applyAlpha(root.accent, 0.45)
                            }
                        }
                        onWidthChanged: {
                            root.updateThumbnails();
                            Qt.callLater(root.focusCurrentWallpaper);
                        }
                        onHeightChanged: Qt.callLater(root.focusCurrentWallpaper)
                        onCountChanged: Qt.callLater(root.focusCurrentWallpaper)
                        function moveSelection(delta) {
                            if (count === 0)
                                return;
                            currentIndex = Math.max(0, Math.min(count - 1, currentIndex + delta));
                            positionViewAtIndex(currentIndex, GridView.Contain);
                        }
                        function activateCurrent() {
                            if (currentIndex >= 0 && currentIndex < count)
                                root.selectWallpaperPath(model.get(currentIndex, "filePath"));
                        }
                        delegate: WallpaperDirectoryItem {
                            required property var modelData
                            required property int index
                            fileModelData: modelData
                            width: grid.cellWidth
                            height: grid.cellHeight
                            selected: index === grid.currentIndex
                            isCurrent: fileModelData.filePath === root.currentPath
                            accentColor: root.accent
                            thumbnailSizeName: root.thumbnailSizeName
                            onEntered: grid.currentIndex = index
                            onActivated: root.selectWallpaperPath(fileModelData.filePath)
                        }
                    }
                    ColumnLayout {
                        anchors.centerIn: parent
                        visible: grid.count === 0
                        width: Math.min(360, parent.width - 32)
                        spacing: 12
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: filterField.text.length > 0 ? "search_off" : "perm_media"
                            iconSize: 42
                            color: root.mutedColor
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: filterField.text.length > 0 ? Translation.tr("No matching wallpapers") : Translation.tr("Nothing here yet")
                            color: root.textColor
                            font.pixelSize: 17
                            font.weight: Font.Medium
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Try another search, media type, or folder.")
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            color: root.mutedColor
                            font.pixelSize: 12
                        }
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        height: 2
                        width: parent.width * Wallpapers.thumbnailGenerationProgress
                        visible: Wallpapers.thumbnailGenerationRunning
                        color: root.accent
                        Behavior on width {
                            NumberAnimation {
                                duration: 100
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: root.lineColor
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Click to apply   ·   ↑ ↓ ← → Browse   ·   Enter Select   ·   / Search")
                        color: root.mutedColor
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                    PickerButton {
                        iconName: root.useDarkMode ? "dark_mode" : "light_mode"
                        text: root.useDarkMode ? Translation.tr("Dark") : Translation.tr("Light")
                        hint: Translation.tr("Colour mode to use when applying a wallpaper")
                        onClicked: root.useDarkMode = !root.useDarkMode
                    }
                    PickerButton {
                        iconName: "shuffle"
                        text: Translation.tr("Shuffle")
                        hint: Translation.tr("Apply a random wallpaper from this folder")
                        enabled: grid.count > 0
                        onClicked: Wallpapers.randomFromCurrentFolder(root.useDarkMode)
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        Wallpapers.searchQuery = "";
        Wallpapers.mediaFilter = "all";
        if (root.currentPath.length > 0)
            Wallpapers.setDirectory(FileUtils.parentDirectory(root.currentPath));
        Qt.callLater(root.focusCurrentWallpaper);
        root.updateThumbnails();
        if (root.monitorIsFocused)
            filterField.forceActiveFocus();
    }
    Connections {
        target: Wallpapers
        function onDirectoryChanged() {
            root.updateThumbnails();
            Qt.callLater(root.focusCurrentWallpaper);
        }
        function onChanged() {
            GlobalStates.wallpaperSelectorOpen = false;
        }
    }
    Connections {
        target: Wallpapers.folderModel
        function onStatusChanged() {
            Qt.callLater(root.focusCurrentWallpaper);
        }
    }
}
