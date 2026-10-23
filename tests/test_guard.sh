#!/usr/bin/env bash
# Feed the guard fake sensors and a fake music-mode, check it switches back to Stock.
set -uo pipefail
cd -- "$(dirname -- "$0")/.." || exit
tmp=$(mktemp -d); trap 'kill "$guard" 2>/dev/null; rm -rf "$tmp"' EXIT
failed=0

mkdir -p "$tmp/hwmon/hwmon0" "$tmp/hwmon/hwmon1" "$tmp/bin"
echo k10temp >"$tmp/hwmon/hwmon0/name"
echo 45000 >"$tmp/hwmon/hwmon0/temp1_input"   # no temp3: falls back to Tctl
echo amdgpu >"$tmp/hwmon/hwmon1/name"
echo 50000 >"$tmp/hwmon/hwmon1/temp1_input"

cat >"$tmp/bin/music-mode" <<FAKE
#!/usr/bin/env bash
echo "\$*" >>"$tmp/calls"
[[ \$1 == status ]] && echo '{"music":true}'
exit 0
FAKE
printf '#!/bin/sh\necho "$*" >>"%s/notified"\n' "$tmp" >"$tmp/bin/notify-send"
chmod +x "$tmp/bin/"*

PATH=$tmp/bin:$PATH MUSIC_GUARD_HWMON_ROOT=$tmp/hwmon MUSIC_GUARD_INTERVAL=1 MUSIC_GUARD_HOLD=2 \
  bin/music-mode-guard >"$tmp/log" 2>&1 &
guard=$!

check() {
  if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; failed=1; fi
}

sleep 3
check "picks Tctl when Tccd1 is missing" "grep -q 'hwmon0/temp1_input' '$tmp/log'"
check "cool temps leave music mode alone" "[[ ! -e '$tmp/calls' ]]"

echo 82000 >"$tmp/hwmon/hwmon1/temp1_input"   # hot GPU
sleep 4
check "hot GPU switches fans to stock" "grep -qx stock '$tmp/calls'"
check "user is notified" "grep -q 'GPU 82°C' '$tmp/notified'"

exit $failed
