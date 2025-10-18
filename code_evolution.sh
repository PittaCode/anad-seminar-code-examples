#!/usr/bin/env bash
set -euo pipefail

# ---- SETTINGS ----
FILE="src/main/kotlin/com/pittacode/badcode/MovieTicketCalculation.kt"
OUTDIR="/tmp/codegif"
DELAY=500          # 100 => ~1s per frame. Increase for slower.
RESIZE=""         # e.g. "1280x" to scale width, or leave empty
HIDE_IMPORTS=true   # true => hide package/import lines from frames
HIDE_DATA_CLASSES=true  # true => hide single-line Kotlin data class declarations (lines starting with 'data')
BG_COLOR="#FFFFFF"  # background color for padding (hex or named)
STYLE="colorful"         # Pygments style theme (e.g., default, monokai, friendly, native)
HIGHLIGHT_REGEX=""      # ERE regex; lines matching will be highlighted (leave empty to disable)
HIGHLIGHT_COLOR="#FFF59D"  # background color for highlighted lines (ImageFormatter hl_color)
LEXER="kotlin"          # Pygments lexer to use (e.g., kotlin, java, python). Leave empty to auto-detect (-g)
SHOW_LINE_NUMBERS=false  # true => show line numbers in frames (Pygments ImageFormatter)
FONT_SIZE=24             # font size used by Pygments ImageFormatter
LAST_HOLD_SECS=10    # seconds to hold on the final frame; set 0 to disable
EXCLUDE_COMMITS=""   # space-separated commit hashes or prefixes to exclude (e.g., abc123 def456)

# Prefer venv pygmentize if it exists, else fallback to system
PYG="$HOME/.venvs/pygimg/bin/pygmentize"
if [ ! -x "$PYG" ]; then
  if command -v pygmentize >/dev/null 2>&1; then
    PYG="$(command -v pygmentize)"
  else
    echo "❌ pygmentize not found. Install with:"
    echo "   python3 -m venv ~/.venvs/pygimg && \\"
    echo "   ~/.venvs/pygimg/bin/pip install pygments Pillow"
    exit 1
  fi
fi

# Pick ImageMagick command (magick on macOS, convert elsewhere)
if command -v magick >/dev/null 2>&1; then
  IM_CMD=(magick -delay $DELAY -loop 0)
elif command -v convert >/dev/null 2>&1; then
  IM_CMD=(convert -delay $DELAY -loop 0)
else
  echo "❌ ImageMagick not found. Install with: brew install imagemagick"
  exit 1
fi

# Pick ImageMagick identify helper
if command -v magick >/dev/null 2>&1; then
  IDENT_CMD=(magick identify)
elif command -v identify >/dev/null 2>&1; then
  IDENT_CMD=(identify)
else
  echo "❌ ImageMagick 'identify' not found. Install with: brew install imagemagick"
  exit 1
fi

# ---- RENDER PNG FRAMES ----
rm -rf "$OUTDIR" && mkdir -p "$OUTDIR"

# Collect commits that touched the file, oldest -> newest (macOS friendly)
COMMITS=($(git log --format=%H --follow -- "$FILE" | tail -r))

