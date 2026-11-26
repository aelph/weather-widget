import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PC3
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami
import "weather.js" as Weather

PlasmoidItem {
    id: root

    // Место: определённое по IP-адресу либо заданное в настройках вручную
    readonly property bool autoLocation: Plasmoid.configuration.autoLocation
    property var detected: null
    property double locatedAt: 0
    readonly property string latitude: autoLocation ? (detected ? String(detected.lat) : "") : Plasmoid.configuration.latitude.replace(",", ".")
    readonly property string longitude: autoLocation ? (detected ? String(detected.lon) : "") : Plasmoid.configuration.longitude.replace(",", ".")
    readonly property string cityName: {
        if (autoLocation) return detected ? (detected.name !== "" ? detected.name : latitude + ", " + longitude) : i18n("Weather")
        if (Plasmoid.configuration.cityName !== "") return Plasmoid.configuration.cityName
        return latitude !== "" && longitude !== "" ? latitude + ", " + longitude : i18n("Weather")
    }
    readonly property int updateMs: Math.max(5, Plasmoid.configuration.updateInterval) * 60000

    // Выбранные единицы измерения; при смене последний ответ сервиса разбирается заново, без нового запроса
    readonly property var units: ({
        temp: Plasmoid.configuration.tempUnit,
        wind: Plasmoid.configuration.windUnit,
        pressure: Plasmoid.configuration.pressureUnit,
        precip: Plasmoid.configuration.precipUnit
    })
    // Срок и пороги тенденций; в настройках пороги хранятся в десятых долях, кроме влажности
    readonly property var trends: ({
        hours: Math.max(1, Math.min(12, Plasmoid.configuration.trendHours)),
        temp: Plasmoid.configuration.trendTemp / 10,
        humidity: Plasmoid.configuration.trendHumidity,
        wind: Plasmoid.configuration.trendWind / 10,
        gusts: Plasmoid.configuration.trendGusts / 10,
        pressure: Plasmoid.configuration.trendPressure / 10
    })
    property string rawText: ""

    readonly property bool showHourly: Plasmoid.configuration.showHourly
    readonly property bool showDaily: Plasmoid.configuration.showDaily
    // Без обоих прогнозов окно сужается до текущей погоды, а показатели уходят под температуру
    readonly property bool narrow: !showHourly && !showDaily

    onUnitsChanged: reparse()
    onTrendsChanged: reparse()

    // Смена единиц или настроек тенденций: последний ответ сервиса разбирается заново, без нового запроса
    function reparse() {
        if (rawText === "") return
        try {
            weather = Weather.parse(rawText, units, trends)
        } catch (e) {
            errorText = i18n("Could not parse the Open-Meteo response: %1", e.message)
        }
    }

    property var weather: null
    property string errorText: ""
    property bool loading: false
    property double fetchedAt: 0
    property double attemptedAt: 0
    property var request: null
    property var requestDone: null
    // Ошибка, которую пользователь исправляет в настройках: под сообщением показывается кнопка настройки
    property bool needsConfig: false

    // Данные старше двух часов считаются устаревшими: значение на панели бледнеет
    property bool stale: false

    toolTipMainText: cityName
    toolTipSubText: {
        if (!weather) return errorText !== "" ? errorText : i18n("Loading…")
        let s = i18nc("temperature, description; feels-like temperature, wind", "%1, %2\nFeels like %3, wind %4", weather.temp, weather.text.toLowerCase(), weather.feels, weather.wind)
        if (errorText !== "") s += "\n" + errorText
        return s
    }

    // Запрос GET с ответом в onDone(код, текст). Запрос без ответа обрывается сторожевым таймером, тогда код равен -1.
    function get(address, onDone) {
        const xhr = new XMLHttpRequest()
        request = xhr
        requestDone = onDone
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE || request !== xhr) return
            watchdog.stop()
            request = null
            requestDone = null
            onDone(xhr.status, xhr.responseText)
        }
        xhr.open("GET", address)
        xhr.send()
        watchdog.restart()
    }

    // relocate – определить место заново, даже если оно определено недавно (кнопка «Обновить»)
    function refresh(relocate) {
        if (loading) return
        attemptedAt = Date.now()
        if (autoLocation) {
            // Место по IP-адресу переопределяется раз в три часа: адрес и с ним место могут смениться
            if (detected === null || relocate === true || Date.now() - locatedAt > 10800000) {
                loading = true
                locate(0)
                return
            }
        } else if (isNaN(parseFloat(latitude)) || isNaN(parseFloat(longitude))) {
            errorText = i18n("Location coordinates are not set. Open the widget settings.")
            needsConfig = true
            return
        }
        loading = true
        fetchWeather()
    }

    // Определение места: сервисы опрашиваются по очереди, пока один не ответит координатами
    function locate(index) {
        if (index >= Weather.LOCATORS.length) {
            if (detected !== null) {
                // Сервисы не ответили, но место уже известно: погода запрашивается для него
                fetchWeather()
                return
            }
            loading = false
            errorText = i18n("Could not determine the location by IP address. Turn the detection off and set the coordinates in the widget settings.")
            needsConfig = true
            return
        }
        get(Weather.LOCATORS[index], function(status, text) {
            let found = null
            if (status === 200) {
                try {
                    found = Weather.parseLocation(text)
                } catch (e) {
                    found = null
                }
            }
            if (found === null) locate(index + 1)
            else if (found.name === "") located(found)
            else localize(found)
        })
    }

    // Сервисы отдают название места по-английски; название на языке системы берётся у геокодера Open-Meteo
    function localize(found) {
        get(Weather.geocoderUrl(found.name), function(status, text) {
            if (status === 200) {
                try {
                    const name = Weather.localizedName(text, found.lat, found.lon)
                    if (name !== "") found.name = name
                } catch (e) {
                }
            }
            located(found)
        })
    }

    function located(found) {
        locatedAt = Date.now()
        detected = found
        fetchWeather()
    }

    function fetchWeather() {
        get(Weather.url(latitude, longitude), function(status, text) {
            loading = false
            if (status !== 200) {
                errorText = status === -1 ? i18n("Open-Meteo did not respond within 30 seconds") : status === 0 ? i18n("No connection to Open-Meteo") : i18n("Open-Meteo returned status %1", String(status))
                return
            }
            try {
                weather = Weather.parse(text, root.units, root.trends)
                rawText = text
                fetchedAt = Date.now()
                stale = false
                errorText = ""
                needsConfig = false
            } catch (e) {
                errorText = i18n("Could not parse the Open-Meteo response: %1", e.message)
            }
        })
    }

    // Запрос без ответа обрывается, иначе признак загрузки навсегда заблокирует обновление
    Timer {
        id: watchdog
        interval: 30000
        onTriggered: {
            const xhr = root.request
            const done = root.requestDone
            root.request = null
            root.requestDone = null
            if (xhr) xhr.abort()
            if (done) done(-1, "")
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

    // Смена места в настройках. Когда место определено по IP-адресу, погоду запрашивает само определение.
    onLatitudeChanged: if (!autoLocation) Qt.callLater(refresh)
    onLongitudeChanged: if (!autoLocation) Qt.callLater(refresh)
    onAutoLocationChanged: {
        errorText = ""
        needsConfig = false
        Qt.callLater(refresh)
    }

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
        Layout.preferredWidth: root.narrow ? Math.min(Kirigami.Units.gridUnit * 30, Math.max(Kirigami.Units.gridUnit * 16, current.implicitWidth + Kirigami.Units.largeSpacing * 2)) : Kirigami.Units.gridUnit * 30
        Layout.preferredHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight
        // Наибольший размер равен предпочтительному, чтобы окно сжималось, когда прогнозы отключены
        Layout.maximumWidth: Layout.preferredWidth
        Layout.maximumHeight: Layout.preferredHeight

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
                    text: root.weather ? i18nc("time of the observation", "as of %1", root.weather.time) : ""
                    opacity: 0.6
                }

                PC3.ToolButton {
                    icon.name: "view-refresh"
                    enabled: !root.loading
                    onClicked: root.refresh(true)
                    PC3.ToolTip { text: i18n("Refresh") }
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

            PC3.Button {
                visible: root.needsConfig && root.errorText !== ""
                icon.name: "configure"
                text: i18n("Configure…")
                onClicked: Plasmoid.internalAction("configure").trigger()
            }

            PC3.Label {
                visible: root.weather === null && root.errorText === ""
                text: i18n("Loading…")
                opacity: 0.6
                Layout.alignment: Qt.AlignHCenter
            }

            // Текущая погода: в широком окне показатели стоят справа от температуры, в узком – под ней
            GridLayout {
                id: current
                visible: root.weather !== null
                Layout.fillWidth: true
                columns: root.narrow ? 1 : 3
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.largeSpacing

                RowLayout {
                    spacing: Kirigami.Units.largeSpacing

                    Kirigami.Icon {
                        source: root.weather ? root.weather.icon : ""
                        Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                        Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                    }

                    ColumnLayout {
                        spacing: 0

                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing

                            PC3.Label {
                                text: root.weather ? root.weather.temp : ""
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 2.6
                                font.weight: Font.Light
                                Layout.alignment: Qt.AlignBaseline
                            }

                            // Тенденция температуры; тем же цветом, что осадки в прогнозах
                            PC3.Label {
                                visible: text !== ""
                                text: root.weather ? root.weather.tempTrend : ""
                                color: Kirigami.Theme.linkColor
                                Layout.alignment: Qt.AlignBaseline
                            }
                        }

                        PC3.Label {
                            text: root.weather ? root.weather.text : ""
                        }
                    }
                }

                Item {
                    visible: !root.narrow
                    Layout.fillWidth: true
                }

                GridLayout {
                    columns: 4
                    columnSpacing: Kirigami.Units.largeSpacing
                    rowSpacing: Kirigami.Units.smallSpacing / 2

                    Repeater {
                        model: root.weather ? [
                            [i18n("Feels like"), root.weather.feels, root.weather.feelsTrend], [i18n("Humidity"), root.weather.humidity, root.weather.humidityTrend],
                            [i18n("Wind"), root.weather.wind, root.weather.windTrend], [i18n("Pressure"), root.weather.pressure, root.weather.pressureTrend],
                            [i18n("Gusts"), root.weather.gusts, root.weather.gustsTrend], [i18n("Sun"), root.weather.sunrise + " – " + root.weather.sunset, root.weather.sunTrend]
                        ] : []

                        // Показатель и под ним его тенденция; у «Солнца» это изменение долготы дня к завтрашнему дню
                        ColumnLayout {
                            id: detail
                            required property var modelData
                            Layout.columnSpan: 2
                            Layout.alignment: Qt.AlignTop
                            spacing: 0

                            RowLayout {
                                spacing: Kirigami.Units.smallSpacing

                                PC3.Label {
                                    text: detail.modelData[0]
                                    opacity: 0.6
                                }

                                PC3.Label {
                                    text: detail.modelData[1]
                                }
                            }

                            PC3.Label {
                                visible: text !== ""
                                text: detail.modelData[2]
                                color: Kirigami.Theme.linkColor
                                font: Kirigami.Theme.smallFont
                            }
                        }
                    }
                }
            }

            Kirigami.Separator {
                visible: root.weather !== null && !root.narrow
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }

            // Почасовой прогноз: 24 часа от текущего, двумя рядами по 12
            PC3.Label {
                visible: root.weather !== null && root.showHourly
                text: i18n("Next 24 hours")
                opacity: 0.6
            }

            GridLayout {
                visible: root.weather !== null && root.showHourly
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
                visible: root.weather !== null && root.showHourly && root.showDaily
                Layout.fillWidth: true
            }

            // Прогноз на 7 дней
            PC3.Label {
                visible: root.weather !== null && root.showDaily
                text: i18n("7 days")
                opacity: 0.6
            }

            GridLayout {
                visible: root.weather !== null && root.showDaily
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
                            text: dayRow.modelData.precipSum > 0 ? dayRow.modelData.precipProb + "%, " + dayRow.modelData.precipText : ""
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

            Item { Layout.fillHeight: true }
        }
    }
}
