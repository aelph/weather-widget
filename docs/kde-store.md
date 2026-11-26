# Страница виджета в каталоге KDE Store

Заготовка для страницы на store.kde.org. Текст описания без разметки: какую разметку поддерживает каталог, не проверялось.

## Поля

| Поле | Значение |
| --- | --- |
| Название | Open-Meteo Weather |
| Категория | Plasma 6 Applets |
| Версия | 1.1 |
| Лицензия | MIT |
| Ссылка на исходники | https://github.com/aelph/weather-widget |
| Файл | `dist/org.elph.weather-1.1.plasmoid` (собирается `./build-package.sh`, приложен к релизу v1.1) |
| Метки | weather, forecast, open-meteo, plasma6 |

## Метки: только латиница

Метки на русском форма не принимает: при попытке их ввести форма очищается (наблюдение владельца при заполнении, 26.11.2026). Сообщения об ошибке при этом нет, введённое теряется, поэтому перед вводом меток стоит сохранить остальные поля.

Проверка по данным каталога (26.11.2026, программный интерфейс `api.kde-look.org`, категории виджетов Plasma 5 и 6): просмотрен 1261 продукт, 1071 разная метка, и среди них нет ни одной с нелатинскими символами – ни кириллицы, ни иероглифов, ни букв с диакритикой. Все метки состоят из строчных латинских букв, цифр и знаков `-`, `_`, `+`, `.`. Отсюда вывод: это общее ограничение набора символов, а не запрет именно русского языка. Правила каталога и код проверки не читались, так что вывод сделан по косвенным данным. То, что форма молча очищается вместо сообщения об ошибке, похоже на дефект самой формы.

Чтобы виджет находился по русским запросам, русские слова («погода», «прогноз») стоят в описании: поиск каталога по описанию работает – по запросу «погода» в категории Plasma 6 находится продукт, у которого это слово есть только в тексте.

## Картинки

Из каталога `screenshots/`, в таком порядке: `en-full.png` (обложка), `ru-full.png`, `en-compact.png`, `settings-en.png`, `panel.png`. Это отрисовка без рабочего стола, а не снимки экрана.

## Описание

```
A weather widget for the Plasma 6 panel using Open-Meteo data. No API key and no account needed.

In the panel: weather icon and temperature. The width is fixed, so the widget does not overlap its neighbours.

In the popup:
- current conditions: temperature, feels-like, wind and gusts, humidity, pressure, sunrise and sunset
- trends: a word next to each value shows whether it is rising, falling or steady, and how the day length changes
- hourly forecast for the next 24 hours
- forecast for 7 days

Settings:
- place search by name, or coordinates typed by hand
- optional location detection by IP address, off by default
- units for temperature, wind, pressure and precipitation
- either forecast can be hidden; with both hidden the popup shrinks to current conditions
- trend horizon and thresholds

Languages: English and Russian, following the system language.

Privacy: the widget sends the coordinates of the place to Open-Meteo and nothing else. Detection by IP address uses ipwho.is (geojs.io as a fallback) and works only if you turn it on.

Weather data by Open-Meteo, CC BY 4.0. The free Open-Meteo API is intended for non-commercial use.

---

Виджет погоды для панели Plasma 6 на данных Open-Meteo. Ключ API и учётная запись не нужны.

В панели: значок погоды и температура. Ширина закреплена, поэтому виджет не наезжает на соседей.

В раскрытом виде:
- текущая погода: температура, «ощущается», ветер и порывы, влажность, давление, восход и закат
- тенденции: слово рядом с каждым показателем говорит, повышается он, понижается или не меняется, и как меняется долгота дня
- почасовой прогноз на 24 часа
- прогноз на 7 дней

Настройки:
- поиск места по названию или ввод координат вручную
- определение места по IP-адресу, по желанию; по умолчанию выключено
- единицы измерения температуры, ветра, давления и осадков
- любой из прогнозов можно скрыть; без обоих окно сужается до текущей погоды
- срок и пороги тенденций

Языки: английский и русский, по языку системы.

Приватность: виджет отправляет в Open-Meteo координаты места и больше ничего. Определение по IP-адресу обращается к ipwho.is (запасной сервис – geojs.io) и работает, только если его включить.

Данные о погоде – Open-Meteo, лицензия CC BY 4.0. Бесплатный API Open-Meteo предназначен для некоммерческого использования.
```
