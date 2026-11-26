// Не библиотека (.pragma library): библиотечному сценарию недоступны i18n() и Qt.locale() из окружения QML

// Коды погоды ВМО, которые отдаёт Open-Meteo: описание, значок днём, значок ночью
const CODES = {
    0: [i18n("Clear"), "weather-clear", "weather-clear-night"],
    1: [i18n("Mostly clear"), "weather-few-clouds", "weather-few-clouds-night"],
    2: [i18n("Partly cloudy"), "weather-clouds", "weather-clouds-night"],
    3: [i18n("Overcast"), "weather-overcast", "weather-overcast"],
    45: [i18n("Fog"), "weather-fog", "weather-fog"],
    48: [i18n("Rime fog"), "weather-fog", "weather-fog"],
    51: [i18n("Light drizzle"), "weather-showers-scattered-day", "weather-showers-scattered-night"],
    53: [i18n("Drizzle"), "weather-showers-scattered", "weather-showers-scattered"],
    55: [i18n("Heavy drizzle"), "weather-showers-scattered", "weather-showers-scattered"],
    56: [i18n("Freezing drizzle"), "weather-freezing-scattered-rain", "weather-freezing-scattered-rain"],
    57: [i18n("Heavy freezing drizzle"), "weather-freezing-scattered-rain", "weather-freezing-scattered-rain"],
    61: [i18n("Light rain"), "weather-showers-scattered", "weather-showers-scattered"],
    63: [i18n("Rain"), "weather-showers", "weather-showers"],
    65: [i18n("Heavy rain"), "weather-showers", "weather-showers"],
    66: [i18n("Freezing rain"), "weather-freezing-rain", "weather-freezing-rain"],
    67: [i18n("Heavy freezing rain"), "weather-freezing-rain", "weather-freezing-rain"],
    71: [i18n("Light snow"), "weather-snow-scattered", "weather-snow-scattered"],
    73: [i18n("Snow"), "weather-snow", "weather-snow"],
    75: [i18n("Heavy snow"), "weather-snow", "weather-snow"],
    77: [i18n("Snow grains"), "weather-snow-scattered", "weather-snow-scattered"],
    80: [i18n("Light showers"), "weather-showers-scattered-day", "weather-showers-scattered-night"],
    81: [i18n("Showers"), "weather-showers-day", "weather-showers-night"],
    82: [i18n("Heavy showers"), "weather-showers", "weather-showers"],
    85: [i18n("Snow showers"), "weather-snow-scattered-day", "weather-snow-scattered-night"],
    86: [i18n("Heavy snow showers"), "weather-snow-day", "weather-snow-night"],
    95: [i18n("Thunderstorm"), "weather-storm", "weather-storm"],
    96: [i18n("Thunderstorm with hail"), "weather-hail", "weather-hail"],
    99: [i18n("Thunderstorm with heavy hail"), "weather-hail", "weather-hail"]
}

const WIND = [i18nc("wind direction", "N"), i18nc("wind direction", "NNE"), i18nc("wind direction", "NE"), i18nc("wind direction", "ENE"), i18nc("wind direction", "E"), i18nc("wind direction", "ESE"), i18nc("wind direction", "SE"), i18nc("wind direction", "SSE"), i18nc("wind direction", "S"), i18nc("wind direction", "SSW"), i18nc("wind direction", "SW"), i18nc("wind direction", "WSW"), i18nc("wind direction", "W"), i18nc("wind direction", "WNW"), i18nc("wind direction", "NW"), i18nc("wind direction", "NNW")]
const WEEKDAYS = [i18nc("weekday, short", "Sun"), i18nc("weekday, short", "Mon"), i18nc("weekday, short", "Tue"), i18nc("weekday, short", "Wed"), i18nc("weekday, short", "Thu"), i18nc("weekday, short", "Fri"), i18nc("weekday, short", "Sat")]

function describe(code) {
    return CODES[code] ? CODES[code][0] : i18n("No data")
}

function icon(code, isDay) {
    if (!CODES[code]) return "weather-none-available"
    return isDay ? CODES[code][1] : CODES[code][2]
}

// Сервис всегда запрашивается в одних и тех же единицах (°C, м/с, гПа, мм); пересчёт в выбранные делается здесь, поэтому смена единиц не требует нового запроса.
// Знак минуса – типографский, ноль без знака
function temp(value, unit) {
    const r = Math.round(unit === "f" ? value * 9 / 5 + 32 : value)
    if (r === 0) return "0°"
    return (r < 0 ? "−" + (-r) : r) + "°"
}

