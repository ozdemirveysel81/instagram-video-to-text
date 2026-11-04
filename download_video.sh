#!/bin/bash
# download_video.sh
# Only downloads Instagram videos (mp4). No transcription.
#
# Usage:
#   1. Put one Instagram link per line in links.txt
#   2. Run: bash download_video.sh

# ---------- SETTINGS (edit if needed) ----------
BROWSER="chrome"        # chrome, safari or firefox (the browser where you are logged in to Instagram)
COMPATIBLE_MP4="yes"    # "yes": make sure every video is H.264/AAC so it plays in QuickTime, iPhone, etc.
                        #        (videos in other codecs are converted automatically, this can take a while)
                        # "no":  keep the files exactly as downloaded
# -----------------------------------------------

cd "$(dirname "$0")" || exit 1

LINKS_FILE="links.txt"
MEDIA_DIR="videos"

# Are the required tools installed?
for TOOL in yt-dlp ffmpeg ffprobe; do
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

mkdir -p "$MEDIA_DIR"

COUNTER=0
SUCCESS=0
FAILED=0

# Links are read from file descriptor 3 so that yt-dlp cannot swallow the list
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
  if yt-dlp --cookies-from-browser "$BROWSER" \
      -f "bv*+ba/b" -S "vcodec:h264,res,acodec:aac" --merge-output-format mp4 \
      -o "$MEDIA_DIR/${NAME}_%(autonumber)s.%(ext)s" "$URL" </dev/null; then
    SUCCESS=$((SUCCESS + 1))
    if [ "$COMPATIBLE_MP4" = "yes" ]; then
      for VIDEO in "$MEDIA_DIR/${NAME}_"*.mp4; do
        [ -f "$VIDEO" ] || continue
        make_compatible "$VIDEO"
      done
    fi
  else
    echo "WARNING: could not download, skipping: $URL"
    FAILED=$((FAILED + 1))
  fi
done 3< "$LINKS_FILE"

echo ""
echo "Done. Successful: $SUCCESS, Failed: $FAILED"
echo "Videos folder: $MEDIA_DIR/"
