#!/bin/sh

set -e
BINDIR="${XDG_BIN_HOME:-$HOME/.local/bin}"
TARGET_BIN="$BINDIR"/simple-appimage-thumbnailer
DATADIR="${XDG_DATA_HOME:-$HOME/.local/share}"/thumbnailers
TARGET_ENTRY="$DATADIR"/simple-appimage-thumbnailer.thumbnailer

if [ "$(id -u)" = 0 ]; then
	echo "DO NOT RUN AS ROOT!"
	exit 1
elif [ "$1" = "uninstall" ] || [ "$1" = "remove" ]; then
	rm -fv "$TARGET_BIN" "$TARGET_ENTRY"
elif ! command -v convert 1>/dev/null; then
	echo "Missing imagemagick dependency, install it to continue"
	exit 1
elif command -v "$TARGET_BIN" 1>/dev/null; then
	echo "simple-appimage-thumbnailer is already installed"
	exit 1
elif ! echo "$PATH" | grep -q "$BINDIR"; then
	echo "$BINDIR is NOT in PATH, please add it in order to install this"
	exit 1
else
	echo "Installing..."
	mkdir -p "$BINDIR" "$DATADIR"
	cp -v ./simple-appimage-thumbnailer.sh "$TARGET_BIN"
	cp -v ./simple-appimage-thumbnailer.thumbnailer "$TARGET_ENTRY"
	chmod +x "$TARGET_BIN"
fi

echo "All done!"
