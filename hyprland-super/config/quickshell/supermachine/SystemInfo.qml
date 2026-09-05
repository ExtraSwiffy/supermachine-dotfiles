pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property int cpuPercent: 0
    property int memoryPercent: 0
    property string memoryUsage: "—"
    property string diskUsage: "—"
    property int diskPercent: 0
    property string uptime: "—"
    property string cpuName: "Detecting…"
    property string gpuName: "Detecting…"
    property string powerProfile: ShellSettings.powerProfile
    property string kernel: "—"
    property bool consoleMode: false

    property Process reader: Process {
        command: [`${Quickshell.env("HOME")}/.local/bin/supermachine-system-info`]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split("\t");
                if (fields.length < 11)
                    return;
                root.cpuPercent = Number(fields[0]);
                root.memoryPercent = Number(fields[1]);
                root.memoryUsage = fields[2];
                root.diskUsage = fields[3];
                root.diskPercent = Number(fields[4]);
                root.uptime = fields[5];
                root.cpuName = fields[6];
                root.gpuName = fields[7];
                root.powerProfile = fields[8];
                root.kernel = fields[9];
                root.consoleMode = fields[10] === "console";
            }
        }
    }

    property Timer timer: Timer {
        interval: 2500
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.reader.running)
                root.reader.running = true;
        }
    }
}
