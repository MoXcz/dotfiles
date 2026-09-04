#!/bin/bash

# Clipboard capture hook for the shell. wl-paste --watch invokes it
# with the payload on stdin and the mime type as $1 ("text" or "image/png").
# Full payloads are stored under items/<id>.<ext>; one JSON line per capture
# is appended to history.jsonl for the QML side to read.

set -o pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/shell/clipboard"
ITEMS_DIR="$STATE_DIR/items"
HISTORY="$STATE_DIR/history.jsonl"
MAX_BYTES="${CLIP_MAX_BYTES:-1048576}"

mkdir -p "$ITEMS_DIR"

# Password managers flag secrets with this hint; never record them.
if wl-paste --list-types 2>/dev/null | grep -qx 'x-kde-passwordManagerHint'; then
  exit 0
fi

tmp=$(mktemp "$ITEMS_DIR/.capture.XXXXXX") || exit 0
trap 'rm -f "$tmp"' EXIT
cat >"$tmp"
[[ -s $tmp ]] || exit 0

bytes=$(stat -c %s "$tmp")
if [[ ${1:-text} == image/* ]]; then
  type=image
  ext=png
else
  type=text
  ext=txt
  ((bytes > MAX_BYTES)) && exit 0
  grep -q '[^[:space:]]' "$tmp" || exit 0
fi

id=$(sha256sum "$tmp" | cut -c1-16)

# Watchers fire on every selection change, including the shell's own
# wl-copy; repeats of the previous capture would only add noise.
if tail -n 1 "$HISTORY" 2>/dev/null | grep -qF "\"id\": \"$id\""; then
  exit 0
fi

file="$ITEMS_DIR/$id.$ext"
[[ -e $file ]] || mv "$tmp" "$file"

python3 - "$type" "$id" "$bytes" "$file" "$(date +%s)" <<'PY' >>"$HISTORY"
import json, struct, sys
kind, id_, size, path, now = sys.argv[1:6]
entry = {"id": id_, "type": kind, "text": "", "bytes": int(size), "time": int(now), "file": path}
with open(path, "rb") as f:
    head = f.read(2000)
if kind == "text":
    entry["text"] = head.decode("utf-8", "replace")[:400]
else:
    if head[:8] == b"\x89PNG\r\n\x1a\n" and len(head) >= 24:
        entry["width"], entry["height"] = struct.unpack(">II", head[16:24])
        entry["text"] = "Image %dx%d" % (entry["width"], entry["height"])
    else:
        entry["text"] = "Image"
print(json.dumps(entry, ensure_ascii=False))
PY
