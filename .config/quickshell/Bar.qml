import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

PanelWindow {
    id: root

    property var modelData

    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        opacity: 0.95

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 12

            // LEFT: workspace
            Text {
                text: "WS: " + Hyprland.activeWorkspace?.id
                color: "#cdd6f4"
            }

            Item { Layout.fillWidth: true }

            // CENTER: title
            Text {
                text: Hyprland.activeWindow?.title ?? "Desktop"
                color: "#a6adc8"
                elide: Text.ElideRight
            }

            Item { Layout.fillWidth: true }

            // RIGHT: clock
            Text {
                id: clock
                color: "#cdd6f4"

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: {
                        const d = new Date()
                        clock.text = Qt.formatDateTime(d, "hh:mm:ss")
                    }
                }

                Component.onCompleted: {
                    const d = new Date()
                    clock.text = Qt.formatDateTime(d, "hh:mm:ss")
                }
            }
        }
    }
}
