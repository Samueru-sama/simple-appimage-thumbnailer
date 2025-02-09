#!/bin/sh

set -u
INPUT="$(realpath "$1")"
OUTPUT="$2"
SIZE="$3"
_TMPDIR="$(mktemp -d)"
TMPICON="$_TMPDIR"/squashfs-root/.DirIcon
COUNT=0

_error() {
	printf '\n%s\n\n' "ERROR: $*"
	[ -d "$_TMPDIR" ] && rm -rf "$_TMPDIR"
	exit 1
}

_sanity_check() {
	command -v convert 1>/dev/null || _error "Missing imagemagick dependency"
	[ -x "$INPUT" ] || _error "AppImage does not have executable permission"
}

_get_diricon() (
	cd "$_TMPDIR" || return 1
	"$INPUT" --appimage-extract '.DirIcon' 1>/dev/null
	# Resolve possible symlinks
	if [ -L ./squashfs-root/.DirIcon ]; then
		while [ "$COUNT" -lt 10 ]; do
			LINKPATH="$(readlink "$TMPICON" 2>/dev/null)"
			printf '\n%s\n' "Resolving symlink to $LINKPATH"
			"$INPUT" --appimage-extract "${LINKPATH#./}" 1>/dev/null
			mv -v ./squashfs-root/"${LINKPATH#./}" "$TMPICON"
			[ -L ./squashfs-root/.DirIcon ] || break
			COUNT=$((COUNT + 1))
		done
	fi
)

_resize() {
	convert -background none -thumbnail "$SIZE" "$TMPICON" PNG:"$TMPICON"
}

_sanity_check
mkdir -p "$_TMPDIR" || _error "Could not create temp directory"
_get_diricon || _error "Failed to extract .DirIcon, is it an AppImage?"
_resize || _error "Failed to resize .DirIcon"
mv -v "$TMPICON" "$OUTPUT"
rm -rf "$_TMPDIR"
