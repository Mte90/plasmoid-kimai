import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "preferences-system"
        source: "config.qml"
    }
    ConfigCategory {
        name: i18n("Quick Actions")
        icon: "quickopen"
        source: "quickactions.qml"
    }
}
