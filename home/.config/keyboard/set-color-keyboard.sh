#!/bin/bash
set -euo pipefail

WAL_COLORS="${HOME}/.config/keyboard/matugen-colors-rgb"
# По умолчанию color1 (можно запустить ./set-color-keyboard.sh 0 для color0)
COLOR_INDEX=${1:-1}

if [[ ! -f "$WAL_COLORS" ]]; then
  echo "Файл не найден: $WAL_COLORS" >&2
  exit 1
fi

# color0 -> первая непустая строка, color1 -> вторая, и т.д.
TARGET_LINE=$((COLOR_INDEX + 1))
COLOR=$(awk -v tgt="$TARGET_LINE" 'NF{c++; if(c==tgt){print; exit}}' "$WAL_COLORS")

if [[ -z "$COLOR" ]]; then
  echo "Не удалось получить color${COLOR_INDEX} из $WAL_COLORS" >&2
  exit 1
fi

# matugen выдаёт hex (rrggbb) — конвертируем в r,g,b
HEX="${COLOR#\#}"
R=$((16#${HEX:0:2})); G=$((16#${HEX:2:2})); B=$((16#${HEX:4:2}))
RGB="${R},${G},${B}"

# Сделать 4 зоны одинаковыми
ARGS="${RGB},${RGB},${RGB},${RGB}"

# Найти бинарь legion-kb-rgb (PATH или ~/.config/keyboard/legion-kb-rgb)
CMD=$(command -v legion-kb-rgb || true)
if [[ -z "$CMD" ]]; then
  if [[ -x "${HOME}/.config/keyboard/legion-kb-rgb" ]]; then
    CMD="${HOME}/.config/keyboard/legion-kb-rgb"
  else
    echo "legion-kb-rgb не найден в PATH и не найден ${HOME}/.config/keyboard/legion-kb-rgb" >&2
    exit 1
  fi
fi

# Применяем
"$CMD" set -e Static -c "$ARGS"
