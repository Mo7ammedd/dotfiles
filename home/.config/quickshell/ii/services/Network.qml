pragma Singleton
pragma ComponentBehavior: Bound

// Took many bits from https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell
import Quickshell.Io
import QtQuick
import qs.services.network

/**
 * Network service with nmcli.
 */
Singleton {
    id: root

    property bool wifi: true
    property bool ethernet: false

    property bool wifiEnabled: false
    property bool wifiScanning: false
    property bool wifiConnecting: connectProc.running
    property WifiAccessPoint wifiConnectTarget
    readonly property list<WifiAccessPoint> wifiNetworks: []
    readonly property WifiAccessPoint active: wifiNetworks.find(n => n.active) ?? null
    readonly property list<var> friendlyWifiNetworks: [...wifiNetworks].sort((a, b) => {
        if (a.active && !b.active)
            return -1;
        if (!a.active && b.active)
            return 1;
        return b.strength - a.strength;
    })
    property string wifiStatus: "disconnected"

    property string networkName: ""
    property int networkStrength
    property string materialSymbol: root.ethernet
        ? "lan"
        : (root.wifiEnabled && root.wifiStatus === "connected")
            ? (
                (root.active?.strength ?? 0) > 83 ? "signal_wifi_4_bar" :
                (root.active?.strength ?? 0) > 67 ? "network_wifi" :
                (root.active?.strength ?? 0) > 50 ? "network_wifi_3_bar" :
                (root.active?.strength ?? 0) > 33 ? "network_wifi_2_bar" :
                (root.active?.strength ?? 0) > 17 ? "network_wifi_1_bar" :
                "signal_wifi_0_bar"
            )
            : (root.wifiStatus === "connecting")
                ? "signal_wifi_statusbar_not_connected"
                : (root.wifiStatus === "disconnected")
                    ? "wifi_find"
                    : (root.wifiStatus === "disabled")
                        ? "signal_wifi_off"
                        : "signal_wifi_bad"

    // Control
    function enableWifi(enabled = true): void {
        const cmd = enabled ? "on" : "off";
        enableWifiProc.exec(["nmcli", "radio", "wifi", cmd]);
    }

    function toggleWifi(): void {
        enableWifi(!wifiEnabled);
    }

    function rescanWifi(): void {
        wifiScanning = true;
        rescanProcess.running = true;
    }

    function connectToWifiNetwork(accessPoint: WifiAccessPoint, password = ""): void {
        if (!accessPoint || root.wifiConnecting) return;
        accessPoint.askingPassword = false;
        accessPoint.connectionError = "";
        root.wifiConnectTarget = accessPoint;
        connectProc.passwordProvided = password.length > 0;
        // Let nmcli select/create the profile: its name need not match the SSID.
        connectProc.exec({
            environment: { LANG: "C", LC_ALL: "C", SSID: accessPoint.ssid, PASSWORD: password },
            command: connectProc.passwordProvided
                ? ["bash", "-c", 'exec nmcli --wait 60 device wifi connect "$SSID" password "$PASSWORD"']
                : ["nmcli", "--wait", "60", "device", "wifi", "connect", accessPoint.ssid]
        });
    }

    function disconnectWifiNetwork(): void {
        if (active) disconnectProc.exec(["nmcli", "connection", "down", active.ssid]);
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]) // From some StackExchange thread, seems to work
    }

    function changePassword(network: WifiAccessPoint, password: string, username = ""): void {
        // TODO: enterprise wifi with username
        if (!network || root.wifiConnecting) return;
        if (password.length === 0) {
            network.askingPassword = true;
            network.connectionError = Translation.tr("Enter a password.");
            return;
        }
        root.connectToWifiNetwork(network, password);
    }

    function connectionErrorMessage(message: string, exitCode: int): string {
        if (/not authorized|permission|not permitted/i.test(message))
            return Translation.tr("Permission denied. Open Details to check this connection.");
        if (/no network with SSID|no access point|ssid.not.found/i.test(message))
            return Translation.tr("This network is no longer available. Refresh the list and try again.");
        if (exitCode === 3 || /timeout|timed out/i.test(message))
            return Translation.tr("Connection timed out. Check the signal and try again.");
        if (/secrets|password|psk|authentication|802.1x|wep.key/i.test(message))
            return Translation.tr("Authentication failed. Check the password or open Details for this network.");
        return Translation.tr("Could not connect to this network. Try again or open Details to check its settings.");
    }

    Process {
        id: enableWifiProc
    }

    Process {
        id: connectProc
        property bool passwordProvided: false
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stderr: StdioCollector {
            id: connectError
        }
        onExited: (exitCode, exitStatus) => {
            const network = root.wifiConnectTarget;
            const failed = exitCode !== 0 || exitStatus !== 0;
            const message = connectError.text.trim();
            const needsPassword = /secrets|password|psk|authentication|802.1x|wep.key/i.test(message);
            if (network) {
                network.askingPassword = failed && network.isSecure && needsPassword;
                network.connectionError = failed && !(network.askingPassword && !passwordProvided)
                    ? root.connectionErrorMessage(message, exitCode) : "";
            }
            root.wifiConnectTarget = null;
            // Do not retain the submitted password after the command completes.
            environment = { LANG: "C", LC_ALL: "C" };
            root.update();
        }
    }

    Process {
        id: disconnectProc
        stdout: SplitParser {
            onRead: getNetworks.running = true
        }
    }

    Process {
        id: rescanProcess
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: {
            root.wifiScanning = false;
            root.update();
        }
    }

    // Status update
    function update() {
        updateConnectionType.startCheck();
        wifiStatusProcess.running = true
        updateNetworkName.running = true;
        updateNetworkStrength.running = true;
        getNetworks.refresh();
    }

    Process {
        id: subscriber
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    Process {
        id: updateConnectionType
        property string buffer
        property bool refreshPending: false
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE d status && nmcli -t -f CONNECTIVITY g"]
        running: true
        function startCheck() {
            if (running) {
                refreshPending = true;
                return;
            }
            buffer = "";
            updateConnectionType.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                updateConnectionType.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            const lines = updateConnectionType.buffer.trim().split('\n');
            const connectivity = lines.pop() // none, limited, full
            let hasEthernet = false;
            let hasWifi = false;
            let wifiStatus = "disconnected";
            lines.forEach(line => {
                if (line.includes("ethernet") && line.includes("connected"))
                    hasEthernet = true;
                else if (line.includes("wifi:")) {
                    if (line.includes("disconnected")) {
                        wifiStatus = "disconnected"
                    }
                    else if (line.includes("connected")) {
                        hasWifi = true;
                        wifiStatus = "connected"

                        if (connectivity === "limited") {
                            hasWifi = false;
                            wifiStatus = "limited"
                        }
                    }
                    else if (line.includes("connecting")) {
                        wifiStatus = "connecting"
                    }
                    else if (line.includes("unavailable")) {
                        wifiStatus = "disabled"
                    }
                }
            });
            root.wifiStatus = wifiStatus;
            root.ethernet = hasEthernet;
            root.wifi = hasWifi;
            if (refreshPending) {
                refreshPending = false;
                startCheck();
            }
        }
    }

    Process {
        id: updateNetworkName
        command: ["sh", "-c", "nmcli -t -f NAME c show --active | head -1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                root.networkName = data;
            }
        }
    }

    Process {
        id: updateNetworkStrength
        running: true
        command: ["sh", "-c", "nmcli -f IN-USE,SIGNAL,SSID device wifi | awk '/^\\*/{if (NR!=1) {print $2}}'"]
        stdout: SplitParser {
            onRead: data => {
                root.networkStrength = parseInt(data);
            }
        }
    }

    Process {
        id: wifiStatusProcess
        command: ["nmcli", "radio", "wifi"]
        Component.onCompleted: running = true
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    Process {
        id: getNetworks
        property bool refreshPending: false
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w", "list", "--rescan", "no"]
        function refresh(): void {
            if (running) refreshPending = true;
            else running = true;
        }
        onExited: {
            if (refreshPending) {
                refreshPending = false;
                running = true;
            }
        }
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(n => {
                    const net = n.replace(rep, PLACEHOLDER).split(":");
                    return {
                        active: net[0] === "yes",
                        strength: parseInt(net[1]),
                        frequency: parseInt(net[2]),
                        ssid: net[3]?.replace(rep2, ":") ?? "",
                        bssid: net[4]?.replace(rep2, ":") ?? "",
                        security: net[5] || ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Group networks by SSID and prioritize connected ones
                const networkMap = new Map();
                for (const network of allNetworks) {
                    const existing = networkMap.get(network.ssid);
                    if (!existing) {
                        networkMap.set(network.ssid, network);
                    } else {
                        // Prioritize active/connected networks
                        if (network.active && !existing.active) {
                            networkMap.set(network.ssid, network);
                        } else if (!network.active && !existing.active) {
                            // If both are inactive, keep the one with better signal
                            if (network.strength > existing.strength) {
                                networkMap.set(network.ssid, network);
                            }
                        }
                        // If existing is active and new is not, keep existing
                    }
                }

                const wifiNetworks = Array.from(networkMap.values());

                const rNetworks = root.wifiNetworks;

                // The list is grouped by SSID. Keep its object (and prompt/error)
                // when a scan picks another access point for the same network.
                const destroyed = rNetworks.filter(rn => rn !== root.wifiConnectTarget
                    && !rn.askingPassword && !rn.connectionError
                    && !wifiNetworks.find(n => n.ssid === rn.ssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of wifiNetworks) {
                    const match = rNetworks.find(n => n.ssid === network.ssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
    }

    Component {
        id: apComp

        WifiAccessPoint {}
    }
}
