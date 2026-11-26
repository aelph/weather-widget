.pragma library

// Коды погоды ВМО, которые отдаёт Open-Meteo: описание, значок днём, значок ночью
const CODES = {
    0: ["Ясно", "weather-clear", "weather-clear-night"],
    1: ["Преимущественно ясно", "weather-few-clouds", "weather-few-clouds-night"],
    2: ["Переменная облачность", "weather-clouds", "weather-clouds-night"],
    3: ["Пасмурно", "weather-overcast", "weather-overcast"],
    45: ["Туман", "weather-fog", "weather-fog"],
    48: ["Туман с изморозью", "weather-fog", "weather-fog"],
    51: ["Слабая морось", "weather-showers-scattered-day", "weather-showers-scattered-night"],
    53: ["Морось", "weather-showers-scattered", "weather-showers-scattered"],
    55: ["Сильная морось", "weather-showers-scattered", "weather-showers-scattered"],
    56: ["Ледяная морось", "weather-freezing-scattered-rain", "weather-freezing-scattered-rain"],
    57: ["Сильная ледяная морось", "weather-freezing-scattered-rain", "weather-freezing-scattered-rain"],
    61: ["Небольшой дождь", "weather-showers-scattered", "weather-showers-scattered"],
    63: ["Дождь", "weather-showers", "weather-showers"],
    65: ["Сильный дождь", "weather-showers", "weather-showers"],
    66: ["Ледяной дождь", "weather-freezing-rain", "weather-freezing-rain"],
    67: ["Сильный ледяной дождь", "weather-freezing-rain", "weather-freezing-rain"],
    71: ["Небольшой снег", "weather-snow-scattered", "weather-snow-scattered"],
    73: ["Снег", "weather-snow", "weather-snow"],
    75: ["Сильный снег", "weather-snow", "weather-snow"],
    77: ["Снежная крупа", "weather-snow-scattered", "weather-snow-scattered"],
    80: ["Небольшой ливень", "weather-showers-scattered-day", "weather-showers-scattered-night"],
    81: ["Ливень", "weather-showers-day", "weather-showers-night"],
    82: ["Сильный ливень", "weather-showers", "weather-showers"],
    85: ["Снегопад", "weather-snow-scattered-day", "weather-snow-scattered-night"],
    86: ["Сильный снегопад", "weather-snow-day", "weather-snow-night"],
    95: ["Гроза", "weather-storm", "weather-storm"],
    96: ["Гроза с градом", "weather-hail", "weather-hail"],
    99: ["Гроза с сильным градом", "weather-hail", "weather-hail"]
}

const WIND = ["С", "ССВ", "СВ", "ВСВ", "В", "ВЮВ", "ЮВ", "ЮЮВ", "Ю", "ЮЮЗ", "ЮЗ", "ЗЮЗ", "З", "ЗСЗ", "СЗ", "ССЗ"]
const WEEKDAYS = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]

function describe(code) {
    return CODES[code] ? CODES[code][0] : "Нет данных"
}

function icon(code, isDay) {
    if (!CODES[code]) return "weather-none-available"
    return isDay ? CODES[code][1] : CODES[code][2]
}

// Знак минуса – типографский, ноль без знака
function temp(value) {
    const r = Math.round(value)
    if (r === 0) return "0°"
    return (r < 0 ? "−" + (-r) : r) + "°"
}

function decimal(value) {
    return value.toFixed(1).replace(".", ",")
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
    if (index === 0) return "Сегодня"
    if (index === 1) return "Завтра"
    const d = new Date(parseInt(iso.substring(0, 4)), parseInt(iso.substring(5, 7)) - 1, parseInt(iso.substring(8, 10)))
    return WEEKDAYS[d.getDay()] + ", " + d.getDate()
}

function url(latitude, longitude) {
    return "https://api.open-meteo.com/v1/forecast?latitude=" + latitude + "&longitude=" + longitude
        + "&timezone=auto&wind_speed_unit=ms&forecast_days=7&forecast_hours=24"
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,is_day,wind_speed_10m,wind_direction_10m,wind_gusts_10m,surface_pressure"
        + "&hourly=temperature_2m,weather_code,is_day,precipitation_probability"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max,sunrise,sunset"
}

// Приводит ответ Open-Meteo к виду, удобному для вёрстки. Бросает исключение, если ответ неполон.
function parse(text) {
    const j = JSON.parse(text)
    if (j.error) throw new Error(j.reason || "ошибка сервиса")
    const c = j.current, h = j.hourly, d = j.daily

    const hourly = []
    for (let i = 0; i < h.time.length; i++) {
        hourly.push({
            hour: hour(h.time[i]),
            temp: temp(h.temperature_2m[i]),
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
            tempMax: temp(d.temperature_2m_max[i]),
            tempMin: temp(d.temperature_2m_min[i]),
            precipProb: d.precipitation_probability_max[i],
            precipSum: d.precipitation_sum[i]
        })
    }

    return {
        time: clock(c.time),
        temp: temp(c.temperature_2m),
        feels: temp(c.apparent_temperature),
        icon: icon(c.weather_code, c.is_day === 1),
        text: describe(c.weather_code),
        humidity: Math.round(c.relative_humidity_2m) + " %",
        wind: windDir(c.wind_direction_10m) + " " + decimal(c.wind_speed_10m) + " м/с",
        gusts: decimal(c.wind_gusts_10m) + " м/с",
        // Давление на уровне места, а не приведённое к уровню моря: 1 гПа = 0,750062 мм рт. ст.
        pressure: Math.round(c.surface_pressure * 0.750062) + " мм рт. ст.",
        sunrise: clock(d.sunrise[0]),
        sunset: clock(d.sunset[0]),
        hourly: hourly,
        daily: daily
    }
}
