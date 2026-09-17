pragma Singleton

import ".."
import QtQuick
import Caelestia
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

Searcher {
    id: root

    property bool reloadPending: false
    readonly property bool busy: actionProc.running
    readonly property bool loading: listProc.running

    function reportError(): void {
        Toaster.toast("Clipboard", "Couldn't complete the clipboard action. Press Ctrl+R to refresh and try again.", "content_paste", Toast.Error);
    }

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}clipboard `.length);
    }

    function reload(): void {
        if (listProc.running)
            reloadPending = true;
        else
            listProc.running = true;
    }

    function copy(clipId: int, screenState: var): void {
        if (busy)
            return;
        actionProc.copyScreen = screenState;
        actionProc.command = ["python3", Quickshell.shellPath("utils/scripts/cliphist-list.py"), "copy", String(clipId)];
        actionProc.running = true;
    }

    function remove(clipId: int): void {
        if (busy)
            return;
        actionProc.copyScreen = null;
        actionProc.command = ["python3", Quickshell.shellPath("utils/scripts/cliphist-list.py"), "delete", String(clipId)];
        actionProc.running = true;
    }

    list: entries.instances
    key: "preview"

    Variants {
        id: entries

        model: []

        Entry {}
    }

    Process {
        id: listProc

        command: ["python3", Quickshell.shellPath("utils/scripts/cliphist-list.py")]
        stdout: StdioCollector { id: listOutput }
        onExited: code => {
            if (code === 0) {
                try {
                    entries.model = JSON.parse(listOutput.text);
                } catch (e) {
                    root.reportError();
                }
            } else {
                root.reportError();
            }
            if (root.reloadPending) {
                root.reloadPending = false;
                Qt.callLater(root.reload);
            }
        }
    }

    Process {
        id: actionProc

        property var copyScreen: null

        onExited: code => {
            if (code === 0) {
                if (copyScreen)
                    copyScreen.launcher = false;
                root.reload();
            } else {
                root.reportError();
            }
            copyScreen = null;
        }
    }

    component Entry: QtObject {
        required property var modelData
        readonly property int clipId: modelData.id
        readonly property string preview: modelData.preview
        readonly property bool image: modelData.image
        readonly property string path: modelData.path ?? ""
        readonly property string title: modelData.title ?? preview
        readonly property string subtitle: modelData.subtitle ?? ""
        readonly property string kind: modelData.kind ?? (image ? "image" : "text")
        readonly property string colour: modelData.colour ?? ""

        function onClicked(list: AppList): void {
            root.copy(clipId, list.screenState);
        }
    }
}
