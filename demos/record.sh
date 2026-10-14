#!/bin/bash
# Usage: demos/record.sh <name> [cols] [rows]
# Records demos/<name>.sh into casts/<name>.cast
set -e
here="$(cd "$(dirname "$0")" && pwd)"
name="$1"; cols="${2:-100}"; rows="${3:-28}"
asciinema rec --overwrite -q -i 1.5 --cols "$cols" --rows "$rows" \
  -c "bash $here/$name.sh" "$here/../casts/$name.cast"
