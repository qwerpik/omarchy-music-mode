#!/usr/bin/env bash
# Install into a throwaway home and check the result is complete and relocated.
set -euo pipefail
cd -- "$(dirname -- "$0")/.."
root=$(mktemp -d); trap 'rm -rf "$root"' EXIT
env=(HOME="$root" PREFIX="$root/prefix" XDG_CONFIG_HOME="$root/config" MUSIC_MODE_NO_RELOAD=1)

env "${env[@]}" ./install.sh </dev/null >/dev/null
for f in prefix/bin/music-mode prefix/bin/music-mode-guard \
         config/systemd/user/music-mode-guard.service \
         config/omarchy/plugins/user.music-mode/Widget.qml \
         config/omarchy/plugins/user.music-mode/manifest.json; do
  [[ -e $root/$f ]] || { echo "FAIL missing $f"; exit 1; }
done
if grep -rq @BINDIR@ "$root"; then echo "FAIL unsubstituted @BINDIR@"; exit 1; fi
grep -q "ExecStart=$root/prefix/bin/music-mode-guard" "$root/config/systemd/user/music-mode-guard.service"
[[ ! -e $root/config/music-mode/password ]] || { echo "FAIL wrote a password without asking"; exit 1; }

env "${env[@]}" ./uninstall.sh >/dev/null
[[ -z $(find "$root/prefix" -type f) ]] || { echo "FAIL uninstall left files"; exit 1; }
echo "ok   install, relocation and uninstall"
