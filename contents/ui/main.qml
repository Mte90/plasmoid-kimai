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
    property var quickActionActivitiesList: []
    property int currentQuickActionIndex: 0

    // Tooltip
    toolTipMainText: "Kimai Tracker"
    toolTipSubText: {
        if (isTracking) {
            return i18n("%1 - Tracking (%2)", currentProject, formatTime(elapsedSeconds))
        } else if (quickActionActivitiesList.length > 0) {
            // Ensure index is within bounds
            var index = currentQuickActionIndex % quickActionActivitiesList.length
            var nextAction = quickActionActivitiesList[index]
            if (nextAction) {
                return i18n("Click to start: %1 - %2", nextAction.projectName, nextAction.activityName)
            } else {
                return i18n("%1 quick actions configured", quickActionActivitiesList.length)
            }
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    handleCompactClick()
                } else if (mouse.button === Qt.MiddleButton) {
                    handleMiddleClick()
                } else if (mouse.button === Qt.RightButton) {
                    plasmoid.expanded = !plasmoid.expanded
                }
            }
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
                visible: quickActionActivitiesList.length > 0
            }

            // Quick action buttons for configured project-activity pairs
            Flow {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                visible: quickActionActivitiesList.length > 0

                Repeater {
                    model: quickActionActivitiesList

                    PlasmaComponents3.Button {
                        text: modelData.projectName + " - " + modelData.activityName
                        icon.name: isTracking && currentProject === modelData.projectName && currentActivity === modelData.activityName ? "media-playback-stop" : "media-playback-start"
                        enabled: kimaiUrl && apiToken
                        highlighted: isTracking && currentProject === modelData.projectName && currentActivity === modelData.activityName
                        onClicked: {
                            if (isTracking && currentProject === modelData.projectName && currentActivity === modelData.activityName) {
                                stopTracking()
                            } else if (!isTracking) {
                                startTrackingProjectActivity(modelData.projectId, modelData.projectName, modelData.activityId, modelData.activityName)
                            }
                        }
                    }
                }
            }

            Kirigami.Separator {
                Layout.fillWidth: true
                visible: quickActionActivitiesList.length > 0
            }

            // Manual Project selection
            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 4
                text: quickActionActivitiesList.length > 0 ? i18n("Manual Selection") : i18n("Quick Actions")
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
    function handleMiddleClick() {
        // Cycle through quick actions without starting them
        if (quickActionActivitiesList.length > 0 && !isTracking) {
            currentQuickActionIndex = (currentQuickActionIndex + 1) % quickActionActivitiesList.length
        }
    }

    function handleCompactClick() {
        if (isTracking) {
            // Stop current tracking
            stopTracking()
        } else {
            // Cycle through quick actions, or expand if none configured
            if (quickActionActivitiesList.length > 0 && kimaiUrl && apiToken) {
                var action = quickActionActivitiesList[currentQuickActionIndex % quickActionActivitiesList.length]
                if (action && action.projectId && action.activityId) {
                    startTrackingProjectActivity(action.projectId, action.projectName, action.activityId, action.activityName)
                    // Move to next action for next click
                    currentQuickActionIndex = (currentQuickActionIndex + 1) % quickActionActivitiesList.length
                } else {
                    plasmoid.expanded = !plasmoid.expanded
                }
            } else {
                plasmoid.expanded = !plasmoid.expanded
            }
        }
    }

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
        quickActionActivitiesList = []
        
        if (!quickActionProjects || !projects.length) {
            return
        }

        // Parse project:activity pairs separated by semicolons
        var pairs = quickActionProjects.split(';')
        var uniqueProjectIds = {}
        var targetActivities = {}
        
        // First pass: collect all unique project IDs and their target activities
        for (var i = 0; i < pairs.length; i++) {
            var pair = pairs[i].split(':')
            if (pair.length !== 2) continue
            
            var projectId = parseInt(pair[0])
            var activityId = parseInt(pair[1])
            
            if (isNaN(projectId) || isNaN(activityId)) continue
            
            uniqueProjectIds[projectId] = true
            if (!targetActivities[projectId]) {
                targetActivities[projectId] = []
            }
            targetActivities[projectId].push(activityId)
        }
        
        // Create project ID to name map for O(n) lookup
        var projectIdToName = {}
        for (var j = 0; j < projects.length; j++) {
            projectIdToName[projects[j].id] = projects[j].name
        }
        
        // Count how many projects we need to load
        var projectCount = 0
        for (var projId in uniqueProjectIds) {
            if (uniqueProjectIds.hasOwnProperty(projId)) {
                projectCount++
            }
        }
        
        if (projectCount === 0) {
            return
        }
        
        var loadedCount = 0
        var activitiesByProject = {}
        
        // Second pass: load activities for each unique project
        for (var projId in uniqueProjectIds) {
            if (uniqueProjectIds.hasOwnProperty(projId)) {
                var projectIdNum = parseInt(projId)
                var projectName = projectIdToName[projectIdNum] || ""
                
                // Load activities for this project
                (function(pid, pname, targetActIds) {
                    loadActivitiesForProjectId(pid, function(loadedActivities) {
                        var localActivities = []
                        if (loadedActivities) {
                            for (var k = 0; k < loadedActivities.length; k++) {
                                var activity = loadedActivities[k]
                                // Check if this activity is in our target list
                                if (targetActIds.indexOf(activity.id) !== -1) {
                                    localActivities.push({
                                        projectId: pid,
                                        projectName: pname,
                                        activityId: activity.id,
                                        activityName: activity.name
                                    })
                                }
                            }
                        }
                        
                        // Store this project's activities
                        activitiesByProject[pid] = localActivities
                        
                        // Increment counter and merge all results when all are loaded
                        loadedCount++
                        if (loadedCount === projectCount) {
                            var finalList = []
                            for (var p in activitiesByProject) {
                                if (activitiesByProject.hasOwnProperty(p)) {
                                    finalList = finalList.concat(activitiesByProject[p])
                                }
                            }
                            quickActionActivitiesList = finalList
                        }
                    })
                })(projectIdNum, projectName, targetActivities[projId])
            }
        }
    }

    function startTrackingProjectActivity(projectId, projectName, activityId, activityName) {
        if (!kimaiUrl || !apiToken || isTracking) {
            return
        }

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
