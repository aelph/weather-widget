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
            Kirigami.FormData.label: "Название:"
        }

        QQC2.TextField {
            id: latField
            Kirigami.FormData.label: "Широта:"
            placeholderText: "51.48"
            validator: RegularExpressionValidator { regularExpression: /-?\d{1,2}([.,]\d+)?/ }
        }

        QQC2.TextField {
            id: lonField
            Kirigami.FormData.label: "Долгота:"
            placeholderText: "0.00"
            validator: RegularExpressionValidator { regularExpression: /-?\d{1,3}([.,]\d+)?/ }
        }

        QQC2.Label {
            text: "Координаты в десятичных градусах: северная широта и восточная долгота положительные."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.fillWidth: true
        }

        QQC2.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: "Обновлять каждые, мин:"
            from: 5
            to: 180
            stepSize: 5
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Раскрытый вид"
        }

        QQC2.CheckBox {
            id: hourlyCheck
            Kirigami.FormData.label: "Показывать:"
            text: "Прогноз на 24 часа"
        }

        QQC2.CheckBox {
            id: dailyCheck
            text: "Прогноз на 7 дней"
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Единицы измерения"
        }

        UnitCombo {
            id: tempCombo
            Kirigami.FormData.label: "Температура:"
            model: [
                { text: "градусы Цельсия, °C", value: "c" },
                { text: "градусы Фаренгейта, °F", value: "f" }
            ]
        }

        UnitCombo {
            id: windCombo
            Kirigami.FormData.label: "Скорость ветра:"
            model: [
                { text: "метры в секунду, м/с", value: "ms" },
                { text: "километры в час, км/ч", value: "kmh" },
                { text: "мили в час", value: "mph" },
                { text: "узлы", value: "kn" }
            ]
        }

        UnitCombo {
            id: pressureCombo
            Kirigami.FormData.label: "Давление:"
            model: [
                { text: "миллиметры ртутного столба", value: "mmhg" },
                { text: "гектопаскали, гПа", value: "hpa" },
                { text: "дюймы ртутного столба", value: "inhg" }
            ]
        }

        UnitCombo {
            id: precipCombo
            Kirigami.FormData.label: "Осадки:"
            model: [
                { text: "миллиметры, мм", value: "mm" },
                { text: "дюймы", value: "inch" }
            ]
        }
    }
}
