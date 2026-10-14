#!/bin/bash
# Usage: demos/record.sh <name> [cols] [rows]
# Records demos/<name>.sh into casts/<name>.cast, then post-processes it for the slides
set -e
here="$(cd "$(dirname "$0")" && pwd)"
name="$1"; cols="${2:-100}"; rows="${3:-28}"
asciinema rec --overwrite -q -i 3 --cols "$cols" --rows "$rows" \
  -c "bash $here/$name.sh" "$here/../casts/$name.cast"
python3 -I "$here/../tools/postprocess_cast.py" "$here/../casts/$name.cast"
