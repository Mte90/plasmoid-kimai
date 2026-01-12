import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.FormLayout {
    id: configRoot

    property alias cfg_kimaiUrl: kimaiUrlField.text
    property alias cfg_apiToken: apiTokenField.text

    // Kimai Server URL
    TextField {
        id: kimaiUrlField
        Kirigami.FormData.label: i18n("Kimai Server URL:")
        placeholderText: i18n("https://your-kimai-instance.com")
    }

    // API Token
    TextField {
        id: apiTokenField
        Kirigami.FormData.label: i18n("API Token:")
        placeholderText: i18n("Your Kimai API token")
        echoMode: TextInput.Password
    }

    // Help text
    Label {
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

    // Connection test (placeholder)
    Button {
        text: i18n("Test Connection")
        icon.name: "network-connect"
        enabled: kimaiUrlField.text && apiTokenField.text
        onClicked: {
            // TODO: Implement connection test
            console.log("Testing connection to:", kimaiUrlField.text)
        }
    }
}
