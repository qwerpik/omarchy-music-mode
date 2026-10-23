# Contributing

Bug reports and pull requests are welcome — especially fan curves and sensor
names from other hardware.

1. Fork and branch from `main`.
2. Run `make check`. The tests drive `music-mode` against a mock CoolerControl
   API (`tests/mock_coolercontrol.py`) and the guard against fake hwmon sensors,
   so no CoolerControl or special hardware is needed. `shellcheck` must be clean.
3. Keep the runtime dependencies at bash, `curl` and `jq`.
4. The guard must only ever switch *to* Stock. Changes that could leave fans in
   a quiet mode while hot need a test showing they can't.

Please use [Conventional Commits](https://www.conventionalcommits.org/)
(`feat:`, `fix:`, `docs:` …) for commit messages.
