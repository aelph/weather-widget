#!/usr/bin/env bash
# Ставит или обновляет плазмоид «Погода» в ~/.local/share/plasma/plasmoids/
set -euo pipefail
cd "$(dirname "$0")"

# Переводы собираются заново, если есть gettext; иначе ставится уже собранный каталог из пакета
if command -v msgfmt >/dev/null 2>&1; then
    ./build-translations.sh
fi

if kpackagetool6 -t Plasma/Applet -s org.elph.weather >/dev/null 2>&1; then
    kpackagetool6 -t Plasma/Applet -u plasmoid/org.elph.weather
else
    kpackagetool6 -t Plasma/Applet -i plasmoid/org.elph.weather
fi

echo "Готово. Новый виджет добавляется через «Добавить виджеты…»; уже стоящий на панели подхватит обновление после перезапуска plasmashell (systemctl --user restart plasma-plasmashell.service)."
