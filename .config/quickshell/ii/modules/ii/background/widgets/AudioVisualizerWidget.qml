import QtQuick
import Quickshell.Io
import qs.modules.common
import qs.modules.ii.background.widgets

AbstractBackgroundWidget {
    id: root
    configEntryName: "audioVisualizer"

    property int barCount: 64
    property real barSpacing: 4
    property real barHeight: 120
    property var values: []

    draggable: false
    implicitWidth: scaledScreenWidth
    implicitHeight: barHeight
    targetX: 0
    targetY: scaledScreenHeight - barHeight

    Timer {
        id: idleTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: root.values = []
    }

    Process {
        running: true
        command: ["sh", "-c", "cava -p ~/.config/cava/config_quickshell"]
        stdout: SplitParser {
            onRead: data => {
                idleTimer.restart()
                root.values = data.split(";").filter(s => s.length > 0).map(Number)
            }
        }
    }

    Repeater {
        model: root.barCount
        Rectangle {
            required property int index
            readonly property real slot: root.width / root.barCount
            x: index * slot
            width: slot - root.barSpacing
            radius: 2
            height: root.values.length ? Math.max(3, ((root.values[index] ?? 0) / 100) * root.barHeight) : 0
            y: root.barHeight - height
            color: Appearance.colors.colPrimary
        }
    }
}
