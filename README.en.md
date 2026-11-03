# Instagram Video to Text: Batch Reel & Video Transcriber (Whisper)

**English** | [Türkçe](README.md)

A free, local set of macOS Terminal scripts that transcribes Instagram videos and Reels to text, processing multiple links in one run. Turkish is the default language, but Whisper supports many more.

Put your links in a `links.txt` file and run a script. The video or audio is downloaded, transcribed locally with [OpenAI Whisper](https://github.com/openai/whisper), and all results are collected in a single `all_transcripts.txt` file. You can also get subtitle files (`.srt`, `.vtt`).

> **Note:** This project is not affiliated with Instagram, Meta, OpenAI or yt-dlp. See the [Legal notice](#legal-notice-and-responsibility).

---

## Contents

- [What it does](#what-it-does)
- [Which script does what](#which-script-does-what)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Settings](#settings)
- [Output formats](#output-formats)
- [Output structure](#output-structure)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Optional: using it with Claude](#optional-using-it-with-claude)
- [Legal notice and responsibility](#legal-notice-and-responsibility)
- [License](#license)

---

## What it does

- Processes multiple Instagram links (Reels and video posts) one after another.
- Transcribes speech to text. Turkish is the default; Whisper supports 99 languages, so you can change the language in the settings.
- Outputs plain text (`txt`), subtitles (`srt`, `vtt`), `tsv` or `json`.
- Writes one file per video, plus a combined `all_transcripts.txt` file.
- If a link cannot be downloaded, it does not stop: it skips that link and adds a note to the results file.
- Everything runs **on your own computer**. Whisper runs locally, so your audio and text are not sent to a third-party transcription service.

## Which script does what

| Script | Downloads | Transcribes | Keeps files |
|---|---|---|---|
| `transcribe.sh` | Audio only (mp3) | Yes | Audio is deleted by default (configurable) |
| `transcribe_video.sh` | Video (mp4) | Yes | Video is kept |
| `download_video.sh` | Video (mp4) | No | Video is kept |
| `setup.sh` | - | - | Installs the required tools |

If you are unsure: use `transcribe.sh` for text only, `transcribe_video.sh` for video and text, and `download_video.sh` for video only.

## Requirements

- **macOS** (written for Mac; it should work similarly on Linux but has not been tested)
- [Homebrew](https://brew.sh)
- These tools (installed automatically by the setup script):
  - [`yt-dlp`](https://github.com/yt-dlp/yt-dlp): downloads the video
  - [`ffmpeg`](https://ffmpeg.org): processes audio/video
  - [`openai-whisper`](https://github.com/openai/whisper): speech to text
- A browser (Chrome, Safari or Firefox) where you are logged in to Instagram. Instagram blocks most content for logged-out requests, so the scripts read your login cookie from the browser.
- Enough free disk space. Whisper downloads its model on first use (approx. `small` ≈ 0.5 GB, `medium` ≈ 1.5 GB), and videos take space too.

## Installation

### 1. Get the project

With Git:

```bash
git clone https://github.com/ozdemirveysel81/instagram-video-to-text.git
cd instagram-video-to-text
```

Without Git: click the green **Code** button on the GitHub page, choose **Download ZIP**, and unzip it.

### 2. Install the required tools

If Homebrew is not installed, first install it using the one-line command on [brew.sh](https://brew.sh). Then, in the project folder:

```bash
bash setup.sh
```

This runs:

```bash
brew install yt-dlp ffmpeg openai-whisper
```

You can also paste that command into Terminal yourself.

### 3. Prepare your links

Copy `links.example.txt` to `links.txt` and fill it with your links:

```bash
cp links.example.txt links.txt
open -e links.txt
```

One link per line. Lines starting with `#` are ignored.

```
https://www.instagram.com/p/XXXXXXXXXXX/
https://www.instagram.com/reel/YYYYYYYYYYY/
# This line is ignored
```

## Usage

In Terminal, go to the project folder and run the script you want:

```bash
cd ~/Desktop/instagram-video-to-text

# Text only (downloads audio, transcribes):
bash transcribe.sh

# Video and text:
bash transcribe_video.sh

# Video only:
bash download_video.sh
```

> Running `bash script_name.sh` avoids "permission denied" errors. To run a script directly as `./transcribe.sh`, run `chmod +x *.sh` once first.

**First run:** Whisper downloads the chosen model the first time. This can take a few minutes, and nothing may seem to happen for a while. That is normal.

**Many links:** Instagram may temporarily rate-limit access after many consecutive requests. It is safer to split long lists into smaller batches.

## Settings

Edit the `SETTINGS` section at the top of each script with any text editor.

| Setting | Values | Description |
|---|---|---|
| `BROWSER` | `chrome`, `safari`, `firefox` | The browser where you are logged in to Instagram |
| `MODEL` | `tiny`, `base`, `small`, `medium` | Larger models are more accurate but slower. `small` is a good balance for Turkish; `medium` is more accurate |
| `SPOKEN_LANGUAGE` | `Turkish`, `English`, etc. | Language spoken in the videos |
| `FORMATS` | `txt`, `srt`, `vtt`, `tsv`, `json` | Output formats. Separate several with spaces |
| `DELETE_AUDIO` | `yes`, `no` | Only in `transcribe.sh`: whether to delete mp3 files when done |

Example: to keep audio files, change this line in `transcribe.sh`:

```bash
DELETE_AUDIO="no"
```

## Output formats

The `FORMATS` setting chooses which files are kept:

| Format | Contents | Use it for |
|---|---|---|
| `txt` | Plain text | Reading, copying, summarizing |
| `srt` | Timestamped subtitles | Adding subtitles to a video, editing software |
| `vtt` | Timestamped subtitles (web) | Subtitles in web video players |
| `tsv` | Table (start, end, text) | Opening in Excel/Numbers |
| `json` | Detailed data | Processing in your own code |

Examples (in the settings at the top of the script):

```bash
FORMATS="txt"          # plain text only (default)
FORMATS="srt"          # subtitles only
FORMATS="txt srt vtt"  # all three
```

Whatever you choose, `transcripts/all_transcripts.txt` is always created: it collects the plain text of every video together with its link.

## Output structure

After a run, the project folder contains:

```
instagram-video-to-text/
├── videos/                # mp4 files (transcribe_video.sh and download_video.sh)
├── audio/                 # mp3 files (transcribe.sh, kept if DELETE_AUDIO="no")
└── transcripts/
    ├── 01_XXXXXXXXXXX_00001.txt   # one file per video (in the formats you chose)
    ├── 01_XXXXXXXXXXX_00001.srt
    ├── 02_YYYYYYYYYYY_00001.txt
    └── all_transcripts.txt        # all texts in one file, with their links
```

File names consist of a running number and the post code. For posts containing several videos (carousels), each video gets its own file.

## Troubleshooting

**`'yt-dlp' is not installed` / `command not found`**
Run the setup: `bash setup.sh`

**Instagram returns "login required", "empty media response" or similar**
- Make sure you are logged in to Instagram in the browser you selected.
- Check that `BROWSER` points to the right browser.
- Update yt-dlp: `brew upgrade yt-dlp`. Instagram changes often and old versions may stop working.
- If you tried many links in a row, wait a while and shorten the list.

**`invalid format`**
In `FORMATS` you can only use: `txt srt vtt tsv json`. Separate several with spaces.

**Chrome: macOS asks for Keychain access**
To read browser cookies, macOS may show a permission prompt. If the request comes from the script you are running on your own computer, you can allow it.

**Safari: permission error**
Go to System Settings > Privacy & Security > Full Disk Access, allow Terminal, then quit and reopen Terminal.

**`No video formats found`**
The post may contain only photos. Posts without video or audio cannot be downloaded.

**Whisper is very slow**
Set `MODEL` to `base` or `tiny`. Accuracy drops, speed improves.

**Many mistakes in the transcript**
Try `MODEL="medium"`. Videos with loud background music produce more errors.

**`permission denied`**
Run `bash transcribe.sh`, or run `chmod +x *.sh` once.

## FAQ

**Is my data sent anywhere?**
In this setup Whisper runs locally on your computer; audio and text are not sent to a third-party service. Downloading the video naturally connects to Instagram.

**Does it use my account password?**
No. The scripts never ask for a password. They only pass the cookies of the session that is already open in your browser to yt-dlp.

**Can I get subtitle files (SRT/VTT)?**
Yes. Set `FORMATS` at the top of the script to `srt` or `vtt`. See [Output formats](#output-formats).

**Does it work on Windows?**
The scripts are written for bash and Homebrew. They may work under WSL but this has not been tested.

**How accurate is the transcript?**
Whisper is strong but can make mistakes, especially with proper names, poor audio quality and speech over music. Review the output before relying on it.

**What happens if I run the same links again?**
File names contain a running number, so nothing is overwritten; a separate copy may be created. To avoid processing the same video twice, put only new links in `links.txt`.

## Optional: using it with Claude

Running the scripts from Terminal does not use Claude at all. If you want, you can open this folder in the **Code** tab of the Claude Desktop app and ask it to run `transcribe_video.sh`. In that case Claude usage counts toward your subscription limits. For routine use, plain Terminal is enough.

## Legal notice and responsibility

- This tool is shared for **personal use and learning** only.
- Videos and the speech in them belong to their creators and may be protected by copyright. We recommend using it only for **your own content or content you have the right to use**.
- Instagram's [Terms of Use](https://help.instagram.com/581066165581870) may restrict downloading content or automated access. Complying with them is your responsibility.
- Downloading, storing, republishing or processing personal data from other people's content without permission may have legal consequences. Pay attention to the laws in your country (for example copyright and data protection laws).
- This project has no official connection with Instagram, Meta, OpenAI or yt-dlp. If Instagram changes its structure, the tool may stop working.
- The software is provided "as is", without warranty of any kind. The author cannot be held liable for any problems arising from its use.

## License

Released under the [MIT License](LICENSE).

## Acknowledgements

This project builds on these open-source projects: [yt-dlp](https://github.com/yt-dlp/yt-dlp), [FFmpeg](https://ffmpeg.org) and [OpenAI Whisper](https://github.com/openai/whisper).
