import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    id: root

    // Configuration properties
    property string kimaiUrl: plasmoid.configuration.kimaiUrl
    property string apiToken: plasmoid.configuration.apiToken
    property bool isTracking: false
    property string currentProject: ""
    property string currentActivity: ""
    property int elapsedSeconds: 0

    // Plasmoid properties
    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation
    Plasmoid.icon: isTracking ? "chronometer" : "chronometer-pause"
    Plasmoid.toolTipMainText: "Kimai Tracker"
    Plasmoid.toolTipSubText: isTracking ? 
        i18n("Tracking: %1 (%2)", currentProject, formatTime(elapsedSeconds)) : 
        i18n("Click to start tracking")

    // Timer for updating elapsed time
    Timer {
        id: trackingTimer
        interval: 1000
        running: isTracking
        repeat: true
        onTriggered: {
            elapsedSeconds++
        }
    }

    // Compact representation (icon in panel)
    Plasmoid.compactRepresentation: Item {
        Layout.minimumWidth: PlasmaCore.Units.iconSizes.small
        Layout.minimumHeight: PlasmaCore.Units.iconSizes.small

        PlasmaCore.IconItem {
            anchors.fill: parent
            source: plasmoid.icon
            active: compactMouse.containsMouse
        }

        MouseArea {
            id: compactMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: plasmoid.expanded = !plasmoid.expanded
        }
    }

    // Full representation (expanded popup)
    Plasmoid.fullRepresentation: Item {
        Layout.preferredWidth: PlasmaCore.Units.gridUnit * 20
        Layout.preferredHeight: PlasmaCore.Units.gridUnit * 25

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: PlasmaCore.Units.smallSpacing
            spacing: PlasmaCore.Units.smallSpacing

            // Header
            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 3
                text: i18n("Kimai Time Tracker")
            }

            // Connection status
            RowLayout {
                Layout.fillWidth: true

                PlasmaCore.IconItem {
                    Layout.preferredWidth: PlasmaCore.Units.iconSizes.small
                    Layout.preferredHeight: PlasmaCore.Units.iconSizes.small
                    source: kimaiUrl && apiToken ? "network-connect" : "network-disconnect"
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: kimaiUrl && apiToken ? 
                        i18n("Connected to %1", kimaiUrl) : 
                        i18n("Not configured - right-click to configure")
                    elide: Text.ElideRight
                    font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                }
            }

            PlasmaComponents3.Separator {
                Layout.fillWidth: true
            }

            // Current tracking status
            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 4
                text: i18n("Current Status")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: PlasmaCore.Units.smallSpacing

                PlasmaCore.IconItem {
                    Layout.preferredWidth: PlasmaCore.Units.iconSizes.medium
                    Layout.preferredHeight: PlasmaCore.Units.iconSizes.medium
                    source: isTracking ? "chronometer" : "chronometer-pause"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents3.Label {
                        text: isTracking ? i18n("Tracking Active") : i18n("Not Tracking")
                        font.bold: true
                    }

                    PlasmaComponents3.Label {
                        visible: isTracking
                        text: i18n("Project: %1", currentProject || i18n("None"))
                        font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                    }

                    PlasmaComponents3.Label {
                        visible: isTracking
                        text: i18n("Activity: %1", currentActivity || i18n("None"))
                        font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                    }

                    PlasmaComponents3.Label {
                        visible: isTracking
                        text: i18n("Time: %1", formatTime(elapsedSeconds))
                        font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                    }
                }
            }

            PlasmaComponents3.Separator {
                Layout.fillWidth: true
            }

            // Project selection (placeholder)
            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 4
                text: i18n("Quick Actions")
            }

            PlasmaComponents3.ComboBox {
                id: projectComboBox
                Layout.fillWidth: true
                enabled: !isTracking && kimaiUrl && apiToken
                model: [i18n("Select a project..."), i18n("Example Project 1"), i18n("Example Project 2")]
                currentIndex: 0
            }

            PlasmaComponents3.ComboBox {
                id: activityComboBox
                Layout.fillWidth: true
                enabled: !isTracking && kimaiUrl && apiToken && projectComboBox.currentIndex > 0
                model: [i18n("Select an activity..."), i18n("Development"), i18n("Meeting"), i18n("Documentation")]
                currentIndex: 0
            }

            // Control buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: PlasmaCore.Units.smallSpacing

                PlasmaComponents3.Button {
                    Layout.fillWidth: true
                    text: isTracking ? i18n("Stop Tracking") : i18n("Start Tracking")
                    icon.name: isTracking ? "media-playback-stop" : "media-playback-start"
                    enabled: kimaiUrl && apiToken && (isTracking || (projectComboBox.currentIndex > 0 && activityComboBox.currentIndex > 0))
                    onClicked: {
                        if (isTracking) {
                            stopTracking()
                        } else {
                            startTracking()
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            // Info message
            PlasmaComponents3.Label {
                Layout.fillWidth: true
                text: i18n("Note: This is a preview version. Kimai API integration is not yet implemented. Example projects/activities are shown for demonstration.")
                wrapMode: Text.WordWrap
                font.pointSize: PlasmaCore.Theme.smallestFont.pointSize
                font.italic: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // Helper functions
    function formatTime(seconds) {
        var hours = Math.floor(seconds / 3600)
        var minutes = Math.floor((seconds % 3600) / 60)
        var secs = seconds % 60
        return (hours < 10 ? "0" : "") + hours + ":" +
               (minutes < 10 ? "0" : "") + minutes + ":" +
               (secs < 10 ? "0" : "") + secs
    }

    function startTracking() {
        if (!kimaiUrl || !apiToken) {
            return
        }

        if (projectComboBox.currentIndex <= 0 || activityComboBox.currentIndex <= 0) {
            return
        }

        // TODO: Implement actual API call to Kimai
        // For now, just update local state
        isTracking = true
        currentProject = projectComboBox.currentText
        currentActivity = activityComboBox.currentText
        elapsedSeconds = 0
    }

    function stopTracking() {
        // TODO: Implement actual API call to Kimai to stop tracking
        // For now, just update local state
        isTracking = false
        currentProject = ""
        currentActivity = ""
        elapsedSeconds = 0
    }

    Component.onCompleted: {
        // Initialize the plasmoid
        console.log("Kimai Tracker plasmoid loaded")
    }
}
