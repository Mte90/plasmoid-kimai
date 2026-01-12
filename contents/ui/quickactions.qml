import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.FormLayout {
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

        var xhr = new XMLHttpRequest()
        xhr.open("GET", kimaiUrl + "/api/projects?visible=3&order=name&orderBy=ASC", true)
        xhr.setRequestHeader("X-AUTH-TOKEN", apiToken)
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        availableProjects = JSON.parse(xhr.responseText)
                        updateProjectsList()
                        statusLabel.text = i18n("Loaded %1 projects", availableProjects.length)
                    } catch (e) {
                        statusLabel.text = i18n("Error parsing projects: %1", e)
                    }
                } else {
                    statusLabel.text = i18n("Error loading projects: %1", xhr.status)
                }
            }
        }
        
        xhr.send()
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

    function setSelectedProjects(projectIds) {
        var ids = projectIds.split(',')
        for (var i = 0; i < availableProjects.length; i++) {
            availableProjects[i].selected = ids.indexOf(String(availableProjects[i].id)) !== -1
        }
    }

    // Description
    Label {
        Layout.fillWidth: true
        text: i18n("Select projects to show as quick action buttons in the panel")
        wrapMode: Text.WordWrap
        font.bold: true
    }

    Label {
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.smallSpacing
        text: i18n("Quick action buttons allow you to start tracking time for a project with a single click. The buttons will appear in the plasmoid's interface.")
        wrapMode: Text.WordWrap
        font.pointSize: Kirigami.Theme.smallFont.pointSize
        opacity: 0.7
    }

    // Status label
    Label {
        id: statusLabel
        Layout.fillWidth: true
        Layout.topMargin: Kirigami.Units.largeSpacing
        text: i18n("Loading projects...")
        wrapMode: Text.WordWrap
        font.pointSize: Kirigami.Theme.smallFont.pointSize
    }

    // Projects list
    ScrollView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredHeight: 300

        ListView {
            id: projectsListView
            clip: true
            
            delegate: CheckDelegate {
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
    TextField {
        id: quickActionProjectsField
        visible: false
    }

    // Reload button
    Button {
        text: i18n("Reload Projects")
        icon.name: "view-refresh"
        onClicked: loadProjects()
    }
}
