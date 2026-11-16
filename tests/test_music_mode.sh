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
# Fake power-profiles-daemon, so the tests never touch the real power profile.
cat >"$tmp/bin/powerprofilesctl" <<'FAKE'
#!/usr/bin/env bash
case $1 in
  get) cat "$FAKE_PROFILE_FILE" ;;
  set) [[ -z ${FAKE_PROFILE_FAIL:-} ]] || exit 1; echo "$2" >"$FAKE_PROFILE_FILE" ;;
esac
FAKE
chmod +x "$tmp/bin/powerprofilesctl"
export FAKE_PROFILE_FILE=$tmp/profile XDG_STATE_HOME=$tmp/state
echo performance >"$tmp/profile"
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
profile_is() {
  local got; got=$(<"$tmp/profile")
  if [[ $got == "$1" ]]; then echo "ok   power profile $got ($2)"
  else echo "FAIL power profile: got '$got', want '$1' ($2)"; failed=1; fi
}
music='{"music":true} exit 0' stock='{"music":false} exit 0'

echo performance >"$tmp/profile"
expect "$music" music; profile_is power-saver "Music switches to power-saver"
expect "$music" music; expect "$stock" stock; profile_is performance "Stock restores it, even after Music twice"

expect "$music" music; echo balanced >"$tmp/profile"
expect "$stock" stock; profile_is balanced "a profile changed during Music is kept"

echo power-saver >"$tmp/profile"
expect "$music" music; expect "$stock" stock; profile_is power-saver "already power-saver stays"

echo performance >"$tmp/profile"
expect "$music" music
FAKE_PROFILE_FAIL=1 expect "$stock" stock; profile_is power-saver "restore refused"
expect "$stock" stock; profile_is performance "the next Stock retries the restore"

MUSIC_MODE_POWER_PROFILE='' expect "$music" music; profile_is performance "empty setting leaves it alone"
expect "$stock" stock

printf 'wrong\n' >"$tmp/password"
expect 'exit 22' status

exit $failed
