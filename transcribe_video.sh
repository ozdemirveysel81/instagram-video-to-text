#!/bin/bash
# transcribe_video.sh
# Downloads Instagram videos (kept as mp4) and transcribes them with Whisper.
#
# Usage:
#   1. Put one Instagram link per line in links.txt
#   2. Run: bash transcribe_video.sh

# ---------- SETTINGS (edit if needed) ----------
BROWSER="chrome"           # chrome, safari or firefox (the browser where you are logged in to Instagram)
MODEL="small"              # tiny, base, small, medium (larger = more accurate but slower)
SPOKEN_LANGUAGE="Turkish"  # language spoken in the videos, e.g. Turkish, English
FORMATS="txt"              # output formats, separated by spaces: txt srt vtt tsv json
                           # examples: FORMATS="txt"   FORMATS="srt"   FORMATS="txt srt vtt"
COMPATIBLE_MP4="yes"       # "yes": make sure every video is H.264/AAC so it plays in QuickTime, iPhone, etc.
                           #        (videos in other codecs are converted automatically, this can take a while)
                           # "no":  keep the files exactly as downloaded
# -----------------------------------------------

cd "$(dirname "$0")" || exit 1

LINKS_FILE="links.txt"
MEDIA_DIR="videos"
OUT_DIR="transcripts"
COMBINED="$OUT_DIR/all_transcripts.txt"

# Are the required tools installed?
for TOOL in yt-dlp ffmpeg ffprobe whisper; do
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

# Converts a video to H.264 + AAC if it uses another codec (for example VP9 or AV1),
# so that it opens in QuickTime, on iPhone, in video editors, etc.
make_compatible() {
  local FILE="$1" VCODEC PIXFMT ACODEC TMP
  VCODEC="$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$FILE" 2>/dev/null)"
  PIXFMT="$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of csv=p=0 "$FILE" 2>/dev/null)"
  ACODEC="$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$FILE" 2>/dev/null)"

  if [ "$VCODEC" = "h264" ] && [ "$PIXFMT" = "yuv420p" ] && { [ -z "$ACODEC" ] || [ "$ACODEC" = "aac" ]; }; then
    return 0
  fi

  echo "Converting to a compatible format (H.264/AAC): $(basename "$FILE") [video: ${VCODEC:-unknown}, audio: ${ACODEC:-none}]"
  TMP="${FILE%.mp4}.compat.tmp.mp4"
  if ffmpeg -y -loglevel error -i "$FILE" \
      -c:v libx264 -pix_fmt yuv420p -crf 20 -preset medium \
      -c:a aac -b:a 160k -movflags +faststart "$TMP" </dev/null; then
    mv "$TMP" "$FILE"
  else
    echo "WARNING: conversion failed, keeping the original file: $FILE"
    rm -f "$TMP"
  fi
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
  echo "Downloading video..."

  # -S prefers H.264 video and AAC audio, which play almost everywhere
  if ! yt-dlp --cookies-from-browser "$BROWSER" \
      -f "bv*+ba/b" -S "vcodec:h264,res,acodec:aac" --merge-output-format mp4 \
      -o "$MEDIA_DIR/${NAME}_%(autonumber)s.%(ext)s" "$URL" </dev/null; then
    echo "WARNING: could not download, skipping: $URL"
    echo "[$COUNTER] DOWNLOAD FAILED: $URL" >> "$COMBINED"
    echo "" >> "$COMBINED"
    FAILED=$((FAILED + 1))
    continue
  fi

  for VIDEO in "$MEDIA_DIR/${NAME}_"*.mp4; do
    [ -f "$VIDEO" ] || continue
    echo "Transcribing: $(basename "$VIDEO")"
    whisper "$VIDEO" --language "$SPOKEN_LANGUAGE" --model "$MODEL" \
      --output_format all --output_dir "$OUT_DIR" --fp16 False </dev/null

    ITEM="$(basename "${VIDEO%.mp4}")"
    BASE="$OUT_DIR/$ITEM"
    if [ -f "$BASE.txt" ]; then
      {
        echo "=============================="
        echo "[$COUNTER] $URL"
        echo "Video: $MEDIA_DIR/$ITEM.mp4"
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

    if [ "$COMPATIBLE_MP4" = "yes" ]; then
      make_compatible "$VIDEO"
    fi
  done
done 3< "$LINKS_FILE"

echo ""
echo "Done. Successful: $SUCCESS, Failed: $FAILED"
echo "Videos folder: $MEDIA_DIR/"
echo "Transcripts folder: $OUT_DIR/"
echo "All texts in one file: $COMBINED"
