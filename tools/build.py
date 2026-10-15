#!/usr/bin/env python3
"""Build index.html from src/slides.html. Requires pyte."""

import html
import json
import pathlib
import re

import pyte

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "src" / "slides.html"
OUT = ROOT / "index.html"

# Max transcript lines for print; longer transcripts are elided in the middle.
MAX_PRINT_LINES = 46

ANSI_16 = {
    "black": "#3b3b3b",
    "red": "#e0605a",
    "green": "#6cc070",
    "brown": "#d7b44a",
    "yellow": "#d7b44a",
    "blue": "#6aa6e8",
    "magenta": "#c38add",
    "cyan": "#5fc4c4",
    "white": "#e8e8e8",
    "brightblack": "#8a8a8a",
    "brightred": "#ff7b72",
    "brightgreen": "#8ee08f",
    "brightyellow": "#ffe08a",
    "brightblue": "#8cc4ff",
    "brightmagenta": "#e2a8ff",
    "brightcyan": "#8ee6e6",
    "brightwhite": "#ffffff",
}


def color(c):
    if c == "default":
        return None
    if c in ANSI_16:
        return ANSI_16[c]
    if re.fullmatch(r"[0-9a-fA-F]{6}", c):
        return "#" + c
    return None


def render_transcript(cast_text: str) -> str:
    lines = cast_text.splitlines()
    header = json.loads(lines[0])
    width = header["width"]
    rows = 3000
    screen = pyte.Screen(width, rows)
    stream = pyte.Stream(screen)
    for line in lines[1:]:
        if not line.strip():
            continue
        _, kind, data = json.loads(line)
        if kind == "o":
            stream.feed(data)

    out = []
    for y in range(rows):
        row = screen.buffer[y]
        parts = []
        cur_style, cur_text = None, []
        for x in range(width):
            ch = row[x]
            fg = color(ch.fg)
            style = []
            if fg:
                style.append(f"color:{fg}")
            if ch.bold:
                style.append("font-weight:700")
            style = ";".join(style)
            if style != cur_style:
                if cur_text:
                    parts.append((cur_style, "".join(cur_text)))
                cur_style, cur_text = style, []
            cur_text.append(ch.data)
        if cur_text:
            parts.append((cur_style, "".join(cur_text)))
        # strip trailing whitespace
        while parts and not parts[-1][1].strip():
            parts.pop()
        if parts:
            s, t = parts[-1]
            parts[-1] = (s, t.rstrip())
        out.append(
            "".join(
                f'<span style="{s}">{html.escape(t)}</span>' if s else html.escape(t)
                for s, t in parts
            )
        )
    while out and not out[-1]:
        out.pop()
    # drop the trailing empty prompt line if it is the last one
    if len(out) > MAX_PRINT_LINES:
        head = MAX_PRINT_LINES // 3
        tail = MAX_PRINT_LINES - head - 1
        n = len(out) - head - tail
        out = out[:head] + [f'<span class="elided">⋮ {n} lines omitted ⋮</span>'] + out[-tail:]
    return "\n".join(out), len(out), width


def poster_time(cast_text: str, idle_limit: float = 1.5) -> float:
    """Time (with idle limit applied) right after the first line has been printed."""
    t_prev, total = 0.0, 0.0
    for line in cast_text.splitlines()[1:]:
        if not line.strip():
            continue
        t, kind, data = json.loads(line)
        total += min(t - t_prev, idle_limit)
        t_prev = t
        if kind == "o" and "\n" in data:
            return total
    return 0.5


def cast_duration(cast_text: str, idle_limit: float) -> float:
    t_prev, total = 0.0, 0.0
    for line in cast_text.splitlines()[1:]:
        if not line.strip():
            continue
        t = json.loads(line)[0]
        total += min(t - t_prev, idle_limit)
        t_prev = t
    return total


def main():
    src = SRC.read_text()
    css = (ROOT / "vendor" / "asciinema-player.css").read_text()
    js = (ROOT / "vendor" / "asciinema-player.min.js").read_text()

    casts = {}

    def term(m):
        attrs = m.group(1)
        name = re.search(r'data-cast="([^"]+)"', attrs).group(1)
        path = ROOT / "casts" / f"{name}.cast"
        if not path.exists():
            return (
                f'<div class="term missing"{attrs}><pre class="transcript-missing">'
                f"[recording {html.escape(name)}.cast not available yet]</pre></div>"
            )
        text = path.read_text()
        casts[name] = text
        transcript, nlines, width = render_transcript(text)
        if "data-poster" not in attrs:
            attrs += f' data-poster="{poster_time(text):.2f}"'
        return (
            f'<div class="term"{attrs} data-lines="{nlines}" data-width="{width}">'
            f'<pre class="transcript" style="--lines:{nlines};--cols:{width}">{transcript}</pre>'
            f"</div>"
        )

    src = re.sub(r'<div class="term"([^>]*)></div>', term, src)

    cast_scripts = "\n".join(
        f'<script type="application/x-asciicast" id="cast-{name}">'
        + text.replace("</", "<\\/")
        + "</script>"
        for name, text in casts.items()
    )

    logo = (ROOT / "vendor" / "spack-logo.svg").read_text()
    logo = re.sub(r"<\?xml[^>]*\?>", "", logo)

    src = src.replace("/*@PLAYER_CSS@*/", css)
    src = src.replace("/*@PLAYER_JS@*/", js.replace("</script", "<\\/script"))
    src = src.replace("<!--@CASTS@-->", cast_scripts)
    src = src.replace("<!--@LOGO@-->", logo)

    OUT.write_text(src)
    print(f"wrote {OUT} ({OUT.stat().st_size / 1024:.0f} KiB, {len(casts)} casts)")


if __name__ == "__main__":
    main()
