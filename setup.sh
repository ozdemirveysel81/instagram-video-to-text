#!/bin/bash
# setup.sh
# Installs the required tools with Homebrew: yt-dlp, ffmpeg, openai-whisper
#
# Usage:
#   bash setup.sh

if ! command -v brew >/dev/null 2>&1; then
  echo "ERROR: Homebrew is not installed."
  echo "First run the one-line install command on https://brew.sh,"
  echo "then run this script again."
  exit 1
fi

echo "Installing required tools: yt-dlp, ffmpeg, openai-whisper"
echo "(This may take a few minutes.)"
echo ""

if ! brew install yt-dlp ffmpeg openai-whisper; then
  echo ""
  echo "ERROR: Installation could not be completed. Check the error message above."
  exit 1
fi

echo ""
echo "Installation complete."
echo ""
echo "Next steps:"
echo "  1. cp links.example.txt links.txt"
echo "  2. Add your Instagram links to links.txt (one link per line)"
echo "  3. bash transcribe.sh   (or transcribe_video.sh / download_video.sh)"
