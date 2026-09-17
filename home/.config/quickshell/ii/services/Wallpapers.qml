pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

/**
 * Provides a list of wallpapers and an "apply" action that calls the existing
 * switchwall.sh script. Pretty much a limited file browsing service.
 */
Singleton {
    id: root

    property string thumbgenScriptPath: `${FileUtils.trimFileProtocol(Directories.scriptPath)}/thumbnails/wallpaper-thumbnails.py`
    property alias directory: folderModel.folder
    readonly property string effectiveDirectory: FileUtils.trimFileProtocol(folderModel.folder.toString())
    property url defaultFolder: Qt.resolvedUrl(`${Directories.config}/wallpapers`)
    property alias folderModel: folderModel // Expose for direct binding when needed
    property string searchQuery: ""
    property string mediaFilter: "all"
    readonly property list<string> imageExtensions: ["jpg", "jpeg", "png", "webp", "avif", "bmp", "svg", "gif", "tif", "tiff"]
    readonly property list<string> videoExtensions: ["mp4", "webm", "mkv", "avi", "mov"]
    readonly property list<string> extensions: mediaFilter === "videos" ? videoExtensions : mediaFilter === "images" ? imageExtensions : [...imageExtensions, ...videoExtensions]
    property list<string> wallpapers: [] // List of absolute file paths (without file://)
    readonly property bool thumbnailGenerationRunning: thumbgenProc.running
    property real thumbnailGenerationProgress: 0

    signal changed
    signal thumbnailGenerated(directory: string)
    signal thumbnailGeneratedFile(filePath: string)

    function load() {
    } // For forcing initialization

    function openFallbackPicker(darkMode = Appearance.m3colors.darkmode) {
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", darkMode ? "dark" : "light"]);
    }

    function apply(path, darkMode = Appearance.m3colors.darkmode) {
        if (!path || path.length === 0)
            return;
        Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--mode", darkMode ? "dark" : "light", "--image", path]);
        root.changed();
    }

    Process {
        id: selectProc
        property string filePath: ""
        property bool darkMode: Appearance.m3colors.darkmode
        function select(filePath, darkMode = Appearance.m3colors.darkmode) {
            selectProc.filePath = filePath;
            selectProc.darkMode = darkMode;
            selectProc.exec(["test", "-d", FileUtils.trimFileProtocol(filePath)]);
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                setDirectory(selectProc.filePath);
                return;
            }
            root.apply(selectProc.filePath, selectProc.darkMode);
        }
    }

    function select(filePath, darkMode = Appearance.m3colors.darkmode) {
        selectProc.select(filePath, darkMode);
    }

    function randomFromCurrentFolder(darkMode = Appearance.m3colors.darkmode) {
        const candidates = [];
        for (let i = 0; i < folderModel.count; i++) {
            if (!folderModel.get(i, "fileIsDir"))
                candidates.push(folderModel.get(i, "filePath"));
        }
        if (candidates.length === 0)
            return;
        const filePath = candidates[Math.floor(Math.random() * candidates.length)];
        print("Randomly selected wallpaper:", filePath);
        root.select(filePath, darkMode);
    }

    Process {
        id: validateDirProc
        property string nicePath: ""
        function setDirectoryIfValid(path) {
            validateDirProc.nicePath = FileUtils.trimFileProtocol(path).replace(/\/+$/, "");
            if (/^\/*$/.test(validateDirProc.nicePath))
                validateDirProc.nicePath = "/";
            validateDirProc.exec(["python3", "-c", "import os, sys; p = sys.argv[1]; print('dir' if os.path.isdir(p) else 'file' if os.path.isfile(p) else 'invalid')", validateDirProc.nicePath]);
        }
        stdout: StdioCollector {
            onStreamFinished: {
                const result = text.trim();
                if (result === "dir") {
                    root.directory = Qt.resolvedUrl(validateDirProc.nicePath);
                } else if (result === "file") {
                    root.directory = Qt.resolvedUrl(FileUtils.parentDirectory(validateDirProc.nicePath));
                } else {
                    // Ignore
                }
            }
        }
    }
    function setDirectory(path) {
        validateDirProc.setDirectoryIfValid(path);
    }
    function navigateUp() {
        folderModel.navigateUp();
    }
    function navigateBack() {
        folderModel.navigateBack();
    }
    function navigateForward() {
        folderModel.navigateForward();
    }

    // Folder model
    FolderListModelWithHistory {
        id: folderModel
        folder: Qt.resolvedUrl(root.defaultFolder)
        caseSensitive: false
        nameFilters: root.extensions.map(ext => `*${root.searchQuery.trim().split(/\s+/).filter(s => s.length > 0).join("*")}*.${ext}`)
        showDirs: true
        showDotAndDotDot: false
        showOnlyReadable: true
        sortField: FolderListModel.Time
        sortReversed: false
        onCountChanged: {
            root.wallpapers = [];
            for (let i = 0; i < folderModel.count; i++) {
                const path = folderModel.get(i, "filePath") || FileUtils.trimFileProtocol(folderModel.get(i, "fileURL"));
                if (path && path.length)
                    root.wallpapers.push(path);
            }
        }
    }

    // Thumbnail generation
    function generateThumbnail(size: string) {
        if (!["normal", "large", "x-large", "xx-large"].includes(size))
            throw new Error("Invalid thumbnail size");
        thumbgenProc.directory = root.directory;
        thumbgenProc.running = false;
        thumbgenProc.command = ["python3", root.thumbgenScriptPath, "--size", size, "--directory", FileUtils.trimFileProtocol(root.directory)];
        // console.log("[Wallpapers] Updating thumbnails with command ", thumbgenProc.command.join(" "))
        root.thumbnailGenerationProgress = 0;
        thumbgenProc.running = true;
    }
    Process {
        id: thumbgenProc
        property string directory
        stdout: SplitParser {
            onRead: data => {
                // print("thumb gen proc:", data)
                let match = data.match(/PROGRESS (\d+)\/(\d+)/);
                if (match) {
                    const completed = parseInt(match[1]);
                    const total = parseInt(match[2]);
                    root.thumbnailGenerationProgress = completed / total;
                }
                match = data.match(/FILE (.+)/);
                if (match) {
                    const filePath = match[1];
                    root.thumbnailGeneratedFile(filePath);
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            // print("[Wallpapers] Thumbnail generation completed with exit code", exitCode)
            root.thumbnailGenerated(thumbgenProc.directory);
        }
    }

    IpcHandler {
        target: "wallpapers"

        function apply(path: string): void {
            root.apply(path);
        }
    }
}
