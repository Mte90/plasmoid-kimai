import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "kimaiapi.js" as KimaiApi

KCM.SimpleKCM {
    id: quickActionsConfig

    property alias cfg_quickActionProjects: quickActionProjectsField.text
    property var availableProjects: []
    property var projectActivities: ({})
    property int selectedProjectIndex: -1

    Component.onCompleted: {
        loadProjects()
    }

    function loadProjects() {
        var kimaiUrl = plasmoid.configuration.kimaiUrl
        var apiToken = plasmoid.configuration.apiToken
        
        if (!kimaiUrl || !apiToken) {
            statusLabel.text = i18n("Please configure Kimai URL and API Token in General settings first")
            return
        }

        KimaiApi.loadProjects(kimaiUrl, apiToken, function(projects) {
            if (projects) {
                availableProjects = projects
                updateProjectsList()
                statusLabel.text = i18n("Loaded %1 projects. Click on a project to select activities.", availableProjects.length)
            } else {
                statusLabel.text = i18n("Error loading projects. Please check your connection settings.")
            }
        })
    }

    function updateProjectsList() {
        projectsListView.model = availableProjects
    }

    function loadActivitiesForProject(projectId, projectIndex) {
        var kimaiUrl = plasmoid.configuration.kimaiUrl
        var apiToken = plasmoid.configuration.apiToken
        
        if (!kimaiUrl || !apiToken) {
            return
        }

        statusLabel.text = i18n("Loading activities...")
        
        KimaiApi.loadActivities(kimaiUrl, apiToken, projectId, function(activities) {
            if (activities) {
                projectActivities[projectId] = activities
                selectedProjectIndex = projectIndex
                activitiesListView.model = activities
                statusLabel.text = i18n("Loaded %1 activities for project", activities.length)
            } else {
                statusLabel.text = i18n("Error loading activities")
            }
        })
    }

    function toggleProjectActivity(projectId, activityId) {
        // Validate inputs
        if (!projectId || !activityId || isNaN(projectId) || isNaN(activityId)) {
            return
        }
        
        var current = quickActionProjectsField.text ? quickActionProjectsField.text.split(';') : []
        var entry = projectId + ":" + activityId
        var index = current.indexOf(entry)
        
        if (index === -1) {
            current.push(entry)
        } else {
            current.splice(index, 1)
        }
        
        quickActionProjectsField.text = current.filter(function(e) { return e !== '' }).join(';')
    }

    function isActivitySelected(projectId, activityId) {
        // Validate inputs
        if (!projectId || !activityId || isNaN(projectId) || isNaN(activityId)) {
            return false
        }
        
        var current = quickActionProjectsField.text ? quickActionProjectsField.text.split(';') : []
        var entry = projectId + ":" + activityId
        return current.indexOf(entry) !== -1
    }

    RowLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.largeSpacing

        // Left side - Projects
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width / 2
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Projects")
                font.bold: true
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Click on a project to select its activities")
                wrapMode: Text.WordWrap
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: projectsListView
                    clip: true
                    
                    delegate: QQC2.ItemDelegate {
                        width: ListView.view.width
                        text: modelData.name
                        highlighted: index === selectedProjectIndex
                        onClicked: {
                            loadActivitiesForProject(modelData.id, index)
                        }
                    }
                }
            }

            QQC2.Button {
                text: i18n("Reload Projects")
                icon.name: "view-refresh"
                onClicked: loadProjects()
            }
        }

        Kirigami.Separator {
            Layout.fillHeight: true
        }

        // Right side - Activities
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width / 2
            spacing: Kirigami.Units.smallSpacing

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Activities")
                font.bold: true
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Select activities to show as quick action buttons")
                wrapMode: Text.WordWrap
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7
            }

            QQC2.Label {
                id: statusLabel
                Layout.fillWidth: true
                text: i18n("Loading projects...")
                wrapMode: Text.WordWrap
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }

            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: activitiesListView
                    clip: true
                    
                    delegate: QQC2.CheckDelegate {
                        width: ListView.view.width
                        text: modelData.name
                        checked: {
                            if (selectedProjectIndex >= 0 && selectedProjectIndex < availableProjects.length) {
                                var projectId = availableProjects[selectedProjectIndex].id
                                return isActivitySelected(projectId, modelData.id)
                            }
                            return false
                        }
                        onToggled: {
                            if (selectedProjectIndex >= 0 && selectedProjectIndex < availableProjects.length) {
                                var projectId = availableProjects[selectedProjectIndex].id
                                toggleProjectActivity(projectId, modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // Hidden field to store selected project:activity pairs
        QQC2.TextField {
            id: quickActionProjectsField
            visible: false
        }
    }
}
