#!/usr/bin/env bash
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
CFG="$HOME/.config/aerial-saver"
AUTOSTART="$HOME/.config/autostart"

echo "==> Installing aerial-saver"

if ! command -v mpv >/dev/null || ! command -v xprintidle >/dev/null; then
    echo "==> Installing dependencies (sudo)"
    sudo apt-get update
    sudo apt-get install -y mpv xprintidle
fi

mkdir -p "$BIN" "$CFG" "$AUTOSTART"
install -m 755 "$SRC/bin/aerial-saver" "$BIN/aerial-saver"

if [ ! -f "$CFG/config" ]; then
    install -m 644 "$SRC/config/config.example" "$CFG/config"
    echo "==> Wrote default config to $CFG/config"
else
    echo "==> Keeping existing config at $CFG/config"
fi

sed "s|@EXEC@|$BIN/aerial-saver|" \
    "$SRC/autostart/aerial-saver.desktop" > "$AUTOSTART/aerial-saver.desktop"

# Retire any prior xscreensaver setup
pkill xscreensaver 2>/dev/null || true
rm -f "$AUTOSTART/xscreensaver.desktop"

# Quiet Cinnamon's own idle/lock so it doesn't fight the script
gsettings set org.cinnamon.desktop.session idle-delay 0 || true
gsettings set org.cinnamon.desktop.screensaver idle-activation-enabled false || true

echo
echo "==> Done."
echo "    Start now:   $BIN/aerial-saver &"
echo "    Config:      $CFG/config"
echo "    Log:         \${XDG_RUNTIME_DIR:-/tmp}/aerial-saver/aerial-saver.log"
