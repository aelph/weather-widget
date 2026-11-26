#!/usr/bin/env bash
# Собирает переводы из po/*.po в пакет плазмоида (contents/locale/<язык>/LC_MESSAGES/*.mo)
set -euo pipefail
cd "$(dirname "$0")"

domain=plasma_applet_org.elph.weather
for po in po/*.po; do
    lang=$(basename "$po" .po)
    dir=plasmoid/org.elph.weather/contents/locale/$lang/LC_MESSAGES
    mkdir -p "$dir"
    msgfmt --check -o "$dir/$domain.mo" "$po"
done
