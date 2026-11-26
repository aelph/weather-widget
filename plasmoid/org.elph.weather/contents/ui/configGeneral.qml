import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_cityName: cityField.text
    property alias cfg_latitude: latField.text
    property alias cfg_longitude: lonField.text
    property alias cfg_updateInterval: intervalSpin.value
    property alias cfg_tempUnit: tempCombo.value
    property alias cfg_windUnit: windCombo.value
    property alias cfg_pressureUnit: pressureCombo.value
    property alias cfg_precipUnit: precipCombo.value
    property alias cfg_showHourly: hourlyCheck.checked
    property alias cfg_showDaily: dailyCheck.checked

    // Plasma передаёт странице и значения по умолчанию; без этих свойств журнал засоряется предупреждениями
    property string cfg_cityNameDefault
    property string cfg_latitudeDefault
    property string cfg_longitudeDefault
    property int cfg_updateIntervalDefault
    property string cfg_tempUnitDefault
    property string cfg_windUnitDefault
    property string cfg_pressureUnitDefault
    property string cfg_precipUnitDefault
    property bool cfg_showHourlyDefault
    property bool cfg_showDailyDefault

    // Список с выбором единицы: в настройках хранится код (value), а не номер строки
    component UnitCombo: QQC2.ComboBox {
        property string value
        textRole: "text"
        valueRole: "value"
        implicitContentWidthPolicy: QQC2.ComboBox.WidestText
        function sync() {
            const i = indexOfValue(value)
            if (i >= 0 && i !== currentIndex) currentIndex = i
        }
        onValueChanged: sync()
        Component.onCompleted: sync()
        onActivated: value = currentValue
    }

    Kirigami.FormLayout {
        QQC2.TextField {
            id: cityField
            Kirigami.FormData.label: i18n("Name:")
        }

        QQC2.TextField {
            id: latField
            Kirigami.FormData.label: i18n("Latitude:")
            placeholderText: "51.48"
            validator: RegularExpressionValidator { regularExpression: /-?\d{1,2}([.,]\d+)?/ }
        }

        QQC2.TextField {
            id: lonField
            Kirigami.FormData.label: i18n("Longitude:")
            placeholderText: "0.00"
            validator: RegularExpressionValidator { regularExpression: /-?\d{1,3}([.,]\d+)?/ }
        }

        QQC2.Label {
            text: i18n("Coordinates in decimal degrees: north latitude and east longitude are positive.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.fillWidth: true
        }

        QQC2.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: i18n("Update every, min:")
            from: 5
            to: 180
            stepSize: 5
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Popup")
        }

        QQC2.CheckBox {
            id: hourlyCheck
            Kirigami.FormData.label: i18n("Show:")
            text: i18n("24-hour forecast")
        }

        QQC2.CheckBox {
            id: dailyCheck
            text: i18n("7-day forecast")
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Units")
        }

        UnitCombo {
            id: tempCombo
            Kirigami.FormData.label: i18n("Temperature:")
            model: [
                { text: i18n("degrees Celsius, °C"), value: "c" },
                { text: i18n("degrees Fahrenheit, °F"), value: "f" }
            ]
        }

        UnitCombo {
            id: windCombo
            Kirigami.FormData.label: i18n("Wind speed:")
            model: [
                { text: i18n("metres per second, m/s"), value: "ms" },
                { text: i18n("kilometres per hour, km/h"), value: "kmh" },
                { text: i18n("miles per hour"), value: "mph" },
                { text: i18n("knots"), value: "kn" }
            ]
        }

        UnitCombo {
            id: pressureCombo
            Kirigami.FormData.label: i18n("Pressure:")
            model: [
                { text: i18n("millimetres of mercury"), value: "mmhg" },
                { text: i18n("hectopascals, hPa"), value: "hpa" },
                { text: i18n("inches of mercury"), value: "inhg" }
            ]
        }

        UnitCombo {
            id: precipCombo
            Kirigami.FormData.label: i18n("Precipitation:")
            model: [
                { text: i18n("millimetres, mm"), value: "mm" },
                { text: i18n("inches"), value: "inch" }
            ]
        }
    }
}
