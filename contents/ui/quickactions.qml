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
                statusLabel.text = i18n("Loaded %1 projects", availableProjects.length)
            } else {
                statusLabel.text = i18n("Error loading projects. Please check your connection settings.")
            }
        })
    }

    function updateProjectsList() {
        projectsListView.model = availableProjects
    }

    function getSelectedProjects() {
        var selected = []
        for (var i = 0; i < availableProjects.length; i++) {
            if (availableProjects[i].selected) {
                selected.push(availableProjects[i].id)
            }
        }
        return selected
    }

    Kirigami.FormLayout {
        // Description
        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Select projects to show as quick action buttons in the panel")
            wrapMode: Text.WordWrap
            font.bold: true
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.smallSpacing
            text: i18n("Quick action buttons allow you to start tracking time for a project with a single click. The buttons will appear in the plasmoid's interface.")
            wrapMode: Text.WordWrap
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
        }

        // Status label
        QQC2.Label {
            id: statusLabel
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            text: i18n("Loading projects...")
            wrapMode: Text.WordWrap
            font.pointSize: Kirigami.Theme.smallFont.pointSize
        }

        // Projects list
        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 300

            ListView {
                id: projectsListView
                clip: true
                
                delegate: QQC2.CheckDelegate {
                    width: ListView.view.width
                    text: modelData.name
                    checked: {
                        var ids = quickActionProjectsField.text.split(',')
                        return ids.indexOf(String(modelData.id)) !== -1
                    }
                    onToggled: {
                        var ids = quickActionProjectsField.text ? quickActionProjectsField.text.split(',') : []
                        var idStr = String(modelData.id)
                        var index = ids.indexOf(idStr)
                        
                        if (checked && index === -1) {
                            ids.push(idStr)
                        } else if (!checked && index !== -1) {
                            ids.splice(index, 1)
                        }
                        
                        quickActionProjectsField.text = ids.filter(function(id) { return id !== '' }).join(',')
                    }
                }
            }
        }

        // Hidden field to store selected project IDs
        QQC2.TextField {
            id: quickActionProjectsField
            visible: false
        }

        // Reload button
        QQC2.Button {
            text: i18n("Reload Projects")
            icon.name: "view-refresh"
            onClicked: loadProjects()
        }
    }
}
