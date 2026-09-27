#!/bin/bash
# Print the book: render every page to web/pages/ and copy in the page turner.
#   ./build.sh [/path/to/godot4]
# Needs Godot 4.4 and an X display with OpenGL — xvfb-run and Mesa's software
# rasterizer are enough (apt: xvfb libgl1-mesa-dri). The engine never ships:
# what is served is these pictures and reader/index.html.
set -euo pipefail
GODOT="${1:-godot4}"
RES="${RES:-2560x1440}"      # 2x a 1280x720 panel: crisp on a Retina screen
QUALITY="${QUALITY:-90}"     # lossy WebP quality; ~250 KB a page at 2560x1440
cd "$(dirname "$0")"
export HOME="${HOME:-/root}"
rm -rf web && mkdir -p web/pages
# Classes with class_name are only registered by an import pass; a fresh clone
# cannot resolve them without it.
"$GODOT" --headless --path project --import > /dev/null 2>&1 || true
log="$(mktemp)"
xvfb-run -a -s "-screen 0 ${RES}x24" env LIBGL_ALWAYS_SOFTWARE=1 \
	"$GODOT" --display-driver x11 --rendering-driver opengl3 --resolution "$RES" \
	--path project -- --shots="$PWD/web/pages" --webp="$QUALITY" 2>&1 | tee "$log" | grep -E "^(shot|LAYOUT|SHOTS)|SCRIPT ERROR|Parse Error" || true
# The render is also the gate: a script error, or a balloon out of reading
# order or over a face, fails the build rather than getting printed.
if grep -qE "SCRIPT ERROR|Parse Error|^LAYOUT" "$log" || ! grep -q "^SHOTS COMPLETE" "$log"; then
	echo "build: the render reported problems (log: $log)" >&2
	exit 1
fi
if ! grep -q "0 layout problems" "$log"; then
	echo "build: layout problems reported" >&2
	exit 1
fi
rm -f "$log"
n="$(ls web/pages/page_*.webp | wc -l)"
sed "s/__TOTAL__/$n/" reader/index.html > web/index.html
echo "printed $n pages to web/ ($(du -sh web | cut -f1))"