// Десятичный разделитель – по региональным настройкам системы
function decimal(value, digits) {
    return value.toFixed(digits === undefined ? 1 : digits).replace(".", Qt.locale().decimalPoint)
}

// Скорость ветра из м/с
function speed(value, unit) {
    if (unit === "kmh") return i18n("%1 km/h", String(Math.round(value * 3.6)))
    if (unit === "mph") return i18n("%1 mph", String(Math.round(value * 2.236936)))
    if (unit === "kn") return i18n("%1 kn", String(Math.round(value * 1.943844)))
    return i18n("%1 m/s", decimal(value))
}

// Давление из гПа
function pressure(value, unit) {
    if (unit === "hpa") return i18n("%1 hPa", String(Math.round(value)))
    if (unit === "inhg") return i18n("%1 inHg", decimal(value * 0.0295300, 2))
    return i18n("%1 mmHg", String(Math.round(value * 0.750062)))
}

// Количество осадков из мм
function precipitation(value, unit) {
    if (unit === "inch") return i18n("%1 in", decimal(value / 25.4, 2))
    return i18n("%1 mm", decimal(value))
}

// Направление, откуда дует ветер
function windDir(degrees) {
    return WIND[Math.round(degrees / 22.5) % 16]
}

// Open-Meteo отдаёт время уже в поясе места, поэтому часы берутся из строки, без пересчёта через Date
function hour(iso) {
    return iso.substring(11, 13)
}

function clock(iso) {
    return iso.substring(11, 16)
}

function dayLabel(iso, index) {
    if (index === 0) return i18n("Today")
    if (index === 1) return i18n("Tomorrow")
    const d = new Date(parseInt(iso.substring(0, 4)), parseInt(iso.substring(5, 7)) - 1, parseInt(iso.substring(8, 10)))
    return i18nc("weekday and day of month", "%1, %2", WEEKDAYS[d.getDay()], String(d.getDate()))
}

// Сервисы определения места по IP-адресу, в порядке обращения; второй – запасной
const LOCATORS = ["https://ipwho.is/", "https://get.geojs.io/v1/ip/geo.json"]

// Разбирает ответ сервиса определения места. Оба сервиса отдают поля latitude, longitude и city. Возвращает null, если координат нет.
function parseLocation(text) {
    const j = JSON.parse(text)
    if (j.success === false) return null
    const lat = parseFloat(j.latitude), lon = parseFloat(j.longitude)
    if (isNaN(lat) || isNaN(lon)) return null
    return { name: j.city || "", lat: lat, lon: lon }
}

// Запрос к геокодеру Open-Meteo: он нужен только затем, чтобы получить название места на языке системы
function geocoderUrl(name) {
    return "https://geocoding-api.open-meteo.com/v1/search?count=10&format=json&language=" + Qt.locale().name.substring(0, 2) + "&name=" + encodeURIComponent(name)
}

// Из ответа геокодера берётся название ближайшего к точке места, если оно не дальше 50 км; иначе пустая строка
function localizedName(text, lat, lon) {
    const results = JSON.parse(text).results || []
    let best = "", bestKm = 50
    for (const r of results) {
        const dLat = (r.latitude - lat) * 111.2
        const dLon = (r.longitude - lon) * 111.2 * Math.cos(lat * Math.PI / 180)
        const km = Math.sqrt(dLat * dLat + dLon * dLon)
        if (km < bestKm) {
            bestKm = km
            best = r.name
        }
    }
    return best
}

function url(latitude, longitude) {
    return "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude
        + "&timezone=auto&wind_speed_unit=ms&forecast_days=7&forecast_hours=24"
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,wind_speed_10m,wind_direction_10m,wind_gusts_10m,surface_pressure"
        + "&hourly=temperature_2m,weather_code,is_day,precipitation_probability,apparent_temperature,relative_humidity_2m,wind_speed_10m,wind_gusts_10m,surface_pressure"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,sunrise,sunset,daylight_duration"
}

// Тенденция показателя: прогноз через hours часов сравнивается с текущим значением.
// Изменение меньше порога считается отсутствием изменений. Значения и пороги – в единицах сервиса (°C, %, м/с, гПа).
// Возвращает 1, -1, 0 или null, если прогноза на нужный час нет.
function trend(now, series, hours, threshold) {
    if (!series || series.length <= hours || series[hours] === null || series[hours] === undefined) return null
    const delta = series[hours] - now
    return delta >= threshold ? 1 : delta <= -threshold ? -1 : 0
}

function steadyText(t) {
    return t === null ? "" : i18nc("trend: no noticeable change", "steady")
}

