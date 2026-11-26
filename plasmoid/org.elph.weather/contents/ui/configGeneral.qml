import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_autoLocation: autoCheck.checked
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
    property alias cfg_trendHours: trendHoursSpin.value
    property alias cfg_trendTemp: trendTempSpin.value
    property alias cfg_trendHumidity: trendHumiditySpin.value
    property alias cfg_trendWind: trendWindSpin.value
    property alias cfg_trendGusts: trendGustsSpin.value
    property alias cfg_trendPressure: trendPressureSpin.value

    // Plasma передаёт странице и значения по умолчанию; без этих свойств журнал засоряется предупреждениями
    property bool cfg_autoLocationDefault
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
    property int cfg_trendHoursDefault
    property int cfg_trendTempDefault
    property int cfg_trendHumidityDefault
    property int cfg_trendWindDefault
    property int cfg_trendGustsDefault
    property int cfg_trendPressureDefault

    // Поле для порога с одним знаком после запятой: значение хранится в десятых долях (5 = 0,5)
    component TenthsSpin: QQC2.SpinBox {
        from: 1
        to: 200
        stepSize: 1
        editable: true
        textFromValue: (value, locale) => (value / 10).toLocaleString(locale, "f", 1)
        valueFromText: (text, locale) => Math.round(Number.fromLocaleString(locale, text) * 10)
        validator: DoubleValidator { bottom: 0.1; top: 20; decimals: 1; notation: DoubleValidator.StandardNotation }
    }

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
        QQC2.CheckBox {
            id: autoCheck
            Kirigami.FormData.label: i18n("Location:")
            text: i18n("Detect location by IP address")
        }

        QQC2.Label {
            text: i18n("The location is requested from ipwho.is (geojs.io as a fallback), which sees your IP address. With a VPN this is the location of the VPN exit. When the detection is off, the name and coordinates below are used.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.fillWidth: true
        }

        QQC2.TextField {
            id: cityField
            Kirigami.FormData.label: i18n("Name:")
            enabled: !autoCheck.checked
        }

        QQC2.TextField {
            id: latField
            enabled: !autoCheck.checked
            Kirigami.FormData.label: i18n("Latitude:")
            placeholderText: "51.48"
            validator: RegularExpressionValidator { regularExpression: /-?\d{1,2}([.,]\d+)?/ }
        }

        QQC2.TextField {
            id: lonField
            enabled: !autoCheck.checked
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

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18n("Trends")
        }

        QQC2.SpinBox {
            id: trendHoursSpin
            Kirigami.FormData.label: i18n("Compare with the forecast in, h:")
            from: 1
            to: 12
        }

        TenthsSpin {
            id: trendTempSpin
            Kirigami.FormData.label: i18n("Temperature threshold, °C:")
        }

        QQC2.SpinBox {
            id: trendHumiditySpin
            Kirigami.FormData.label: i18n("Humidity threshold, %:")
            from: 1
            to: 50
        }

        TenthsSpin {
            id: trendWindSpin
            Kirigami.FormData.label: i18n("Wind threshold, m/s:")
        }

        TenthsSpin {
            id: trendGustsSpin
            Kirigami.FormData.label: i18n("Gusts threshold, m/s:")
        }

        TenthsSpin {
            id: trendPressureSpin
            Kirigami.FormData.label: i18n("Pressure threshold, hPa:")
        }

        QQC2.Label {
            text: i18n("A change smaller than the threshold is shown as “steady”. Thresholds are always set in °C, m/s and hPa, whatever display units are chosen.")
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.fillWidth: true
        }
    }
}
