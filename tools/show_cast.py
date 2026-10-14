#!/usr/bin/env python3
"""Print the final full transcript of a cast (for checking recordings). Requires pyte."""
import json, sys, pyte
lines = open(sys.argv[1]).read().splitlines()
h = json.loads(lines[0]); sc = pyte.Screen(h["width"], 3000); st = pyte.Stream(sc)
dur = 0.0
for x in lines[1:]:
    t, k, d = json.loads(x); dur = t
    if k == "o": st.feed(d)
out = [r.rstrip() for r in sc.display]
while out and not out[-1]: out.pop()
print("\n".join(out)); print(f"--- {len(out)} lines, {dur:.1f}s", file=sys.stderr)
