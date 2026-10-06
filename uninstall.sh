#!/usr/bin/env bash
set -euo pipefail
echo "==> Removing aerial-saver"
pkill -f aerial-saver 2>/dev/null || true
rm -f "$HOME/.local/bin/aerial-saver" \
      "$HOME/.config/autostart/aerial-saver.desktop"
# Config is left in place; remove it manually if you want:
#   rm -rf "$HOME/.config/aerial-saver"
gsettings reset org.cinnamon panels-autohide 2>/dev/null || true
echo "==> Done."
