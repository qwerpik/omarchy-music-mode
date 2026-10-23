PREFIX ?= $(HOME)/.local

.PHONY: test check install uninstall

test:
	tests/test_music_mode.sh
	tests/test_guard.sh
	tests/test_install.sh

check: test
	shellcheck bin/music-mode bin/music-mode-guard install.sh uninstall.sh tests/*.sh

install:
	PREFIX="$(PREFIX)" ./install.sh

uninstall:
	PREFIX="$(PREFIX)" ./uninstall.sh
