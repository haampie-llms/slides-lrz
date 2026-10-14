#!/usr/bin/env python3
"""Post-process a recorded cast in place, for readability on slides:

- turn the invisible OSC 7777 markers written by demos/lib.sh into asciicast marker events
  (the deck shows the latest one as a sticky "current command" caption)
- shorten long paths, hashes and digests in the *output* with an ellipsis

Usage: postprocess_cast.py <file.cast>
"""
import base64
import json
import re
import sys

MARK = re.compile(r"\x1b\]7777;([A-Za-z0-9+/=]*)\x07")
SUBS = [
    # /home/bot/lrz-demo/store/linux-x86_64_v3/zlib-ng-2.3.3-<32 char hash> -> .../zlib-ng-2.3.3-g72d7i3
    (re.compile(r"(/home/bot/lrz-demo/[^/\s]+)/linux-x86_64_v3/([A-Za-z0-9_.+-]+?-)([a-z2-7]{7})[a-z2-7]{25}"),
     r"\1/…/\2\3"),
    # OCI tags: name-version-<32 char hash>.spack -> name-version-<7>….spack
    (re.compile(r"([A-Za-z0-9_.+-]+-)([a-z2-7]{7})[a-z2-7]{25}\.spack"), r"\1\2….spack"),
    # sha256 digests, also as path components
    (re.compile(r"sha256([:/])([0-9a-f]{12})[0-9a-f]{52}"), r"sha256\1\2…"),
]

path = sys.argv[1]
lines = open(path).read().splitlines()
out = [lines[0]]
for line in lines[1:]:
    if not line.strip():
        continue
    t, kind, data = json.loads(line)
    if kind != "o":
        out.append(line)
        continue
    pos = 0
    for m in MARK.finditer(data):
        before = data[pos : m.start()]
        if before:
            out.append(json.dumps([t, "o", before]))
        label = base64.b64decode(m.group(1)).decode()
        out.append(json.dumps([t, "m", label]))
        pos = m.end()
    rest = data[pos:]
    for rx, rep in SUBS:
        rest = rx.sub(rep, rest)
    if rest:
        out.append(json.dumps([t, "o", rest]))
open(path, "w").write("\n".join(out) + "\n")
