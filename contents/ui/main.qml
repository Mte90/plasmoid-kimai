import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "kimaiapi.js" as KimaiApi

PlasmoidItem {
    id: root

    // Constants
    readonly property int invalid_timesheet_id: -1

    // Configuration properties
    property string kimaiUrl: plasmoid.configuration.kimaiUrl
    property string apiToken: plasmoid.configuration.apiToken
    property string quickActionProjects: plasmoid.configuration.quickActionProjects
    property bool isTracking: false
    property string currentProject: ""
    property string currentActivity: ""
    property int elapsedSeconds: 0
    property int currentTimeSheetId: invalid_timesheet_id
    property var projects: []
    property var activities: []
    property var quickActionProjectsList: []

    // Tooltip
    toolTipMainText: "Kimai Tracker"
    toolTipSubText: {
        if (isTracking) {
            return i18n("%1 - Tracking (%2)", currentProject, formatTime(elapsedSeconds))
        } else if (quickActionProjectsList.length > 0) {
            var projectNames = []
            for (var i = 0; i < quickActionProjectsList.length; i++) {
                projectNames.push(quickActionProjectsList[i].name)
            }
            return projectNames.join(", ")
        } else {
            return i18n("Click to start tracking")
        }
    }

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

    // Timer to periodically fetch active timesheet
    Timer {
        id: checkActiveTimer
        interval: 30000 // Check every 30 seconds
        running: kimaiUrl && apiToken
        repeat: true
        onTriggered: {
            fetchActiveTimesheet()
        }
    }

    // Compact representation (icon in panel)
    compactRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.minimumHeight: Kirigami.Units.iconSizes.small

        Kirigami.Icon {
            anchors.fill: parent
            source:
                if (isTracking) {
                    return Qt.resolvedUrl("../images/stop.png")
                } else {
                    return Qt.resolvedUrl("../images/play.png")
                }
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
    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: Kirigami.Units.gridUnit * 25

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            // Header
            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 3
                text: i18n("Kimai Time Tracker")
            }

            // Connection status
            RowLayout {
                Layout.fillWidth: true

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.small
                    Layout.preferredHeight: Kirigami.Units.iconSizes.small
                    source: kimaiUrl && apiToken ? "network-connect" : "network-disconnect"
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    text: kimaiUrl && apiToken ? 
                        i18n("Connected to %1", kimaiUrl) : 
                        i18n("Not configured - right-click to configure")
                    elide: Text.ElideRight
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                }
            }

            Kirigami.Separator {
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
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.medium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.medium
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
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }

                    PlasmaComponents3.Label {
                        visible: isTracking
                        text: i18n("Activity: %1", currentActivity || i18n("None"))
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }

                    PlasmaComponents3.Label {
                        visible: isTracking
                        text: i18n("Time: %1", formatTime(elapsedSeconds))
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
            }

            // Quick Action Buttons
            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 4
                text: i18n("Quick Actions")
                visible: quickActionProjectsList.length > 0
            }

            // Quick action buttons for configured projects
            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                visible: quickActionProjectsList.length > 0

                Repeater {
                    model: quickActionProjectsList

                    PlasmaComponents3.Button {
                        text: modelData.name
                        icon.name: isTracking && currentProject === modelData.name ? "media-playback-stop" : "media-playback-start"
                        enabled: kimaiUrl && apiToken
                        highlighted: isTracking && currentProject === modelData.name
                        onClicked: {
                            if (isTracking && currentProject === modelData.name) {
                                stopTracking()
                            } else if (!isTracking) {
                                startTrackingProject(modelData.id, modelData.name)
                            }
                        }
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                visible: quickActionProjectsList.length > 0
            }

            // Manual Project selection
            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 4
                text: quickActionProjectsList.length > 0 ? i18n("Manual Selection") : i18n("Quick Actions")
            }

            PlasmaComponents3.ComboBox {
                id: projectComboBox
                Layout.fillWidth: true
                enabled: !isTracking && kimaiUrl && apiToken
                model: getProjectNames()
                currentIndex: 0
                onCurrentIndexChanged: {
                    if (currentIndex > 0) {
                        loadActivitiesForProject()
                    }
                }
            }

            PlasmaComponents3.ComboBox {
                id: activityComboBox
                Layout.fillWidth: true
                enabled: !isTracking && kimaiUrl && apiToken && projectComboBox.currentIndex > 0
                model: getActivityNames()
                currentIndex: 0
            }

            // Control buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

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

    function getProjectNames() {
        var names = [i18n("Select a project...")]
        for (var i = 0; i < projects.length; i++) {
            names.push(projects[i].name)
        }
        return names
    }

    function getActivityNames() {
        var names = [i18n("Select an activity...")]
        for (var i = 0; i < activities.length; i++) {
            names.push(activities[i].name)
        }
        return names
    }

    function resetTrackingState() {
        isTracking = false
        currentTimeSheetId = invalid_timesheet_id
        currentProject = ""
        currentActivity = ""
        elapsedSeconds = 0
    }

    function refreshApiData() {
        if (kimaiUrl && apiToken) {
            loadProjects()
            fetchActiveTimesheet()
        }
    }

    function updateQuickActionProjects() {
        quickActionProjectsList = []
        if (!quickActionProjects || !projects.length) {
            return
        }

        var selectedIds = quickActionProjects.split(',')
        for (var i = 0; i < selectedIds.length; i++) {
            var projectId = parseInt(selectedIds[i])
            if (!projectId) continue
            
            for (var j = 0; j < projects.length; j++) {
                if (projects[j].id === projectId) {
                    quickActionProjectsList.push({
                        id: projects[j].id,
                        name: projects[j].name
                    })
                    break
                }
            }
        }
    }

    function startTrackingProject(projectId, projectName) {
        if (!kimaiUrl || !apiToken || isTracking) {
            return
        }

        // Get default activity for the project
        KimaiApi.loadActivities(kimaiUrl, apiToken, projectId, function(loadedActivities) {
            if (loadedActivities && loadedActivities.length > 0) {
                var activityId = loadedActivities[0].id
                var activityName = loadedActivities[0].name
                
                KimaiApi.startTracking(kimaiUrl, apiToken, projectId, activityId, function(success, response) {
                    if (success && response) {
                        isTracking = true
                        currentTimeSheetId = response.id
                        currentProject = projectName
                        currentActivity = activityName
                        elapsedSeconds = 0
                    }
                })
            }
        })
    }

    function loadActivitiesForProjectId(projectId, callback) {
        if (!kimaiUrl || !apiToken) {
            return
        }

        KimaiApi.loadActivities(kimaiUrl, apiToken, projectId, callback)
    }

    function loadProjects() {
        if (!kimaiUrl || !apiToken) {
            return
        }

        KimaiApi.loadProjects(kimaiUrl, apiToken, function(loadedProjects) {
            if (loadedProjects) {
                projects = loadedProjects
                projectComboBox.model = getProjectNames()
                updateQuickActionProjects()
            }
        })
    }

    function loadActivitiesForProject() {
        if (!kimaiUrl || !apiToken || projectComboBox.currentIndex <= 0) {
            return
        }

        var projectIndex = projectComboBox.currentIndex - 1
        if (projectIndex < 0 || projectIndex >= projects.length) {
            return
        }

        var projectId = projects[projectIndex].id
        
        KimaiApi.loadActivities(kimaiUrl, apiToken, projectId, function(loadedActivities) {
            if (loadedActivities) {
                activities = loadedActivities
                activityComboBox.model = getActivityNames()
            }
        })
    }

    function fetchActiveTimesheet() {
        if (!kimaiUrl || !apiToken) {
            return
        }

        KimaiApi.fetchActiveTimesheet(kimaiUrl, apiToken, function(activeTimesheets) {
            if (activeTimesheets && activeTimesheets.length > 0) {
                var timesheet = activeTimesheets[0]
                
                // Only update if this is a new timesheet or we're not already tracking
                if (currentTimeSheetId !== timesheet.id) {
                    isTracking = true
                    currentTimeSheetId = timesheet.id
                    currentProject = timesheet.project ? timesheet.project.name : ""
                    currentActivity = timesheet.activity ? timesheet.activity.name : ""
                    
                    // Calculate elapsed seconds using UTC timestamps
                    var beginDate = new Date(timesheet.begin)
                    var now = new Date()
                    elapsedSeconds = Math.floor((now.getTime() - beginDate.getTime()) / 1000)
                }
            } else {
                if (isTracking && currentTimeSheetId !== invalid_timesheet_id) {
                    // Tracking stopped remotely
                    resetTrackingState()
                }
            }
        })
    }

    function startTracking() {
        if (!kimaiUrl || !apiToken) {
            return
        }

        if (projectComboBox.currentIndex <= 0 || activityComboBox.currentIndex <= 0) {
            return
        }

        var projectIndex = projectComboBox.currentIndex - 1
        var activityIndex = activityComboBox.currentIndex - 1
        
        if (projectIndex < 0 || projectIndex >= projects.length || 
            activityIndex < 0 || activityIndex >= activities.length) {
            return
        }

        var projectId = projects[projectIndex].id
        var activityId = activities[activityIndex].id
        
        KimaiApi.startTracking(kimaiUrl, apiToken, projectId, activityId, function(success, response) {
            if (success && response) {
                isTracking = true
                currentTimeSheetId = response.id
                currentProject = projectComboBox.currentText
                currentActivity = activityComboBox.currentText
                elapsedSeconds = 0
            }
        })
    }

    function stopTracking() {
        if (!kimaiUrl || !apiToken || currentTimeSheetId === invalid_timesheet_id) {
            return
        }

        KimaiApi.stopTracking(kimaiUrl, apiToken, currentTimeSheetId, function(success) {
            if (success) {
                resetTrackingState()
            }
        })
    }

    Component.onCompleted: {
        // Initialize the plasmoid
        refreshApiData()
    }

    // Reload projects when configuration changes
    onKimaiUrlChanged: {
        refreshApiData()
    }

    onApiTokenChanged: {
        refreshApiData()
    }

    onQuickActionProjectsChanged: {
        updateQuickActionProjects()
    }
}
