#!/bin/bash
# download_video.sh
# Only downloads Instagram videos (mp4). No transcription.
#
# Usage:
#   1. Put one Instagram link per line in links.txt
#   2. Run: bash download_video.sh

# ---------- SETTINGS (edit if needed) ----------
BROWSER="chrome"   # chrome, safari or firefox (the browser where you are logged in to Instagram)
# -----------------------------------------------

cd "$(dirname "$0")" || exit 1

LINKS_FILE="links.txt"
MEDIA_DIR="videos"

# Are the required tools installed?
for TOOL in yt-dlp ffmpeg; do
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

  if yt-dlp --cookies-from-browser "$BROWSER" \
      -f "bv*+ba/b" --merge-output-format mp4 \
      -o "$MEDIA_DIR/${NAME}_%(autonumber)s.%(ext)s" "$URL" </dev/null; then
    SUCCESS=$((SUCCESS + 1))
  else
    echo "WARNING: could not download, skipping: $URL"
    FAILED=$((FAILED + 1))
  fi
done 3< "$LINKS_FILE"

echo ""
echo "Done. Successful: $SUCCESS, Failed: $FAILED"
echo "Videos folder: $MEDIA_DIR/"
