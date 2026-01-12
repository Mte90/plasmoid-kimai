import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami
import "kimaiapi.js" as KimaiApi

KCM.SimpleKCM {
    id: configRoot

    property alias cfg_kimaiUrl: kimaiUrlField.text
    property alias cfg_apiToken: apiTokenField.text
    property bool testingConnection: false

    Kirigami.FormLayout {
        // Kimai Server URL
        QQC2.TextField {
            id: kimaiUrlField
            Kirigami.FormData.label: i18n("Kimai Server URL (without /api):")
            placeholderText: i18n("https://your-kimai-instance.com")
        }

        // API Token
        QQC2.TextField {
            id: apiTokenField
            Kirigami.FormData.label: i18n("API Token:")
            placeholderText: i18n("Your Kimai API token")
            echoMode: TextInput.Password
        }

        // Connection test button
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing

            QQC2.Button {
                id: testConnectionButton
                text: i18n("Test Connection")
                icon.name: "network-connect"
                enabled: !testingConnection && kimaiUrlField.text && apiTokenField.text
                onClicked: {
                    testingConnection = true
                    connectionStatusLabel.text = i18n("Testing connection...")
                    connectionStatusLabel.color = Kirigami.Theme.textColor
                    connectionStatusIcon.source = "view-refresh"
                    
                    KimaiApi.testConnection(kimaiUrlField.text, apiTokenField.text, function(success, message) {
                        testingConnection = false
                        connectionStatusLabel.text = message
                        if (success) {
                            connectionStatusLabel.color = Kirigami.Theme.positiveTextColor
                            connectionStatusIcon.source = "dialog-ok"
                        } else {
                            connectionStatusLabel.color = Kirigami.Theme.negativeTextColor
                            connectionStatusIcon.source = "dialog-error"
                        }
                    })
                }
            }

            QQC2.BusyIndicator {
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                running: testingConnection
                visible: testingConnection
            }
        }

        // Connection status
        RowLayout {
            Layout.fillWidth: true
            visible: connectionStatusLabel.text !== ""

            Kirigami.Icon {
                id: connectionStatusIcon
                Layout.preferredWidth: Kirigami.Units.iconSizes.small
                Layout.preferredHeight: Kirigami.Units.iconSizes.small
                source: ""
            }

            QQC2.Label {
                id: connectionStatusLabel
                Layout.fillWidth: true
                text: ""
                wrapMode: Text.WordWrap
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
        }

        // Help text
        QQC2.Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            text: i18n("You can generate an API token in your Kimai user settings under 'API Access'.")
            wrapMode: Text.WordWrap
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
        }
    }
}
