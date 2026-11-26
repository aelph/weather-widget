#!/usr/bin/env bash
# Собирает пакет dist/org.elph.weather-<версия>.plasmoid для каталога KDE Store и для установки через «Установить виджет из файла…»
set -euo pipefail
cd "$(dirname "$0")"

# Переводы собираются заново, если есть gettext; иначе в пакет идёт уже собранный каталог
if command -v msgfmt >/dev/null 2>&1; then
    ./build-translations.sh
fi

python3 - <<'PY'
import json, os, zipfile
src = "plasmoid/org.elph.weather"
version = json.load(open(os.path.join(src, "metadata.json"), encoding="utf-8"))["KPlugin"]["Version"]
os.makedirs("dist", exist_ok=True)
out = "dist/org.elph.weather-%s.plasmoid" % version
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for folder, dirs, files in os.walk(src):
        dirs.sort()
        for name in sorted(files):
            path = os.path.join(folder, name)
            z.write(path, os.path.relpath(path, src))
print(out)
PY
