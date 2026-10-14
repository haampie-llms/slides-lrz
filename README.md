# Sharing software environments — LRZ, 15 Oct 2026

Slides for a 90-minute talk at LRZ: Spack environments → build caches →
`spack containerize` → `spack buildcache push --base-image` (container images as archives),
followed by the Spack tutorial's binary cache section as hands-on.

- `slides.html` — **the deck**: one self-contained file, works offline over `file://`.
  Keys: ←/→ or PgUp/PgDn (a clicker works; on recorded slides "next" plays the recording,
  then skips to its end, then moves on), `p` play/pause, `r` restart recording,
  `n` speaker notes, `f` fullscreen. Print / Save as PDF from Chrome: one slide per page,
  recordings are replaced by static transcripts.
- `src/slides.html` — slide source; `tools/build.py` inlines player, logo and casts
  (`pip install pyte`, then `python3 tools/build.py`).
- `casts/` — terminal recordings (asciinema v2), made with `demos/*.sh` via
  `demos/record.sh <name> [cols] [rows]`. Commands and output are real; `tools/postprocess_cast.py`
  then shortens long store paths, hashes and digests with `…` for readability, and turns the
  command markers into asciicast markers that the deck shows as a sticky "current command" caption.
- `tools/many_layers.py` — builds synthetic images with N layers to probe runtime layer limits.
- `outline.md` — the talk outline.

The demo environment (Spack v1.2.2, isolated config, local registry, rootless Docker) lives in
`~/lrz-demo` and is not part of this repo.
