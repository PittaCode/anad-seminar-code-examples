#!/usr/bin/env bash
set -euo pipefail

# ---- SETTINGS ----
FILE="src/main/kotlin/com/pittacode/badcode/MovieTicketCalculation.kt"
OUTDIR="/tmp/codegif"
DELAY=50          # 100 => ~1s per frame. Increase for slower.
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
LAST_HOLD_SECS=4    # seconds to hold on the final frame; set 0 to disable
EXCLUDE_COMMITS="a6cc63"   # space-separated commit hashes or prefixes to exclude (e.g., abc123 def456)

# ---- LOGGING & HELPERS ----
log() { printf '[codegif] %s\n' "$*" >&2; }
die() { echo "❌ $*" >&2; exit 1; }

# Prefer venv pygmentize if it exists, else fallback to system
pick_pygmentize() {
  PYG="$HOME/.venvs/pygimg/bin/pygmentize"
  if [ ! -x "$PYG" ]; then
    if command -v pygmentize >/dev/null 2>&1; then
      PYG="$(command -v pygmentize)"
    else
      echo "❌ pygmentize not found. Install with:" >&2
      echo "   python3 -m venv ~/.venvs/pygimg && \\" >&2
      echo "   ~/.venvs/pygimg/bin/pip install pygments Pillow" >&2
      exit 1
    fi
  fi
}

# Pick ImageMagick commands (magick/convert and identify)
pick_imagemagick() {
  if command -v magick >/dev/null 2>&1; then
    IM_BIN=magick
    IM_CMD=(magick -delay "$DELAY" -loop 0)
  elif command -v convert >/dev/null 2>&1; then
    IM_BIN=convert
    IM_CMD=(convert -delay "$DELAY" -loop 0)
  else
    die "ImageMagick not found. Install with: brew install imagemagick"
  fi

  if command -v magick >/dev/null 2>&1; then
    IDENT_CMD=(magick identify)
  elif command -v identify >/dev/null 2>&1; then
    IDENT_CMD=(identify)
  else
    die "ImageMagick 'identify' not found. Install with: brew install imagemagick"
  fi
}

# Build Pygments options string (style, line numbers, highlights)
build_pygment_opts() {
  local ln_val="False"
  if [ "${SHOW_LINE_NUMBERS:-false}" = true ]; then
    ln_val="True"
  fi
  local opts="line_numbers=${ln_val},font_size=${FONT_SIZE}"
  if [ -n "${STYLE:-}" ]; then
    opts="${opts},style=${STYLE}"
  fi
  # Optionally add highlighted lines
  if [ -n "${HIGHLIGHT_REGEX:-}" ]; then
    local hl_lines
    hl_lines=$(grep -nE "$HIGHLIGHT_REGEX" "$1" | cut -d: -f1 | tr '\n' ' ' | sed 's/[[:space:]]*$//') || true
    if [ -n "$hl_lines" ]; then
      opts="${opts},hl_color=${HIGHLIGHT_COLOR},hl_lines=${hl_lines}"
    fi
  fi
  printf '%s' "$opts"
}

# Filter source text according to settings (imports, data classes)
filter_source_if_needed() {
  local in_file="$1" out_file="$2" filter_rx=""
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
    grep -Ev "$filter_rx" "$in_file" > "$out_file"
  else
    cp "$in_file" "$out_file"
  fi
}

# Render PNG frames for each commit touching FILE
render_png_frames() {
  rm -rf "$OUTDIR" && mkdir -p "$OUTDIR"

  local i=0
  # Stream commits that touched the file, oldest -> newest (macOS friendly)
  while IFS= read -r c; do
    # Skip excluded commits (full hash or prefix)
    local skip=0
    for s in $EXCLUDE_COMMITS; do
      if [[ "$c" == ${s}* ]]; then
        skip=1; break
      fi
    done
    if (( skip )); then
      continue
    fi

    i=$((i+1))
    local pad
    pad=$(printf "%04d" "$i")

    if git show "${c}:${FILE}" > "$OUTDIR/${pad}.raw.txt" 2>/dev/null; then
      filter_source_if_needed "$OUTDIR/${pad}.raw.txt" "$OUTDIR/${pad}.txt"

      local opts
      opts=$(build_pygment_opts "$OUTDIR/${pad}.txt")

      if [ -n "${LEXER:-}" ]; then
        "$PYG" -l "$LEXER" -f png -O "$opts" -o "$OUTDIR/${pad}.png" "$OUTDIR/${pad}.txt"
      else
        "$PYG" -g -f png -O "$opts" -o "$OUTDIR/${pad}.png" "$OUTDIR/${pad}.txt"
      fi
    fi
  done < <(git log --format=%H --follow -- "$FILE" | tail -r)

  # Export i for later steps (last-frame hold and message)
  FRAMES_RENDERED="$i"
}

# Ensure PNG frames exist
ensure_frames_present() {
  if ! compgen -G "$OUTDIR/*.png" >/dev/null; then
    die "No PNG frames generated. Check FILE path: $FILE"
  fi
}

# Normalize canvas to avoid cropping when frames differ in size
normalize_canvas() {
  local maxw maxh
  maxw=$(${IDENT_CMD[@]} -format "%w\n" "$OUTDIR"/*.png | sort -nr | head -n1)
  maxh=$(${IDENT_CMD[@]} -format "%h\n" "$OUTDIR"/*.png | sort -nr | head -n1)

  # Process files in lexicographical order
  while IFS= read -r img; do
    [ -n "$img" ] || continue
    "$IM_BIN" "$img" -background "$BG_COLOR" -gravity northwest -extent "${maxw}x${maxh}" "$img"
  done < <(printf "%s\n" "$OUTDIR"/*.png | sort)
}

# Optionally duplicate last frame to hold on it for a few seconds
hold_on_last_frame() {
  local last extra n pad
  if [ "${LAST_HOLD_SECS:-0}" -gt 0 ]; then
    extra=$(( (LAST_HOLD_SECS*100)/DELAY ))
    if [ "$extra" -lt 1 ]; then extra=1; fi
    last=$(printf "%s\n" "$OUTDIR"/*.png | sort | tail -n1)
    n=0
    while [ "$n" -lt "$extra" ]; do
      n=$((n+1))
      FRAMES_RENDERED=$((FRAMES_RENDERED+1))
      pad=$(printf "%04d" "$FRAMES_RENDERED")
      cp "$last" "$OUTDIR/${pad}.png"
    done
  fi
}

# Assemble the GIF from PNG frames
assemble_gif() {
  if [ -n "$RESIZE" ]; then
    "${IM_CMD[@]}" "$OUTDIR"/*.png -resize "$RESIZE" code-evolution.gif
  else
    "${IM_CMD[@]}" "$OUTDIR"/*.png code-evolution.gif
  fi
}

main() {
  pick_pygmentize
  pick_imagemagick
  render_png_frames
  ensure_frames_present
  normalize_canvas
  hold_on_last_frame
  assemble_gif
  echo "✅ Done: code-evolution.gif (frames: ${FRAMES_RENDERED:-0}, delay=$DELAY)"
}

main "$@"