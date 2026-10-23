#!/usr/bin/env bash
# Drive bin/music-mode against a mock CoolerControl API.
set -uo pipefail
cd -- "$(dirname -- "$0")/.." || exit
tmp=$(mktemp -d)
coproc mock { exec python3 tests/mock_coolercontrol.py; }
# shellcheck disable=SC2154  # mock_PID is set by coproc
trap 'kill "$mock_PID" 2>/dev/null; rm -rf "$tmp"' EXIT
read -r port <&"${mock[0]}"

printf 'secret\n' >"$tmp/password"
export MUSIC_MODE_API=http://127.0.0.1:$port MUSIC_MODE_PASSWORD_FILE=$tmp/password
export PATH=$tmp/bin:$PATH
mkdir "$tmp/bin" && ln -s /bin/true "$tmp/bin/omarchy-shell"
failed=0

expect() {
  local want=$1; shift
  local got; got=$(bin/music-mode "$@" 2>/dev/null; echo "exit $?")
  got=${got//$'\n'/ }
  if [[ $got == "$want" ]]; then echo "ok   music-mode $*: $got"
  else echo "FAIL music-mode $*: got '$got', want '$want'"; failed=1; fi
}

expect '{"music":false} exit 0' status
expect '{"music":true} exit 0'  toggle
expect '{"music":true} exit 0'  status
expect '{"music":false} exit 0' toggle
expect '{"music":true} exit 0'  music
expect '{"music":true} exit 0'  music
expect '{"music":false} exit 0' stock
expect 'exit 2'                 bogus
MUSIC_MODE_MUSIC=Silent expect 'exit 1' status
printf 'wrong\n' >"$tmp/password"
expect 'exit 22' status

exit $failed