function riseText(t) {
    return t > 0 ? i18nc("trend of temperature, humidity or pressure", "rising") : t < 0 ? i18nc("trend of temperature, humidity or pressure", "falling") : steadyText(t)
}

function windText(t) {
    return t > 0 ? i18nc("trend of wind speed", "strengthening") : t < 0 ? i18nc("trend of wind speed", "easing") : steadyText(t)
}

function gustsText(t) {
    return t > 0 ? i18nc("trend of wind gusts", "strengthening") : t < 0 ? i18nc("trend of wind gusts", "easing") : steadyText(t)
}

// Приводит ответ Open-Meteo к виду, удобному для вёрстки. Бросает исключение, если ответ неполон.
// units – выбранные единицы: { temp: "c"|"f", wind: "ms"|"kmh"|"mph"|"kn", pressure: "mmhg"|"hpa"|"inhg", precip: "mm"|"inch" }
// Тенденция долготы дня: завтрашняя продолжительность светового дня сравнивается с сегодняшней (в секундах).
// Разница меньше полуминуты, как около солнцестояний, считается отсутствием изменений.
function daylightText(durations) {
    if (!durations || durations.length < 2 || durations[0] === null || durations[1] === null) return ""
    const delta = durations[1] - durations[0]
    const minutes = String(Math.round(Math.abs(delta) / 60))
    if (delta >= 30) return i18nc("change of day length by tomorrow", "day lengthening by %1 min", minutes)
    if (delta <= -30) return i18nc("change of day length by tomorrow", "day shortening by %1 min", minutes)
    return i18nc("change of day length by tomorrow", "day length steady")
}

// trends – срок и пороги тенденций: { hours, temp, humidity, wind, gusts, pressure }
function parse(text, units, trends) {
    const u = units || {}
    const t = trends || { hours: 1, temp: 0.5, humidity: 3, wind: 0.5, gusts: 1, pressure: 0.5 }
    const j = JSON.parse(text)
    if (j.error) throw new Error(j.reason || i18n("service error"))
    const c = j.current, h = j.hourly, d = j.daily

    const hourly = []
    for (let i = 0; i < h.time.length; i++) {
        hourly.push({
            hour: hour(h.time[i]),
            temp: temp(h.temperature_2m[i], u.temp),
            icon: icon(h.weather_code[i], h.is_day[i] === 1),
            text: describe(h.weather_code[i]),
            precip: h.precipitation_probability[i]
        })
    }

    const daily = []
    for (let i = 0; i < d.time.length; i++) {
        daily.push({
            label: dayLabel(d.time[i], i),
            icon: icon(d.weather_code[i], true),
            text: describe(d.weather_code[i]),
            tempMax: temp(d.temperature_2m_max[i], u.temp),
            tempMin: temp(d.temperature_2m_min[i], u.temp),
            precipProb: d.precipitation_probability_max[i],
            precipSum: d.precipitation_sum[i],
            precipText: precipitation(d.precipitation_sum[i], u.precip)
        })
    }

    return {
        time: clock(c.time),
        temp: temp(c.temperature_2m, u.temp),
        feels: temp(c.apparent_temperature, u.temp),
        icon: icon(c.weather_code, c.is_day === 1),
        text: describe(c.weather_code),
        humidity: Math.round(c.relative_humidity_2m) + " %",
        wind: windDir(c.wind_direction_10m) + ", " + speed(c.wind_speed_10m, u.wind),
        gusts: speed(c.wind_gusts_10m, u.wind),
        // Давление на уровне места, а не приведённое к уровню моря
        pressure: pressure(c.surface_pressure, u.pressure),
        tempTrend: riseText(trend(c.temperature_2m, h.temperature_2m, t.hours, t.temp)),
        feelsTrend: riseText(trend(c.apparent_temperature, h.apparent_temperature, t.hours, t.temp)),
        humidityTrend: riseText(trend(c.relative_humidity_2m, h.relative_humidity_2m, t.hours, t.humidity)),
        windTrend: windText(trend(c.wind_speed_10m, h.wind_speed_10m, t.hours, t.wind)),
        gustsTrend: gustsText(trend(c.wind_gusts_10m, h.wind_gusts_10m, t.hours, t.gusts)),
        pressureTrend: riseText(trend(c.surface_pressure, h.surface_pressure, t.hours, t.pressure)),
        sunTrend: daylightText(d.daylight_duration),
        sunrise: clock(d.sunrise[0]),
        sunset: clock(d.sunset[0]),
        hourly: hourly,
        daily: daily
    }
}
