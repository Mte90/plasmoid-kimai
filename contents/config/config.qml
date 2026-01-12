import QtQuick 2.0
import org.kde.plasma.configuration 2.0

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
