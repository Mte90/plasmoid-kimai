import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

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
    toolTipSubText: isTracking ? 
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
        loadActivitiesForProjectId(projectId, function(loadedActivities) {
            if (loadedActivities && loadedActivities.length > 0) {
                var activityId = loadedActivities[0].id
                var activityName = loadedActivities[0].name
                
                var xhr = new XMLHttpRequest()
                xhr.open("POST", kimaiUrl + "/api/timesheets", true)
                xhr.setRequestHeader("Authorization", "Bearer " + apiToken)
                xhr.setRequestHeader("Content-Type", "application/json")
                
                var data = {
                    begin: new Date().toISOString(),
                    project: projectId,
                    activity: activityId
                }
                
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200 || xhr.status === 201) {
                            try {
                                var response = JSON.parse(xhr.responseText)
                                isTracking = true
                                currentTimeSheetId = response.id
                                currentProject = projectName
                                currentActivity = activityName
                                elapsedSeconds = 0
                            } catch (e) {
                                console.error("Failed to parse start tracking response:", e)
                            }
                        } else {
                            console.error("Failed to start tracking:", xhr.status, xhr.statusText)
                        }
                    }
                }
                
                xhr.send(JSON.stringify(data))
            }
        })
    }

    function loadActivitiesForProjectId(projectId, callback) {
        if (!kimaiUrl || !apiToken) {
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.open("GET", kimaiUrl + "/api/activities?project=" + projectId + "&visible=3&order=name&orderBy=ASC", true)
        xhr.setRequestHeader("Authorization", "Bearer " + apiToken)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var loadedActivities = JSON.parse(xhr.responseText)
                        if (callback) {
                            callback(loadedActivities)
                        }
                    } catch (e) {
                        console.error("Failed to parse activities:", e)
                        if (callback) {
                            callback(null)
                        }
                    }
                } else {
                    console.error("Failed to load activities:", xhr.status, xhr.statusText)
                    if (callback) {
                        callback(null)
                    }
                }
            }
        }
        
        xhr.send()
    }

    function loadProjects() {
        if (!kimaiUrl || !apiToken) {
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.open("GET", kimaiUrl + "/api/projects?visible=3&order=name&orderBy=ASC", true)
        xhr.setRequestHeader("Authorization", "Bearer " + apiToken)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        projects = JSON.parse(xhr.responseText)
                        projectComboBox.model = getProjectNames()
                        updateQuickActionProjects()
                    } catch (e) {
                        console.error("Failed to parse projects:", e)
                    }
                } else {
                    console.error("Failed to load projects:", xhr.status, xhr.statusText)
                }
            }
        }
        
        xhr.send()
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
        
        var xhr = new XMLHttpRequest()
        xhr.open("GET", kimaiUrl + "/api/activities?project=" + projectId + "&visible=3&order=name&orderBy=ASC", true)
        xhr.setRequestHeader("Authorization", "Bearer " + apiToken)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        activities = JSON.parse(xhr.responseText)
                        activityComboBox.model = getActivityNames()
                    } catch (e) {
                        console.error("Failed to parse activities:", e)
                    }
                } else {
                    console.error("Failed to load activities:", xhr.status, xhr.statusText)
                }
            }
        }
        
        xhr.send()
    }

    function fetchActiveTimesheet() {
        if (!kimaiUrl || !apiToken) {
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.open("GET", kimaiUrl + "/api/timesheets/active", true)
        xhr.setRequestHeader("Authorization", "Bearer " + apiToken)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var activeTimesheets = JSON.parse(xhr.responseText)
                        if (activeTimesheets.length > 0) {
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
                    } catch (e) {
                        console.error("Failed to parse active timesheet:", e)
                    }
                }
            }
        }
        
        xhr.send()
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
        
        var xhr = new XMLHttpRequest()
        xhr.open("POST", kimaiUrl + "/api/timesheets", true)
        xhr.setRequestHeader("Authorization", "Bearer " + apiToken)
        xhr.setRequestHeader("Content-Type", "application/json")
        
        var data = {
            begin: new Date().toISOString(),
            project: projectId,
            activity: activityId
        }
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 201) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        isTracking = true
                        currentTimeSheetId = response.id
                        currentProject = projectComboBox.currentText
                        currentActivity = activityComboBox.currentText
                        elapsedSeconds = 0
                    } catch (e) {
                        console.error("Failed to parse start tracking response:", e)
                    }
                } else {
                    console.error("Failed to start tracking:", xhr.status, xhr.statusText)
                }
            }
        }
        
        xhr.send(JSON.stringify(data))
    }

    function stopTracking() {
        if (!kimaiUrl || !apiToken || currentTimeSheetId === invalid_timesheet_id) {
            return
        }

        var xhr = new XMLHttpRequest()
        xhr.open("PATCH", kimaiUrl + "/api/timesheets/" + currentTimeSheetId + "/stop", true)
        xhr.setRequestHeader("Authorization", "Bearer " + apiToken)
        xhr.setRequestHeader("Content-Type", "application/json")
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    resetTrackingState()
                } else {
                    console.error("Failed to stop tracking:", xhr.status, xhr.statusText)
                }
            }
        }
        
        xhr.send()
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
