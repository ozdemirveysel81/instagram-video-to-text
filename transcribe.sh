#!/bin/bash
# transcribe.sh
# Downloads only the AUDIO of Instagram videos and transcribes it with Whisper.
#
# Usage:
#   1. Put one Instagram link per line in links.txt
#   2. Run: bash transcribe.sh

# ---------- SETTINGS (edit if needed) ----------
BROWSER="chrome"           # chrome, safari or firefox (the browser where you are logged in to Instagram)
MODEL="small"              # tiny, base, small, medium (larger = more accurate but slower)
SPOKEN_LANGUAGE="Turkish"  # language spoken in the videos, e.g. Turkish, English
FORMATS="txt"              # output formats, separated by spaces: txt srt vtt tsv json
                           # examples: FORMATS="txt"   FORMATS="srt"   FORMATS="txt srt vtt"
DELETE_AUDIO="yes"         # "yes": delete the mp3 files when done, "no": keep them
# -----------------------------------------------

cd "$(dirname "$0")" || exit 1

LINKS_FILE="links.txt"
MEDIA_DIR="audio"
OUT_DIR="transcripts"
COMBINED="$OUT_DIR/all_transcripts.txt"

# Are the required tools installed?
for TOOL in yt-dlp ffmpeg whisper; do
  if ! command -v "$TOOL" >/dev/null 2>&1; then
    echo "ERROR: '$TOOL' is not installed. Run this first:"
    echo "  bash setup.sh"
    exit 1
  fi
done

if [ ! -f "$LINKS_FILE" ]; then
  echo "ERROR: $LINKS_FILE not found. Copy links.example.txt to links.txt and add one link per line."
  exit 1
fi

# Are the chosen formats valid?
if [ -z "$FORMATS" ]; then
  echo "ERROR: FORMATS is empty. Use one or more of: txt srt vtt tsv json"
  exit 1
fi
for F in $FORMATS; do
  case "$F" in
    txt|srt|vtt|tsv|json) ;;
    *) echo "ERROR: invalid format '$F'. Use one or more of: txt srt vtt tsv json"; exit 1 ;;
  esac
done

# Deletes the output files that were not requested in FORMATS
prune_formats() {
  for EXT in txt vtt srt tsv json; do
    case " $FORMATS " in
      *" $EXT "*) ;;
      *) rm -f "$1.$EXT" ;;
    esac
  done
}

mkdir -p "$MEDIA_DIR" "$OUT_DIR"
: > "$COMBINED"

COUNTER=0
SUCCESS=0
FAILED=0

# Links are read from file descriptor 3 so that yt-dlp and whisper cannot swallow the list
while IFS= read -r URL <&3 || [ -n "$URL" ]; do
  # Skip empty lines and lines starting with #
  URL="$(printf '%s' "$URL" | tr -d '\r' | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
  [ -z "$URL" ] && continue
  case "$URL" in \#*) continue ;; esac

  COUNTER=$((COUNTER + 1))
  CODE="$(echo "$URL" | sed -E 's#.*/(p|reel|reels|tv)/([^/?]+).*#\2#')"
  NAME="$(printf "%02d" "$COUNTER")_$CODE"

  echo ""
  echo "=== [$COUNTER] $URL ==="
  echo "Downloading audio..."

  if ! yt-dlp --cookies-from-browser "$BROWSER" -x --audio-format mp3 \
      -o "$MEDIA_DIR/${NAME}_%(autonumber)s.%(ext)s" "$URL" </dev/null; then
    echo "WARNING: could not download, skipping: $URL"
    echo "[$COUNTER] DOWNLOAD FAILED: $URL" >> "$COMBINED"
    echo "" >> "$COMBINED"
    FAILED=$((FAILED + 1))
    continue
  fi

  for AUDIO in "$MEDIA_DIR/${NAME}_"*.mp3; do
    [ -f "$AUDIO" ] || continue
    echo "Transcribing: $(basename "$AUDIO")"
    whisper "$AUDIO" --language "$SPOKEN_LANGUAGE" --model "$MODEL" \
      --output_format all --output_dir "$OUT_DIR" --fp16 False </dev/null

    BASE="$OUT_DIR/$(basename "${AUDIO%.mp3}")"
    if [ -f "$BASE.txt" ]; then
      {
        echo "=============================="
        echo "[$COUNTER] $URL"
        echo "=============================="
        cat "$BASE.txt"
        echo ""
        echo ""
      } >> "$COMBINED"
      SUCCESS=$((SUCCESS + 1))
    else
      echo "[$COUNTER] TRANSCRIPTION FAILED: $URL" >> "$COMBINED"
      FAILED=$((FAILED + 1))
    fi

    prune_formats "$BASE"

    if [ "$DELETE_AUDIO" = "yes" ]; then
      rm -f "$AUDIO"
    fi
  done
done 3< "$LINKS_FILE"

echo ""
echo "Done. Successful: $SUCCESS, Failed: $FAILED"
echo "Transcripts folder: $OUT_DIR/"
echo "All texts in one file: $COMBINED"