i=0
for c in "${COMMITS[@]}"; do
  # Skip excluded commits (full hash or prefix)
  skip=0
  # Note: EXCLUDE_COMMITS is split on whitespace; this is bash-compatible and avoids zsh-specific expansions.
  for s in $EXCLUDE_COMMITS; do
    if [[ "$c" == ${s}* ]]; then
      skip=1
      break
    fi
  done
  if (( skip )); then
    continue
  fi
  i=$((i+1))
  pad=$(printf "%04d" "$i")
  if git show "${c}:${FILE}" > "$OUTDIR/${pad}.raw.txt" 2>/dev/null; then
    # Optionally hide package/import lines
    # Build dynamic filter to hide imports/package and/or data class lines
    filter_rx=""
    if [ "$HIDE_IMPORTS" = true ]; then
      filter_rx='^[[:space:]]*(package|import)([[:space:]]|$)'
    fi
    if [ "${HIDE_DATA_CLASSES:-false}" = true ]; then
      if [ -n "$filter_rx" ]; then
        filter_rx="${filter_rx}|^[[:space:]]*data[[:space:]]"
      else
        filter_rx='^[[:space:]]*data[[:space:]]'
      fi
    fi
    if [ -n "$filter_rx" ]; then
      grep -Ev "$filter_rx" "$OUTDIR/${pad}.raw.txt" > "$OUTDIR/${pad}.txt"
    else
      cp "$OUTDIR/${pad}.raw.txt" "$OUTDIR/${pad}.txt"
    fi

    # Build Pygments options dynamically (style + optional highlighted lines)
    LN_VAL="False"
    if [ "${SHOW_LINE_NUMBERS:-false}" = true ]; then
      LN_VAL="True"
    fi
    OPTS="line_numbers=${LN_VAL},font_size=${FONT_SIZE}"
    if [ -n "${STYLE:-}" ]; then
      OPTS="${OPTS},style=${STYLE}"
    fi
    if [ -n "${HIGHLIGHT_REGEX:-}" ]; then
      HL_LINES=$(grep -nE "$HIGHLIGHT_REGEX" "$OUTDIR/${pad}.txt" | cut -d: -f1 | tr '\n' ' ' | sed 's/[[:space:]]*$//') || true
      if [ -n "$HL_LINES" ]; then
        OPTS="${OPTS},hl_color=${HIGHLIGHT_COLOR},hl_lines=${HL_LINES}"
      fi
    fi
    # Choose lexer: explicit LEXER if set; else guess (-g)
    if [ -n "${LEXER:-}" ]; then
      "$PYG" -l "$LEXER" -f png -O "$OPTS" -o "$OUTDIR/${pad}.png" "$OUTDIR/${pad}.txt"
    else
      "$PYG" -g -f png -O "$OPTS" -o "$OUTDIR/${pad}.png" "$OUTDIR/${pad}.txt"
    fi
  fi
done

# No frames? Bail out.
if ! ls "$OUTDIR"/*.png >/dev/null 2>&1; then
  echo "❌ No PNG frames generated. Check FILE path: $FILE"
  exit 1
fi

# ---- NORMALIZE CANVAS (avoid cropping if frames have different sizes) ----
MAXW=$(${IDENT_CMD[@]} -format "%w\n" "$OUTDIR"/*.png | sort -nr | head -n1)
MAXH=$(${IDENT_CMD[@]} -format "%h\n" "$OUTDIR"/*.png | sort -nr | head -n1)
for img in $(ls "$OUTDIR"/*.png | sort); do
  magick "$img" -background "$BG_COLOR" -gravity northwest -extent ${MAXW}x${MAXH} "$img"
done

# ---- OPTIONAL: HOLD ON THE LAST FRAME BY DUPLICATING IT ----
if [ "${LAST_HOLD_SECS:-0}" -gt 0 ]; then
  # Calculate how many extra frames approximate the requested hold time
  extra=$(( (LAST_HOLD_SECS*100)/DELAY ))
  if [ $extra -lt 1 ]; then
    extra=1
  fi
  last=$(ls "$OUTDIR"/*.png | sort | tail -n1)
  n=0
  while [ $n -lt $extra ]; do
    n=$((n+1))
    i=$((i+1))
    pad=$(printf "%04d" "$i")
    cp "$last" "$OUTDIR/${pad}.png"
  done
fi

# ---- MAKE THE GIF ----
if [ -n "$RESIZE" ]; then
  "${IM_CMD[@]}" "$OUTDIR"/*.png -resize "$RESIZE" code-evolution.gif
else
  "${IM_CMD[@]}" "$OUTDIR"/*.png code-evolution.gif
fi

echo "✅ Done: code-evolution.gif (frames: $i, delay=$DELAY)"