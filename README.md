# cinnamon-aerial-saver

An Apple-TV-style **Aerial** video screensaver for Linux Mint / Cinnamon that plays
**one** high-bitrate video stretched across **all** monitors from a single decoder,
with independently configurable video, lock, and display-off timers.

![platform](https://img.shields.io/badge/platform-Linux%20Mint%20%2F%20Cinnamon-blue)
![license](https://img.shields.io/badge/license-VibeCoded%20AI--Slop%20v1.0-purple)

![AI slop](https://img.shields.io/badge/AI%20slop-100%25-red)

![quality](https://img.shields.io/badge/quality-none%20whatsoever-lightgrey)

> [!CAUTION]
> **AI-generated slop — do not use.** This exists as a personal workaround, not as
> software. Read it for ideas if you like; do not expect it to work, be maintained,
> or be correct. Any resemblance to functioning software is coincidental.
>
> **The smart thing to do is never to use it for any reason.** It is published only
> because it works on exactly one computer and that computer belongs to the author.
> If you run it and something breaks, that is the expected outcome.

---

## Why

Cinnamon's built-in screensaver (and xscreensaver) place a *separate* window on each
monitor. With four monitors you get four copies of the same video, each scaled down,
each decoded independently — so they stutter and drift out of sync, and neither tool
offers independent "saver delay / lock delay / screen-off delay" controls.

`aerial-saver` instead launches a single `mpv` process into one window that spans the
whole virtual desktop. One decode, no scaling when the desktop matches the source
resolution, and no drift between monitors.

## Features

- **One 4K instance across N monitors** — single window, single decoder
- **Auto-detecting geometry** — spans whatever the current desktop is, at native
  resolution on a single display
- **Three independent timers** — video start, lock, and monitor power-off
- **Cinnamon's own locker** for the lock stage (Super+L keeps working)
- **Single config file** — one plain-text file drives everything
- **Panel auto-hide** while the video plays, restored on wake
- Optional: skip the video unless a minimum number of monitors is active

## Requirements

- Linux Mint (or any Cinnamon desktop) on **X11**
- `mpv` and `xprintidle` — installed automatically by `install.sh`
- `xrandr` / `xdpyinfo` — part of `x11-xserver-utils`, present by default
- Python 3 and `git` — only for the one-time video download (see below)

---

## Quick start

```bash
git clone https://github.com/SimplifyAndAddCoffee/cinnamon-aerial-saver.git
cd cinnamon-aerial-saver
./install.sh
```

Then download the videos (next section), point the config at the folder, and start it:

```bash
~/.local/bin/aerial-saver &
```

It also launches automatically at every login via `~/.config/autostart/`.

---

## Getting the Aerial video files

The video files are downloaded with the loader script from the upstream project
**[Chronosaurus42/Aerial-Screensaver-Linux](https://github.com/Chronosaurus42/Aerial-Screensaver-Linux)**.
`aerial_loader.py` fetches Apple's aerial videos from Apple's servers and writes them
to the folder you run it from [^4e3900#20-34].

### 1. Install the download prerequisites

```bash
sudo apt install python3 git
```

(The upstream project also lists `mplayer` and `xscreensaver` as dependencies, but
`aerial-saver` uses **mpv** and does not need either of those.)

### 2. Clone the loader repo

```bash
git clone https://github.com/Chronosaurus42/Aerial-Screensaver-Linux.git
```

### 3. Create your video folder and copy the loader into it

```bash
mkdir -p ~/Videos/Screensaver-SDR
cp Aerial-Screensaver-Linux/aerial_loader.py ~/Videos/Screensaver-SDR/
cd ~/Videos/Screensaver-SDR
```

### 4. Choose the quality, then run it

Open `aerial_loader.py` and set the download quality. The script exposes this mapping
[^4e3900#20-34]:

```python
video_quality = {0: "url-1080-H264",
                 1: "url-1080-SDR",
                 2: "url-1080-HDR",
                 3: "url-4K-SDR",
                 4: "url-4K-HDR"}
# used quality for download
download_video_quality = 3   # 3 = 4K SDR  <-- recommended
# used quality for stream
stream_video_quality = 1
```

Set `download_video_quality = 3` for 4K SDR — that is the format this project expects,
since the desktop spans exactly 3840×2160 with a 2×2 grid of 1080p panels. Then run:

```bash
python3 aerial_loader.py
```

> **Tip:** to download only (no streaming setup), leave the other files untouched —
> you only need the `.mov` files in this folder. The loader will write them alongside
> the script.

### 5. Point the config at the folder

In `~/.config/aerial-saver/config`, set:

```bash
VIDEOS="$HOME/Videos/Screensaver-SDR"
```

That's it — `aerial-saver` scans this folder for `mov`, `mp4`, and `m4v` files.

### Notes

- Each video is first written fully to RAM before being written to disk, so keep an eye
  on memory on low-RAM machines [^4e3900#65-69].
- The full aerial set is large (several GB at 4K). You can start with just a few files;
  the screensaver will loop whatever is present.
- The upstream project supports both download and live streaming modes; this project
  uses the local files only.

---

## Configuration

Edit `~/.config/aerial-saver/config`:

| Key | Default | Meaning |
|---|---|---|
| `SAVER_AFTER` | `300` | Seconds idle before the video starts |
| `LOCK_AFTER` | `900` | Seconds idle before locking (`0` = never) |
| `DPMS_AFTER` | `1500` | Seconds idle before monitors power off (`0` = never) |
| `VIDEOS` | `~/Videos/Screensaver-SDR` | Folder containing your videos |
| `EXTENSIONS` | `mov mp4 m4v` | File extensions to include |
| `GEOMETRY` | `auto` | `auto` spans the whole desktop; or a fixed `WxH+X+Y` |
| `MIN_MONITORS` | `1` | Only start the video when at least this many monitors are active |
| `MPV_EXTRA` | `--hwdec=auto-safe --profile=gpu-hq` | Extra mpv flags |
| `HIDE_PANEL` | `yes` | Hide the Cinnamon panel while playing |
| `POLL` | `2` | Idle-check interval, seconds |

After editing, restart the daemon:

```bash
pkill -f aerial-saver && ~/.local/bin/aerial-saver &
```

---

## How it works

1. Every `POLL` seconds the script reads the X idle time with `xprintidle`.
2. At `SAVER_AFTER` it launches **one** `mpv` window sized to the whole desktop
   (`--geometry="$(xdpyinfo | awk '/dimensions:/{print $2}')+0+0"`), hides the panel,
   and loops the playlist forever.
3. At `LOCK_AFTER` it stops the video and calls `cinnamon-screensaver-command -l`.
4. At `DPMS_AFTER` it calls `xset dpms force off`.
5. Any input resets everything back to idle.

---

## Display layouts

`GEOMETRY="auto"` reads the root-window size, which is the bounding box of all
monitors. With a 2×2 grid of 1080p panels that is exactly 3840×2160, so a 4K source
maps 1:1 with no scaling. On a single laptop panel it is simply that panel's native
resolution. No edits are needed when you dock or undock.

Set `MIN_MONITORS=4` if you want the video **only** on the full four-monitor setup.
When fewer monitors are active, the video stage is skipped but the lock and
power-off stages still run.

### Docking helper

If your monitors need a custom mode added before they will span correctly (for example
a hand-crafted 1920×1080 mode on `DisplayPort-2`), keep a helper such as
`extras/fixmon.sh` and run it on dock:

```bash
#!/usr/bin/env bash
xrandr --newmode "1920x1080_60.00" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
xrandr --addmode DisplayPort-2 1920x1080_60.00
```

For automatic application on dock/undock, `autorandr` can save one profile per display
arrangement and re-apply it when the connected set changes.

---

## Troubleshooting

- **Panel stays hidden after a crash** — `gsettings reset org.cinnamon panels-autohide`
- **No hardware decoding** — check the log; try `MPV_EXTRA="--hwdec=vaapi"` or `--hwdec=nvdec`
- **Window doesn't span** — confirm the desktop is a single X screen
  (`xdpyinfo | grep dimensions` should show the combined size, e.g. `3840x2160`)
- **Video never starts** — check `MIN_MONITORS` against
  `xrandr --listactivemonitors`, and confirm `VIDEOS` contains files
- **Log** — `${XDG_RUNTIME_DIR:-/tmp}/aerial-saver/aerial-saver.log`

---

## Uninstall

```bash
./uninstall.sh
```

Your config is left in place; remove it manually with
`rm -rf ~/.config/aerial-saver` if you want a clean slate.

---

## Credits

- Video loader and original xscreensaver integration:
  [Chronosaurus42/Aerial-Screensaver-Linux](https://github.com/Chronosaurus42/Aerial-Screensaver-Linux)
- Aerial videos are the property of Apple, Inc.; this project only plays locally
  downloaded copies.

---

## License

Copyright (C) 2026  aerial-saver contributors

This program is free software: you can redistribute it and/or modify it under the
terms of the **GNU General Public License** as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this
program. If not, see <https://www.gnu.org/licenses/>.
