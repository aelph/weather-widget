import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "weather.js" as Weather

PlasmoidItem {
    id: root

    readonly property string cityName: Plasmoid.configuration.cityName
    readonly property string latitude: Plasmoid.configuration.latitude.replace(",", ".")
    readonly property string longitude: Plasmoid.configuration.longitude.replace(",", ".")
    readonly property int updateMs: Math.max(5, Plasmoid.configuration.updateInterval) * 60000

    property var weather: null
    property string errorText: ""
    property bool loading: false
    property double fetchedAt: 0
    property double attemptedAt: 0
    property var request: null

    // Данные старше двух часов считаются устаревшими: значение на панели бледнеет
    property bool stale: false

    toolTipMainText: cityName
    toolTipSubText: {
        if (!weather) return errorText !== "" ? errorText : "Загрузка…"
        let s = weather.temp + ", " + weather.text.toLowerCase() + "\nОщущается " + weather.feels + ", ветер " + weather.wind
        if (errorText !== "") s += "\n" + errorText
        return s
    }

    function refresh() {
        if (loading) return
        if (isNaN(parseFloat(latitude)) || isNaN(parseFloat(longitude))) {
            errorText = "Не заданы координаты места"
            return
        }
        loading = true
        attemptedAt = Date.now()
        const xhr = new XMLHttpRequest()
        request = xhr
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || request !== xhr) return
            watchdog.stop()
            request = null
            loading = false
            if (xhr.status !== 200) {
                errorText = xhr.status === 0 ? "Нет связи с Open-Meteo" : "Open-Meteo ответил кодом " + xhr.status
                return
            }
            try {
                weather = Weather.parse(xhr.responseText)
                fetchedAt = Date.now()
                stale = false
                errorText = ""
            } catch (e) {
                errorText = "Не удалось разобрать ответ Open-Meteo: " + e.message
            }
        }
        xhr.open("GET", Weather.url(latitude, longitude))
        xhr.send()
        watchdog.restart()
    }

    // Запрос без ответа обрывается, иначе признак загрузки навсегда заблокирует обновление
    Timer {
        id: watchdog
        interval: 30000
        onTriggered: {
            const xhr = root.request
            root.request = null
            root.loading = false
            root.errorText = "Open-Meteo не ответил за 30 секунд"
            if (xhr) xhr.abort()
        }
    }

    // Ежеминутная сверка с часами вместо одного длинного таймера: после сна и после сбоя обновление не ждёт целого интервала
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = Date.now()
            root.stale = root.fetchedAt > 0 && now - root.fetchedAt > 7200000
            const wait = root.errorText !== "" ? 60000 : root.updateMs
            if (now - root.attemptedAt >= wait) root.refresh()
        }
    }

    onLatitudeChanged: Qt.callLater(refresh)
    onLongitudeChanged: Qt.callLater(refresh)

    activationTogglesExpanded: true

    onExpandedChanged: if (expanded && Date.now() - attemptedAt > 300000) refresh()

    compactRepresentation: MouseArea {
        id: compact

        Layout.preferredWidth: compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.minimumWidth: Layout.preferredWidth
        Layout.maximumWidth: Layout.preferredWidth
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Kirigami.Icon {
                source: root.weather ? root.weather.icon : "weather-none-available"
                Layout.preferredWidth: Kirigami.Units.iconSizes.roundedIconSize(Math.min(compact.height, Kirigami.Units.iconSizes.smallMedium))
                Layout.preferredHeight: Layout.preferredWidth
            }

            PC3.Label {
                text: root.weather ? root.weather.temp : "…"
                textFormat: Text.PlainText
                opacity: root.stale ? 0.5 : 1
            }
        }
    }

    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 30
        Layout.preferredHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                PlasmaExtras.Heading {
                    level: 3
                    text: root.cityName
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                PC3.Label {
                    visible: root.weather !== null
                    text: root.weather ? "данные на " + root.weather.time : ""
                    opacity: 0.6
                }

                PC3.ToolButton {
                    icon.name: "view-refresh"
                    enabled: !root.loading
                    onClicked: root.refresh()
                    PC3.ToolTip { text: "Обновить" }
                }
            }

            PC3.Label {
                visible: root.errorText !== ""
                text: root.errorText
                textFormat: Text.PlainText
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            PC3.Label {
                visible: root.weather === null && root.errorText === ""
                text: "Загрузка…"
                opacity: 0.6
                Layout.alignment: Qt.AlignHCenter
            }

            // Текущая погода
            RowLayout {
                visible: root.weather !== null
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: root.weather ? root.weather.icon : ""
                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                    Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                }

                ColumnLayout {
                    spacing: 0

                    PC3.Label {
                        text: root.weather ? root.weather.temp : ""
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2.6
                        font.weight: Font.Light
                    }

                    PC3.Label {
                        text: root.weather ? root.weather.text : ""
                    }
                }

                Item { Layout.fillWidth: true }

                GridLayout {
                    columns: 4
                    columnSpacing: Kirigami.Units.largeSpacing
                    rowSpacing: Kirigami.Units.smallSpacing / 2

                    Repeater {
                        model: root.weather ? [
                            ["Ощущается", root.weather.feels], ["Влажность", root.weather.humidity],
                            ["Ветер", root.weather.wind], ["Давление", root.weather.pressure],
                            ["Порывы", root.weather.gusts], ["Солнце", root.weather.sunrise + " – " + root.weather.sunset]
                        ] : []

                        RowLayout {
                            required property var modelData
                            Layout.columnSpan: 2
                            spacing: Kirigami.Units.smallSpacing

                            PC3.Label {
                                text: parent.modelData[0]
                                opacity: 0.6
                            }

                            PC3.Label {
                                text: parent.modelData[1]
                            }
                        }
                    }
                }
            }

            Kirigami.Separator {
                visible: root.weather !== null
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }

            // Почасовой прогноз: 24 часа от текущего, двумя рядами по 12
            PC3.Label {
                visible: root.weather !== null
                text: "Ближайшие 24 часа"
                opacity: 0.6
            }

            GridLayout {
                visible: root.weather !== null
                Layout.fillWidth: true
                columns: 12
                columnSpacing: 0
                rowSpacing: Kirigami.Units.largeSpacing
                uniformCellWidths: true

                Repeater {
                    model: root.weather ? root.weather.hourly : []

                    // Обёртка нужна, чтобы ячейка растягивалась: сам ColumnLayout не шире своего содержимого
                    Item {
                        id: hourCell
                        required property var modelData
                        Layout.fillWidth: true
                        implicitWidth: hourColumn.implicitWidth
                        implicitHeight: hourColumn.implicitHeight

                        ColumnLayout {
                            id: hourColumn
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 0

                            PC3.Label {
                                text: hourCell.modelData.hour
                                opacity: 0.6
                                font: Kirigami.Theme.smallFont
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Kirigami.Icon {
                                source: hourCell.modelData.icon
                                Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                                Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                                Layout.alignment: Qt.AlignHCenter

                                PC3.ToolTip.text: hourCell.modelData.text
                                PC3.ToolTip.visible: hourHover.hovered
                                HoverHandler { id: hourHover }
                            }

                            PC3.Label {
                                text: hourCell.modelData.temp
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // Вероятность осадков; строка занимает место и при нуле, чтобы ряды не прыгали
                            PC3.Label {
                                text: hourCell.modelData.precip > 0 ? hourCell.modelData.precip + "%" : " "
                                color: Kirigami.Theme.linkColor
                                font: Kirigami.Theme.smallFont
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }

            Kirigami.Separator {
                visible: root.weather !== null
                Layout.fillWidth: true
            }

            // Прогноз на 7 дней
            PC3.Label {
                visible: root.weather !== null
                text: "7 дней"
                opacity: 0.6
            }

            GridLayout {
                visible: root.weather !== null
                Layout.fillWidth: true
                columns: 6
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.weather ? root.weather.daily : []

                    // Шесть ячеек одной строки таблицы; Repeater раскладывает их в общий GridLayout
                    Item {
                        id: dayRow
                        required property var modelData
                        required property int index
                        visible: false

                        Component.onCompleted: {
                            for (const cell of [dayName, dayIcon, dayText, dayPrecip, dayMin, dayMax]) cell.parent = dayRow.parent
                        }

                        PC3.Label {
                            id: dayName
                            text: dayRow.modelData.label
                            Layout.row: dayRow.index
                            Layout.column: 0
                        }

                        Kirigami.Icon {
                            id: dayIcon
                            source: dayRow.modelData.icon
                            Layout.row: dayRow.index
                            Layout.column: 1
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                        }

                        PC3.Label {
                            id: dayText
                            text: dayRow.modelData.text
                            elide: Text.ElideRight
                            Layout.row: dayRow.index
                            Layout.column: 2
                            Layout.fillWidth: true
                        }

                        PC3.Label {
                            id: dayPrecip
                            text: dayRow.modelData.precipSum > 0 ? dayRow.modelData.precipProb + "%, " + Weather.decimal(dayRow.modelData.precipSum) + " мм" : ""
                            color: Kirigami.Theme.linkColor
                            Layout.row: dayRow.index
                            Layout.column: 3
                            Layout.alignment: Qt.AlignRight
                        }

                        PC3.Label {
                            id: dayMin
                            text: dayRow.modelData.tempMin
                            opacity: 0.6
                            Layout.row: dayRow.index
                            Layout.column: 4
                            Layout.alignment: Qt.AlignRight
                        }

                        PC3.Label {
                            id: dayMax
                            text: dayRow.modelData.tempMax
                            font.bold: true
                            Layout.row: dayRow.index
                            Layout.column: 5
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }
            }
        }
    }
}
