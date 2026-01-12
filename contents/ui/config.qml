import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    id: configRoot

    property alias cfg_kimaiUrl: kimaiUrlField.text
    property alias cfg_apiToken: apiTokenField.text

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

        // Help text
        QQC2.Label {
            Layout.fillWidth: true
            Layout.topMargin: Kirigami.Units.largeSpacing
            text: i18n("You can generate an API token in your Kimai user settings under 'API Access'.")
            wrapMode: Text.WordWrap
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            opacity: 0.7
        }

        // Additional spacing
        Item {
            Kirigami.FormData.isSection: true
        }

        // Info about connection test
        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Note: Connection testing is not yet implemented. The plasmoid will attempt to connect when you configure these settings.")
            wrapMode: Text.WordWrap
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            font.italic: true
            opacity: 0.7
        }
    }
}
