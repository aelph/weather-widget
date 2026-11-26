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

    // Plasma передаёт странице и значения по умолчанию; без этих свойств журнал засоряется предупреждениями
    property string cfg_cityNameDefault
    property string cfg_latitudeDefault
    property string cfg_longitudeDefault
    property int cfg_updateIntervalDefault

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

        QQC2.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: "Обновлять каждые, мин:"
            from: 5
            to: 180
            stepSize: 5
        }

        QQC2.Label {
            text: "Координаты в десятичных градусах: северная широта и восточная долгота положительные."
            wrapMode: Text.WordWrap
            opacity: 0.7
            Layout.fillWidth: true
        }
    }
}
