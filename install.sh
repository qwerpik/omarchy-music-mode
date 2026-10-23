#!/usr/bin/env bash
# Install music-mode for the current user. No root needed.
# Usage: ./install.sh   (PREFIX defaults to ~/.local)
set -euo pipefail
cd -- "$(dirname -- "$0")"

prefix=${PREFIX:-$HOME/.local}
config=${XDG_CONFIG_HOME:-$HOME/.config}
bindir=$prefix/bin
plugindir=$config/omarchy/plugins/user.music-mode
unitdir=$config/systemd/user
password_file=$config/music-mode/password

for tool in curl jq; do
  command -v "$tool" >/dev/null || { echo "Missing dependency: $tool" >&2; exit 1; }
done

substitute() { sed "s|@BINDIR@|$bindir|g" "$1" >"$2"; }

install -d "$bindir" "$plugindir" "$unitdir"
install -m755 bin/music-mode bin/music-mode-guard "$bindir/"
install -m644 omarchy/plugins/user.music-mode/manifest.json "$plugindir/"
substitute omarchy/plugins/user.music-mode/Widget.qml "$plugindir/Widget.qml"
substitute systemd/music-mode-guard.service "$unitdir/music-mode-guard.service"

if [[ ! -s $password_file && -t 0 ]]; then
  echo "music-mode logs in to the CoolerControl daemon as CCAdmin."
  read -rsp "CoolerControl password (the one for the CoolerControl web UI / app): " password; echo
  install -d -m700 "$(dirname "$password_file")"
  (umask 077; printf '%s\n' "$password" >"$password_file")
fi

if [[ -z ${MUSIC_MODE_NO_RELOAD:-} ]]; then
  systemctl --user daemon-reload
  systemctl --user enable --now music-mode-guard.service
fi

cat <<MSG
Installed to $bindir.

Next steps:
  1. In CoolerControl, create the "Stock" and "Music" modes (docs/COOLERCONTROL.md).
  2. Add {"id": "user.music-mode"} to a bar section in ~/.config/omarchy/shell.json
  3. Try it:  music-mode toggle
MSG
[[ -s $password_file ]] || echo "  !  Put your CoolerControl password in $password_file (chmod 600)."
