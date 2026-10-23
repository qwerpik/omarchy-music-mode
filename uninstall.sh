#!/usr/bin/env bash
# Remove everything install.sh put in place. The password file is kept unless --purge.
set -euo pipefail

prefix=${PREFIX:-$HOME/.local}
config=${XDG_CONFIG_HOME:-$HOME/.config}
reload=${MUSIC_MODE_NO_RELOAD:-}

[[ -n $reload ]] || systemctl --user disable --now music-mode-guard.service 2>/dev/null || true
rm -f "$prefix/bin/music-mode" "$prefix/bin/music-mode-guard"
rm -rf "$config/omarchy/plugins/user.music-mode"
rm -f "$config/systemd/user/music-mode-guard.service"
if [[ ${1:-} == --purge ]]; then rm -rf "$config/music-mode"; fi
[[ -n $reload ]] || systemctl --user daemon-reload 2>/dev/null || true

echo "music-mode removed. Also delete the user.music-mode bar entry in shell.json."
echo "Your CoolerControl modes and profiles are untouched."
