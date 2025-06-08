#!/bin/sh

set -e

if [ "$SAT_DEBUG" = 1 ]; then
	set -x
	echo "$@" >> /tmp/.sat-debug
fi

VERSION=0.1
TMPDIR="${TMPDIR:-/tmp}"

_error() {
	>&2 printf '\n%s\n\n' " ERROR: $*"
	exit 1
}

_usage() {
	echo " USAGE: ${0##*/} </path/to/appimage> </path/to/out/thumbnail> <size>"
	exit 1
}

_cleanup() {
	if [ -d "$MOUNT_POINT" ]; then
		umount "$MOUNT_POINT"
		rm -rf "$MOUNT_POINT"
	fi
}

trap _cleanup INT TERM EXIT

_dep_check() {
	while read -r d; do
		if ! command -v "$d" >/dev/null; then
			_error "Missing dependency $d"
		fi
	done <<-EOF
	awk
	dwarfs
	head
	mkdir
	od
	readlink
	squashfuse
	tail
	umount
	EOF
}

_find_offset() {
	offset="$(LC_ALL=C od -An -vtx1 -N 64 -- "$1" | awk '
	  BEGIN {
		for (i = 0; i < 16; i++) {
			c = sprintf("%x", i)
			H[c] = i
			H[toupper(c)] = i
		}
	  }
	  {
		  elfHeader = elfHeader " " $0
	  }
	  END {
		$0 = toupper(elfHeader)
		if ($5 == "02") is64 = 1; else is64 = 0
		if ($6 == "02") isBE = 1; else isBE = 0
		if (is64) {
			if (isBE) {
				shoff = $41 $42 $43 $44 $45 $46 $47 $48
				shentsize = $59 $60
				shnum = $61 $62
			} else {
				shoff = $48 $47 $46 $45 $44 $43 $42 $41
				shentsize = $60 $59
				shnum = $62 $61
			}
		  } else {
			if (isBE) {
				shoff = $33 $34 $35 $36
				shentsize = $47 $48
				shnum = $49 $50
			} else {
				shoff = $36 $35 $34 $33
				shentsize = $48 $47
				shnum = $50 $49
			}
		  }
		  print parsehex(shoff) + parsehex(shentsize) * parsehex(shnum)
		}
	  function parsehex(v,    i, r) {
		  r = 0
		  for (i = 1; i <= length(v); i++)
		  r = r * 16 + H[substr(v, i, 1)]
		  return r
	  }'
	)"
	if [ -z "$offset" ]; then
		return 1
	fi
}

_is_appimage() {
	case "$(head -c 10 "$1")" in
		*ELF*AI|\
		*ELF*RI|\
		*ELF*AB) _find_offset "$1";;
		''|*)    return 1         ;;
	esac
}

_get_hash() {
	HASH="$(tail -vc 1048576 "$1" | cksum)"
	HASH="${HASH%% *}"
	if [ -z "$HASH" ]; then
		_error "Something went wrong getting hash from $1"
	fi
	echo "$HASH"
}

_mount_appimage() {
	mkdir -p "$MOUNT_POINT"
	squashfuse -o offset="$offset" "$INPUT" "$MOUNT_POINT" 2>/dev/null \
		|| dwarfs -o offset="$offset" "$INPUT" "$MOUNT_POINT"

	>&2 printf '%s\n' "$MOUNT_POINT"
}

_get_thumbnail() {
	if command -v magick 1>/dev/null; then
		magick -background none "$TMPICON" -thumbnail "$SIZE" PNG:"$OUTPUT"
	elif command -v convert 1>/dev/null; then
		convert -background none "$TMPICON" -thumbnail "$SIZE" PNG:"$OUTPUT"
	elif command -v ffmpeg 1>/dev/null; then
		ffmpeg -y -i "$TMPICON" -vf "scale=$SIZE:-1" "$OUTPUT"
	elif command -v vipsthumbnail 1>/dev/null; then
		vipsthumbnail "$TMPICON" --size "$SIZE" -o "$OUTPUT"
	else
		_error "No magick, convert, ffmpeg or vipsthumbnail found"
	fi
}

# Start
if [ "$1" = "--version" ]; then
	echo "$VERSION"
	exit 0
elif [ "$#" -lt 3 ]; then
	_usage
fi

_dep_check

INPUT="$(readlink -f "$1")"
OUTPUT="$(readlink -f "$2")"
SIZE="$3"

if ! _is_appimage "$INPUT"; then
	_error "'$INPUT' is NOT an AppImage"
fi

HASH="$(_get_hash "$INPUT")"
MOUNT_POINT="$TMPDIR/.sat-$HASH"
TMPICON="$MOUNT_POINT"/.DirIcon

if ! _mount_appimage; then
	_error "Failed to mount '$INPUT', is it an AppImage?"
fi

if ! _get_thumbnail; then
	_error "Failed to resize and move .DirIcon"
fi
