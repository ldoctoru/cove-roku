#!/usr/bin/env python3
"""Generates the Glass theme UI images in src/images/ui.

    python3 -m venv .venv && .venv/bin/pip install -r scripts/requirements.txt
    .venv/bin/python scripts/make-ui-assets.py            # regenerate src/images/ui
    .venv/bin/python scripts/make-ui-assets.py --check    # only compare (exit 1 when src/images/ui differs)

Options: --font PATH (default: the vendored scripts/fonts/DejaVuSans-Bold.ttf), --out DIR (default src/images/ui).

The images are drawn into a temporary folder first, then synced into the output folder: changed and new files
are written, files the script no longer makes are deleted (except HAND_MADE below), unchanged files are left
alone. The output is byte-for-byte reproducible only with the pinned Pillow (scripts/requirements.txt) and the
vendored font; CI checks that (the "UI assets" job).

Roku has no blur, clipping or gradients, so they are faked with small PNGs:
- *.9.png are 9-patches: content plus a 1px border whose black top/left pixels mark the stretchable middle.
- Corner and circle masks are painted in the page background colour (one file per background choice).
- Gradient strips are tiny and get stretched by the Poster node.
Shapes are drawn at 4x and scaled down for smooth edges. Colours follow Cove for macOS (Sources/Views.swift).
"""
import argparse
import filecmp
import os
import shutil
import sys
import tempfile

try:
    import PIL
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    sys.exit("make-ui-assets: Pillow is missing: pip install -r scripts/requirements.txt")

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OUT = os.path.normpath(os.path.join(HERE, "..", "src", "images", "ui"))
DEFAULT_FONT = os.path.join(HERE, "fonts", "DejaVuSans-Bold.ttf")
# Drawn by hand, not by this script: kept by the sync (and by --check) instead of being deleted as stale
HAND_MADE = {"icon_lock_28.png", "icon_profile_36.png", "icon_tab_profiles_44.png", "icon_critic_fresh_56.png", "icon_critic_rotten_56.png"}

OUT = DEFAULT_OUT     # where save() writes (main() points it at a temporary folder)
FONT = DEFAULT_FONT
WRITTEN = []
S = 4  # supersampling
BGS = {"black": (0, 0, 0), "charcoal": (28, 28, 28), "navy": (10, 18, 43), "plum": (31, 13, 38), "forest": (10, 31, 20)}
GLASS_FILL = (28, 28, 28, 179)
GLASS_STROKE = (255, 255, 255, 38)
WHITE = (255, 255, 255, 255)


def save(img, name):
    if name in WRITTEN:
        sys.exit("make-ui-assets: %s is drawn twice" % name)
    WRITTEN.append(name)
    img.save(os.path.join(OUT, name), optimize=True)


def font(size):
    return ImageFont.truetype(FONT, size)


def down(img, w, h):
    return img.resize((w, h), Image.LANCZOS)


def shape(w, h, radius, fill, stroke=None, stroke_w=0):
    big = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    r = radius * S
    if stroke and stroke_w:
        d.rounded_rectangle([0, 0, w * S - 1, h * S - 1], r, fill=stroke)
        inset = stroke_w * S
        d.rounded_rectangle([inset, inset, w * S - 1 - inset, h * S - 1 - inset], max(r - inset, 0), fill=fill)
    else:
        d.rounded_rectangle([0, 0, w * S - 1, h * S - 1], r, fill=fill)
    return down(big, w, h)


def ring(w, h, radius, width, color):
    big = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    d.rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius * S, outline=color, width=width * S)
    return down(big, w, h)


def arc(size, width, pct, color=WHITE):
    """A clockwise arc from 12 o'clock covering pct % of a circle, with round ends."""
    import math
    big = Image.new("RGBA", (size * S, size * S), (0, 0, 0, 0))
    if pct <= 0:
        return down(big, size, size)
    d = ImageDraw.Draw(big)
    w = width * S
    box = [0, 0, size * S - 1, size * S - 1]  # (PIL draws the width inwards from the box)
    end = -90 + 360 * pct / 100
    d.arc(box, -90, end, fill=color, width=w)
    if pct < 100:
        r = (size * S - w) / 2
        c = size * S / 2
        for a in (-90, end):
            x = c + r * math.cos(math.radians(a))
            y = c + r * math.sin(math.radians(a))
            d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=color)
    return down(big, size, size)


def nine(content, stretch_x=None, stretch_y=None):
    """Wraps content in the 1px 9-patch border; stretch_* = (start, end) inside content, default its middle 2px."""
    w, h = content.size
    sx = stretch_x or (w // 2 - 1, w // 2 + 1)
    sy = stretch_y or (h // 2 - 1, h // 2 + 1)
    img = Image.new("RGBA", (w + 2, h + 2), (0, 0, 0, 0))
    img.paste(content, (1, 1))
    for x in range(sx[0], sx[1]):
        img.putpixel((x + 1, 0), (0, 0, 0, 255))
    for y in range(sy[0], sy[1]):
        img.putpixel((0, y + 1), (0, 0, 0, 255))
    return img


def circle(size, fill, stroke=None, stroke_w=0):
    return shape(size, size, size // 2, fill, stroke, stroke_w)


def ring_circle(size, width, color=WHITE):
    """A ring: a filled circle with the middle cut out (\"Who's watching?\" focus ring)."""
    big = Image.new("RGBA", (size * S, size * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    d.ellipse([0, 0, size * S - 1, size * S - 1], fill=color)
    i = width * S
    d.ellipse([i, i, size * S - 1 - i, size * S - 1 - i], fill=(0, 0, 0, 0))
    return down(big, size, size)


def strip(w, h, alpha_at, rgb=(0, 0, 0), vertical=True):
    img = Image.new("RGBA", (w, h))
    n = h if vertical else w
    for i in range(n):
        a = int(round(alpha_at(i / (n - 1))))
        for j in range(w if vertical else h):
            img.putpixel((j, i) if vertical else (i, j), rgb + (a,))
    return img


def ramp(stops):
    def f(t):
        for (t0, a0), (t1, a1) in zip(stops, stops[1:]):
            if t <= t1:
                return a0 + (a1 - a0) * ((t - t0) / (t1 - t0) if t1 > t0 else 1)
        return stops[-1][1]
    return f


def corner_mask(size, radius, bg):
    big = Image.new("RGBA", (size * S, size * S), bg + (255,))
    d = ImageDraw.Draw(big)
    d.rounded_rectangle([0, 0, size * S - 1, size * S - 1], radius * S, fill=(0, 0, 0, 0))
    return down(big, size, size)


def circle_mask(size, bg):
    big = Image.new("RGBA", (size * S, size * S), bg + (255,))
    ImageDraw.Draw(big).ellipse([0, 0, size * S - 1, size * S - 1], fill=(0, 0, 0, 0))
    return down(big, size, size)


def shadow(size, inset, radius, blur, alpha):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([inset, inset, size - 1 - inset, size - 1 - inset], radius, fill=alpha)
    m = m.filter(ImageFilter.GaussianBlur(blur))
    img.putalpha(m)
    return img


# ---- icons: white glyphs on transparent, tinted at runtime with blendColor
def icon(name, size, draw):
    big = Image.new("RGBA", (size * S, size * S), (0, 0, 0, 0))
    draw(ImageDraw.Draw(big), size * S)
    save(down(big, size, size), "icon_%s_%d.png" % (name, size))


def play(d, n):
    d.polygon([(n * 0.28, n * 0.18), (n * 0.28, n * 0.82), (n * 0.84, n * 0.5)], fill=WHITE)


def plus(d, n):
    t = n * 0.09
    d.rounded_rectangle([n / 2 - t, n * 0.2, n / 2 + t, n * 0.8], t, fill=WHITE)
    d.rounded_rectangle([n * 0.2, n / 2 - t, n * 0.8, n / 2 + t], t, fill=WHITE)


def check(d, n):
    d.line([(n * 0.2, n * 0.52), (n * 0.42, n * 0.74), (n * 0.82, n * 0.28)], fill=WHITE, width=int(n * 0.13), joint="curve")


def info(d, n):
    d.ellipse([n * 0.42, n * 0.12, n * 0.58, n * 0.28], fill=WHITE)
    d.rounded_rectangle([n * 0.42, n * 0.36, n * 0.58, n * 0.88], n * 0.05, fill=WHITE)


def heart(d, n):
    d.ellipse([n * 0.1, n * 0.16, n * 0.52, n * 0.58], fill=WHITE)
    d.ellipse([n * 0.48, n * 0.16, n * 0.9, n * 0.58], fill=WHITE)
    d.polygon([(n * 0.13, n * 0.44), (n * 0.87, n * 0.44), (n * 0.5, n * 0.88)], fill=WHITE)


def pause(d, n):
    d.rounded_rectangle([n * 0.24, n * 0.18, n * 0.42, n * 0.82], n * 0.04, fill=WHITE)
    d.rounded_rectangle([n * 0.58, n * 0.18, n * 0.76, n * 0.82], n * 0.04, fill=WHITE)


def restart(d, n):
    w = int(n * 0.11)
    d.arc([n * 0.18, n * 0.18, n * 0.82, n * 0.82], 200, 520 - 40, fill=WHITE, width=w)
    # arrow head at the arc's start (about 10 o'clock), pointing up-left
    d.polygon([(n * 0.08, n * 0.30), (n * 0.38, n * 0.24), (n * 0.20, n * 0.52)], fill=WHITE)


def captions(d, n):
    d.rounded_rectangle([n * 0.08, n * 0.2, n * 0.92, n * 0.8], n * 0.12, outline=WHITE, width=int(n * 0.08))
    f = font(int(n * 0.36))
    bb = d.textbbox((0, 0), "CC", font=f)
    d.text(((n - (bb[2] - bb[0])) / 2 - bb[0], (n - (bb[3] - bb[1])) / 2 - bb[1]), "CC", font=f, fill=WHITE)


def skip30(forward, secs=30):
    label = str(secs)

    def draw(d, n):
        w = int(n * 0.08)
        box = [n * 0.1, n * 0.1, n * 0.9, n * 0.9]
        if forward:
            d.arc(box, -60, 250, fill=WHITE, width=w)
            d.polygon([(n * 0.62, n * 0.02), (n * 0.86, n * 0.16), (n * 0.6, n * 0.3)], fill=WHITE)
        else:
            d.arc(box, -70, 240, fill=WHITE, width=w)
            d.polygon([(n * 0.38, n * 0.02), (n * 0.14, n * 0.16), (n * 0.4, n * 0.3)], fill=WHITE)
        f = font(int(n * 0.34))
        bb = d.textbbox((0, 0), label, font=f)
        d.text(((n - (bb[2] - bb[0])) / 2 - bb[0], (n - (bb[3] - bb[1])) / 2 - bb[1] + n * 0.03), label, font=f, fill=WHITE)
    return draw


def prev_track(d, n):
    d.rectangle([n * 0.2, n * 0.22, n * 0.3, n * 0.78], fill=WHITE)
    d.polygon([(n * 0.8, n * 0.22), (n * 0.8, n * 0.78), (n * 0.32, n * 0.5)], fill=WHITE)


def next_track(d, n):
    d.polygon([(n * 0.2, n * 0.22), (n * 0.2, n * 0.78), (n * 0.68, n * 0.5)], fill=WHITE)
    d.rectangle([n * 0.7, n * 0.22, n * 0.8, n * 0.78], fill=WHITE)


def chapter_prev(d, n):
    # backward.end.alt: a bar and two triangles pointing left (previous chapter; prev_track is the episode)
    d.rectangle([n * 0.12, n * 0.26, n * 0.2, n * 0.74], fill=WHITE)
    d.polygon([(n * 0.54, n * 0.26), (n * 0.54, n * 0.74), (n * 0.22, n * 0.5)], fill=WHITE)
    d.polygon([(n * 0.88, n * 0.26), (n * 0.88, n * 0.74), (n * 0.56, n * 0.5)], fill=WHITE)


def chapter_next(d, n):
    d.polygon([(n * 0.12, n * 0.26), (n * 0.12, n * 0.74), (n * 0.44, n * 0.5)], fill=WHITE)
    d.polygon([(n * 0.46, n * 0.26), (n * 0.46, n * 0.74), (n * 0.78, n * 0.5)], fill=WHITE)
    d.rectangle([n * 0.8, n * 0.26, n * 0.88, n * 0.74], fill=WHITE)


def episodes(d, n):
    w = int(n * 0.07)
    d.rounded_rectangle([n * 0.14, n * 0.36, n * 0.86, n * 0.86], n * 0.08, outline=WHITE, width=w)
    d.line([(n * 0.24, n * 0.25), (n * 0.76, n * 0.25)], fill=WHITE, width=w)
    d.line([(n * 0.34, n * 0.14), (n * 0.66, n * 0.14)], fill=WHITE, width=w)


def subtitles(d, n):
    w = int(n * 0.07)
    d.rounded_rectangle([n * 0.1, n * 0.16, n * 0.9, n * 0.72], n * 0.12, outline=WHITE, width=w)
    d.polygon([(n * 0.3, n * 0.68), (n * 0.48, n * 0.68), (n * 0.28, n * 0.88)], fill=WHITE)
    d.line([(n * 0.26, n * 0.38), (n * 0.56, n * 0.38)], fill=WHITE, width=w)
    d.line([(n * 0.62, n * 0.38), (n * 0.74, n * 0.38)], fill=WHITE, width=w)
    d.line([(n * 0.26, n * 0.52), (n * 0.40, n * 0.52)], fill=WHITE, width=w)
    d.line([(n * 0.46, n * 0.52), (n * 0.74, n * 0.52)], fill=WHITE, width=w)


def waveform(d, n):
    w = n * 0.07
    hs = [0.2, 0.42, 0.66, 0.42, 0.56, 0.3]
    for i, h in enumerate(hs):
        x = n * (0.16 + i * 0.136)
        d.rounded_rectangle([x - w / 2, n * (0.5 - h / 2), x + w / 2, n * (0.5 + h / 2)], w / 2, fill=WHITE)


def quality(d, n):
    d.rounded_rectangle([n * 0.06, n * 0.2, n * 0.94, n * 0.8], n * 0.12, outline=WHITE, width=int(n * 0.07))
    f = font(int(n * 0.36))
    bb = d.textbbox((0, 0), "HD", font=f)
    d.text(((n - (bb[2] - bb[0])) / 2 - bb[0], (n - (bb[3] - bb[1])) / 2 - bb[1]), "HD", font=f, fill=WHITE)


def chapters_icon(d, n):
    # list.bullet.rectangle: a rounded box with three bullet + line rows
    w = int(n * 0.07)
    d.rounded_rectangle([n * 0.06, n * 0.14, n * 0.94, n * 0.86], n * 0.12, outline=WHITE, width=w)
    for y in (0.34, 0.5, 0.66):
        d.ellipse([n * 0.2, n * (y - 0.045), n * 0.29, n * (y + 0.045)], fill=WHITE)
        d.line([(n * 0.36, n * y), (n * 0.8, n * y)], fill=WHITE, width=w)


def eye(d, n):
    import math
    def lens(scale):
        pts = []
        for i in range(41):
            x = -1 + i / 20
            y = 0.62 * math.cos(x * math.pi / 2)
            pts.append((n / 2 + x * n * 0.44 * scale, n / 2 - y * n * 0.44 * scale))
        for i in range(41):
            x = 1 - i / 20
            y = 0.62 * math.cos(x * math.pi / 2)
            pts.append((n / 2 + x * n * 0.44 * scale, n / 2 + y * n * 0.44 * scale))
        return pts
    d.polygon(lens(1.0), fill=WHITE)
    d.polygon(lens(0.78), fill=(0, 0, 0, 0))
    d.ellipse([n * 0.37, n * 0.37, n * 0.63, n * 0.63], fill=WHITE)


def eye_slash(d, n):
    eye(d, n)
    d.line([(n * 0.14, n * 0.14), (n * 0.86, n * 0.86)], fill=(0, 0, 0, 0), width=int(n * 0.2))
    d.line([(n * 0.14, n * 0.14), (n * 0.86, n * 0.86)], fill=WHITE, width=int(n * 0.08))


def star(d, n):
    import math
    pts = []
    for i in range(10):
        r = n * (0.46 if i % 2 == 0 else 0.19)
        a = math.pi / 2 + i * math.pi / 5
        pts.append((n / 2 + r * math.cos(a), n * 0.53 - r * math.sin(a)))
    d.polygon(pts, fill=WHITE)


def chevron_down(d, n):
    d.line([(n * 0.22, n * 0.38), (n * 0.5, n * 0.66), (n * 0.78, n * 0.38)], fill=WHITE, width=int(n * 0.12), joint="curve")


def home_icon(d, n):
    w = int(n * 0.08)
    d.polygon([(n * 0.5, n * 0.1), (n * 0.92, n * 0.48), (n * 0.08, n * 0.48)], fill=WHITE)
    d.rectangle([n * 0.2, n * 0.44, n * 0.8, n * 0.9], fill=WHITE)
    d.rectangle([n * 0.42, n * 0.6, n * 0.58, n * 0.9], fill=(0, 0, 0, 0))


def search_icon(d, n):
    w = int(n * 0.1)
    d.ellipse([n * 0.12, n * 0.12, n * 0.66, n * 0.66], outline=WHITE, width=w)
    d.line([(n * 0.6, n * 0.6), (n * 0.88, n * 0.88)], fill=WHITE, width=int(n * 0.12))


def radiowaves(d, n):
    w = int(n * 0.08)
    d.ellipse([n * 0.41, n * 0.41, n * 0.59, n * 0.59], fill=WHITE)
    for r, a in ((0.24, 0), (0.4, 0)):
        box = [n * (0.5 - r), n * (0.5 - r), n * (0.5 + r), n * (0.5 + r)]
        d.arc(box, 140, 220, fill=WHITE, width=w)
        d.arc(box, -40, 40, fill=WHITE, width=w)


def clock_icon(d, n):
    w = int(n * 0.08)
    d.ellipse([n * 0.1, n * 0.1, n * 0.9, n * 0.9], outline=WHITE, width=w)
    d.line([(n * 0.5, n * 0.24), (n * 0.5, n * 0.52), (n * 0.68, n * 0.64)], fill=WHITE, width=w, joint="curve")


def film_icon(d, n):
    w = int(n * 0.07)
    d.rounded_rectangle([n * 0.12, n * 0.16, n * 0.88, n * 0.84], n * 0.06, outline=WHITE, width=w)
    d.line([(n * 0.32, n * 0.16), (n * 0.32, n * 0.84)], fill=WHITE, width=w)
    d.line([(n * 0.68, n * 0.16), (n * 0.68, n * 0.84)], fill=WHITE, width=w)
    for y in (0.38, 0.62):
        d.line([(n * 0.12, n * y), (n * 0.32, n * y)], fill=WHITE, width=w)
        d.line([(n * 0.68, n * y), (n * 0.88, n * y)], fill=WHITE, width=w)


def tv_icon(d, n):
    w = int(n * 0.07)
    d.rounded_rectangle([n * 0.08, n * 0.18, n * 0.92, n * 0.74], n * 0.06, outline=WHITE, width=w)
    d.line([(n * 0.32, n * 0.86), (n * 0.68, n * 0.86)], fill=WHITE, width=w)


def folder_icon(d, n):
    w = int(n * 0.07)
    d.polygon([(n * 0.1, n * 0.22), (n * 0.4, n * 0.22), (n * 0.48, n * 0.32), (n * 0.9, n * 0.32), (n * 0.9, n * 0.82), (n * 0.1, n * 0.82)], outline=WHITE)
    d.line([(n * 0.1, n * 0.22), (n * 0.4, n * 0.22), (n * 0.48, n * 0.32), (n * 0.9, n * 0.32), (n * 0.9, n * 0.82), (n * 0.1, n * 0.82), (n * 0.1, n * 0.22)], fill=WHITE, width=w, joint="curve")


def gear_icon(d, n):
    import math
    pts = []
    for i in range(16):
        r = n * (0.44 if i % 2 == 0 else 0.34)
        a = i * math.pi / 8
        pts.append((n / 2 + r * math.cos(a), n / 2 + r * math.sin(a)))
    d.polygon(pts, fill=WHITE)
    d.ellipse([n * 0.36, n * 0.36, n * 0.64, n * 0.64], fill=(0, 0, 0, 0))


def house_outline(d, n):
    w = int(n * 0.07)
    d.line([(n * 0.1, n * 0.48), (n * 0.5, n * 0.12), (n * 0.9, n * 0.48)], fill=WHITE, width=w, joint="curve")
    d.line([(n * 0.22, n * 0.4), (n * 0.22, n * 0.88), (n * 0.78, n * 0.88), (n * 0.78, n * 0.4)], fill=WHITE, width=w, joint="curve")
    d.rectangle([n * 0.43, n * 0.62, n * 0.57, n * 0.88], fill=WHITE)


def palette_icon(d, n):
    w = int(n * 0.07)
    d.ellipse([n * 0.08, n * 0.12, n * 0.92, n * 0.88], outline=WHITE, width=w)
    d.ellipse([n * 0.56, n * 0.56, n * 0.78, n * 0.78], fill=(0, 0, 0, 0), outline=WHITE, width=w)
    for x, y in ((0.3, 0.36), (0.5, 0.26), (0.7, 0.36), (0.26, 0.58)):
        d.ellipse([n * (x - 0.06), n * (y - 0.06), n * (x + 0.06), n * (y + 0.06)], fill=WHITE)


def grid_icon(d, n):
    w = int(n * 0.07)
    for x, y in ((0.12, 0.12), (0.54, 0.12), (0.12, 0.54), (0.54, 0.54)):
        d.rounded_rectangle([n * x, n * y, n * (x + 0.34), n * (y + 0.34)], n * 0.06, outline=WHITE, width=w)


def playrect_icon(d, n):
    w = int(n * 0.07)
    d.rounded_rectangle([n * 0.08, n * 0.16, n * 0.92, n * 0.84], n * 0.1, outline=WHITE, width=w)
    d.polygon([(n * 0.42, n * 0.34), (n * 0.42, n * 0.66), (n * 0.66, n * 0.5)], fill=WHITE)


def server_icon(d, n):
    w = int(n * 0.07)
    for y in (0.14, 0.42, 0.7):
        d.rounded_rectangle([n * 0.1, n * y, n * 0.9, n * (y + 0.2)], n * 0.05, outline=WHITE, width=w)
        d.ellipse([n * 0.7, n * (y + 0.07), n * 0.77, n * (y + 0.14)], fill=WHITE)


def remote_icon(d, n):
    w = int(n * 0.07)
    d.rounded_rectangle([n * 0.3, n * 0.06, n * 0.7, n * 0.94], n * 0.14, outline=WHITE, width=w)
    d.ellipse([n * 0.41, n * 0.2, n * 0.59, n * 0.38], outline=WHITE, width=w)
    for y in (0.52, 0.66, 0.8):
        d.ellipse([n * 0.44, n * (y - 0.035), n * 0.56, n * (y + 0.035)], fill=WHITE)


def info_ring(d, n):
    w = int(n * 0.07)
    d.ellipse([n * 0.08, n * 0.08, n * 0.92, n * 0.92], outline=WHITE, width=w)
    d.ellipse([n * 0.45, n * 0.24, n * 0.55, n * 0.34], fill=WHITE)
    d.rounded_rectangle([n * 0.45, n * 0.42, n * 0.55, n * 0.74], n * 0.03, fill=WHITE)


def bubble_icon(d, n):
    w = int(n * 0.07)
    d.rounded_rectangle([n * 0.08, n * 0.12, n * 0.92, n * 0.7], n * 0.12, outline=WHITE, width=w)
    d.polygon([(n * 0.26, n * 0.66), (n * 0.44, n * 0.66), (n * 0.24, n * 0.88)], fill=WHITE)
    for y in (0.32, 0.48):
        d.line([(n * 0.24, n * y), (n * 0.76, n * y)], fill=WHITE, width=w)


# ---- v1.4 Glass3D look (Cove for macOS Classic/Glass3DTokens.swift, ClassicPill.swift; review4/design.md §3).
# Clear glass = black 30 % + a top-lit white sheen (12 -> 3 %) + a gradient rim (35 -> 8 -> 20 %) + a 22 % outline.
# The accent pill is layered (a horizontal fade can't live in a 9-patch): dark base, accent-tinted left cap,
# stretched fade strip and right cap, an accent rim, a white top shine and an accent bottom line.
# Focus is the "fogged mirror": white 10 -> 16 -> 24 % settling low with a lit top rim, plus the white ring.
G3_DARK = (0, 0, 0, 77)
G3_OUTLINE = (255, 255, 255, 56)
G3_TINT_L = 170   # accent fill alpha at the left end of the Play pill (67 %)
G3_TINT_R = 20    # ... and at the right end (8 %)


def vfill(w, h, radius, stops, rgb=(255, 255, 255)):
    """A rounded shape filled with a vertical alpha ramp (drawn at 4x)."""
    f = ramp(stops)
    grad = Image.new("RGBA", (w * S, h * S))
    for y in range(h * S):
        a = int(round(f(y / (h * S - 1))))
        ImageDraw.Draw(grad).line([(0, y), (w * S, y)], fill=rgb + (a,))
    m = Image.new("L", (w * S, h * S), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius * S, fill=255)
    out = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    out.paste(grad, (0, 0), m)
    return out


def vrim(w, h, radius, width, stops):
    """A rounded outline whose alpha follows a vertical ramp (top-lit rim), at 4x."""
    f = ramp(stops)
    m = Image.new("L", (w * S, h * S), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius * S, outline=255, width=width * S)
    out = Image.new("RGBA", (w * S, h * S), (255, 255, 255, 0))
    px = out.load()
    mp = m.load()
    for y in range(h * S):
        a = f(y / (h * S - 1))
        for x in range(w * S):
            if mp[x, y]:
                px[x, y] = (255, 255, 255, int(round(a * mp[x, y] / 255)))
    return out


def layered(w, h, layers):
    out = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    for layer in layers:
        out = Image.alpha_composite(out, layer)
    return down(out, w, h)


def glass3d(w, h, radius):
    """Clear glass with the 22 % outline (Mac ClassicClearGlass + ClassicGlassBacking + glass3DRoundOutline)."""
    base = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    ImageDraw.Draw(base).rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius * S, fill=G3_DARK)
    return layered(w, h, [base, vfill(w, h, radius, [(0, 31), (1, 8)]),
                          vrim(w, h, radius, 2, [(0, 110), (0.5, 56), (1, 70)])])


def fog(w, h, radius, rim=True, ring_w=0):
    """The fogged-mirror focus: milky white settling low, a lit 2 px top rim (and optionally a white ring)."""
    layers = [vfill(w, h, radius, [(0, 26), (0.55, 41), (1, 61)])]
    if rim:
        layers.append(vrim(w, h, radius, 2, [(0, 150), (0.35, 0), (1, 0)]))
    if ring_w:
        r = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
        ImageDraw.Draw(r).rounded_rectangle([0, 0, w * S - 1, h * S - 1], radius * S, outline=WHITE, width=ring_w * S)
        layers.append(r)
    return layered(w, h, layers)


def half_disc(h, alpha, left):
    """A pill end cap: half of a circle of diameter h, white at alpha (tinted with the accent at runtime)."""
    w = h // 2
    big = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    if left:
        d.ellipse([0, 0, h * S - 1, h * S - 1], fill=(255, 255, 255, alpha))
    else:
        d.ellipse([-w * S, 0, w * S - 1, h * S - 1], fill=(255, 255, 255, alpha))
    return down(big, w, h)


def edge_card(size, radius, corner):
    """The Mac's light glass edge (ClassicLightCard): a 2 px rim, bright (90 %) in the top-left and bottom-right
    corners and fading to about 10 % inside the corner patch, so the stretched sides stay faint."""
    big = Image.new("L", (size * S, size * S), 0)
    ImageDraw.Draw(big).rounded_rectangle([0, 0, size * S - 1, size * S - 1], radius * S, outline=255, width=2 * S)
    m = down(big.convert("RGBA"), size, size).split()[0]
    out = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    px = out.load()
    mp = m.load()
    for y in range(size):
        for x in range(size):
            if not mp[x, y]:
                continue
            tl = (x + y) / float(corner)
            br = ((size - 1 - x) + (size - 1 - y)) / float(corner)
            near = min(tl, br)
            v = 26 + (230 - 26) * max(0.0, 1 - near)
            px[x, y] = (255, 255, 255, int(round(v * mp[x, y] / 255)))
    return out


def glow(size, inset, radius, blur):
    """A soft white glow (tinted with the accent at runtime) around a card: Mac HoverGlow."""
    img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([inset - 6, inset - 6, size - 1 - inset + 6, size - 1 - inset + 6], radius + 6, fill=255)
    img.putalpha(m.filter(ImageFilter.GaussianBlur(blur)))
    return img


def check_circle(filled):
    def draw(d, n):
        if filled:
            d.ellipse([n * 0.06, n * 0.06, n * 0.94, n * 0.94], fill=WHITE)
            d.line([(n * 0.28, n * 0.52), (n * 0.44, n * 0.68), (n * 0.72, n * 0.36)], fill=(0, 0, 0, 0), width=int(n * 0.11), joint="curve")
        else:
            d.ellipse([n * 0.06, n * 0.06, n * 0.94, n * 0.94], outline=WHITE, width=int(n * 0.08))
            d.line([(n * 0.28, n * 0.52), (n * 0.44, n * 0.68), (n * 0.72, n * 0.36)], fill=WHITE, width=int(n * 0.09), joint="curve")
    return draw


def heart_outline(d, n):
    heart(d, n)
    k = 0.13
    d.ellipse([n * (0.1 + k), n * (0.16 + k), n * (0.52 - k * 0.5), n * (0.58 - k * 0.5)], fill=(0, 0, 0, 0))
    d.ellipse([n * (0.48 + k * 0.5), n * (0.16 + k), n * (0.9 - k), n * (0.58 - k * 0.5)], fill=(0, 0, 0, 0))
    d.polygon([(n * 0.24, n * 0.47), (n * 0.76, n * 0.47), (n * 0.5, n * 0.75)], fill=(0, 0, 0, 0))
    d.rectangle([n * 0.3, n * 0.36, n * 0.7, n * 0.5], fill=(0, 0, 0, 0))


def draw_glass3d():
    save(nine(glass3d(60, 60, 30)), "g3_capsule.9.png")
    save(glass3d(69, 69, 34), "g3_circle_69.png")
    save(nine(shape(60, 60, 30, (0, 0, 0, 90))), "g3_dark_pill.9.png")
    save(half_disc(72, G3_TINT_L, True), "g3_tint_cap_l.png")
    save(strip(512, 4, ramp([(0, G3_TINT_L), (1, G3_TINT_R)]), (255, 255, 255), vertical=False), "g3_tint_fade.png")
    save(half_disc(72, G3_TINT_R, False), "g3_tint_cap_r.png")
    save(nine(ring(60, 60, 30, 2, WHITE)), "g3_pill_rim.9.png")
    save(strip(512, 4, ramp([(0, 0), (0.5, 140), (1, 0)]), (255, 255, 255), vertical=False), "g3_pill_shine.png")
    save(nine(fog(60, 60, 30)), "fog_capsule.9.png")
    # (a 9-patch can't shrink below its corners: pills 44-59 px high use the 44 px pieces and a 60 px ring)
    save(nine(glass3d(44, 44, 22)), "g3_capsule_44.9.png")
    save(nine(fog(44, 44, 22)), "fog_capsule_44.9.png")
    save(nine(ring(60, 60, 30, 4, WHITE)), "focus_ring_pill_60.9.png")
    save(fog(69, 69, 34), "fog_circle_69.png")
    save(nine(fog(36, 36, 12)), "fog_r12.9.png")
    # list focus bar (Picker, menus): fog with the white ring baked in, so a LabelList shows fog + ring
    save(nine(fog(36, 36, 12, rim=False, ring_w=3)), "fog_ring_r12.9.png")
    # cards: the light glass edge, the top sheen, r12 corners, a ring for r12 cards (6 px gap) and the glow
    save(nine(edge_card(84, 12, 40)), "card_edge_r12.9.png")
    save(strip(4, 128, ramp([(0, 31), (1, 0)]), (255, 255, 255)), "sheen_top.png")
    for name, rgb in BGS.items():
        save(nine(corner_mask(40, 12, rgb)), "mask_r12_%s.9.png" % name)
        save(nine(shape(60, 60, 27, rgb + (230,))), "panel_r27_%s.9.png" % name)
    save(nine(vrim(60, 60, 27, 2, [(0, 89), (0.5, 20), (1, 51)]).resize((60, 60), Image.LANCZOS)), "panel_rim_r27.9.png")
    save(nine(ring(60, 60, 18, 4, WHITE)), "focus_ring_r18.9.png")
    save(nine(glow(96, 24, 12, 10)), "glow_r12.9.png")
    # thumbnails (Continue Watching, episodes): top black 55 % -> clear, bottom clear -> 70 % (ThumbnailScrim)
    save(strip(4, 256, ramp([(0, 140), (0.38, 0), (0.55, 0), (1, 179)])), "scrim_thumb.png")
    # Settings: r21 cards (white 8 % + 15 % edge) and the selected tab (white 10 % + 22 % edge, r15)
    save(nine(shape(48, 48, 21, (255, 255, 255, 20), (255, 255, 255, 38), 2)), "card_r21.9.png")
    save(nine(shape(48, 48, 15, (255, 255, 255, 26), (255, 255, 255, 56), 2)), "tab_sel_r15.9.png")
    # sidebar: the current page as an accent band (white, tinted 40 %) with a white 25 % hairline
    save(nine(shape(48, 48, 18, WHITE)), "band_r18.9.png")
    save(nine(ring(48, 48, 18, 2, (255, 255, 255, 64))), "band_rim_r18.9.png")
    save(nine(ring(24, 24, 6, 2, (255, 255, 255, 191))), "outline_box_r6.9.png")
    icon("checkc", 28, check_circle(False))
    icon("checkcf", 28, check_circle(True))
    icon("hearto", 28, heart_outline)


def draw_all():
    draw_glass3d()
    save(nine(shape(60, 60, 30, GLASS_FILL, GLASS_STROKE, 2)), "glass_pill.9.png")
    save(nine(shape(48, 48, 24, (255, 255, 255, 56))), "sel_pill.9.png")
    save(nine(shape(48, 48, 24, WHITE)), "white_pill.9.png")
    save(nine(ring(84, 84, 42, 4, WHITE)), "focus_ring_pill.9.png")
    save(nine(shape(36, 36, 12, WHITE)), "white_rr12.9.png")
    save(nine(shape(48, 48, 21, (38, 38, 38, 235))), "panel_r21.9.png")
    save(circle(69, GLASS_FILL, GLASS_STROKE, 2), "glass_circle_69.png")
    save(circle(69, WHITE), "white_circle_69.png")
    # (v1.1.1 VD-6) the focus ring of a 69 px circle button: 4 px stroke, 4 px gap, drawn at [-8, -8]
    save(ring_circle(85, 4), "focus_ring_circle_85.png")
    save(circle(10, WHITE), "dot_10.png")
    save(nine(ring(60, 60, 26, 4, WHITE)), "focus_ring_r26.9.png")
    save(nine(ring(40, 40, 18, 2, (255, 255, 255, 31))), "card_border_r18.9.png")
    save(nine(shadow(96, 24, 18, 14, 153)), "card_shadow.9.png")
    save(circle(36, (0, 0, 0, 179), (255, 255, 255, 217), 2), "badge_circle.png")
    save(nine(shape(36, 36, 18, (0, 0, 0, 179), (255, 255, 255, 217), 2)), "badge_capsule.9.png")
    # (v1.3.2) the watched badge: a white disc tinted with the accent (blendColor), a white edge and a soft shadow
    save(circle(36, WHITE), "badge_watched.png")
    save(ring_circle(36, 2), "badge_watched_ring.png")
    save(shadow(52, 8, 18, 3, 150), "badge_watched_shadow.png")
    for name, rgb in BGS.items():
        save(nine(corner_mask(40, 18, rgb)), "mask_r18_%s.9.png" % name)
        save(circle_mask(144, rgb), "mask_circle_%s_144.png" % name)
        # hero/detail bottom fade: clear for the top half, bg at 60 % by 75 %, solid bg at the bottom
        save(strip(4, 512, ramp([(0, 0), (0.5, 0), (0.75, 153), (1, 255)]), rgb), "scrim_bottom_%s.png" % name)
        # a plain clear -> bg fade (under the rows when the backdrop follows the focused title)
        save(strip(4, 256, ramp([(0, 0), (1, 255)]), rgb), "fade_%s.png" % name)
    # (v1.4 H5) the Mac's left fade: black 75 % -> clear at 60 % of the width (drawn full width)
    save(strip(512, 4, ramp([(0, 191), (0.6, 0), (1, 0)]), vertical=False), "scrim_left.png")
    save(strip(512, 4, ramp([(0, 0), (1, 166)]), vertical=False), "scrim_right.png")
    save(strip(4, 128, ramp([(0, 0), (1, 204)])), "scrim_card.png")
    save(strip(4, 256, ramp([(0, 166), (1, 0)])), "scrim_top.png")
    for size in (48, 28):
        for name, fn in (("play", play), ("plus", plus), ("check", check), ("info", info), ("heart", heart),
                         ("pause", pause), ("restart", restart), ("captions", captions)):
            icon(name, size, fn)
    for name, fn in (("back30", skip30(False)), ("fwd30", skip30(True)), ("prev", prev_track), ("next", next_track),
                     ("episodes", episodes), ("subtitles", subtitles), ("audio", waveform), ("quality", quality),
                     ("chapters", chapters_icon), ("chapprev", chapter_prev), ("chapnext", chapter_next)):
        icon(name, 36, fn)
    # the other jump lengths (Settings → Playback → Jump buttons); 30 is above
    for secs in (10, 15, 60):
        icon("back%d" % secs, 36, skip30(False, secs))
        icon("fwd%d" % secs, 36, skip30(True, secs))
    save(circle(105, GLASS_FILL, (255, 255, 255, 31), 2), "glass_circle_105.png")
    save(circle(105, WHITE), "white_circle_105.png")
    save(circle(56, WHITE), "white_circle_56.png")
    for name, fn in (("eye", eye), ("eyeslash", eye_slash), ("star", star), ("chevron", chevron_down)):
        icon(name, 28, fn)
    icon("film", 28, film_icon)   # details page: Trailer
    save(nine(ring(24, 24, 5, 2, (255, 255, 255, 191))), "outline_box_r4.9.png")
    for name, fn in (("home", home_icon), ("search", search_icon), ("nowplaying", radiowaves), ("clock", clock_icon),
                     ("film", film_icon), ("tv", tv_icon), ("folder", folder_icon), ("gear", gear_icon), ("heart", heart)):
        icon(name, 36, fn)
    for name, fn in (("general", palette_icon), ("home", house_outline), ("libraries", grid_icon), ("subtitles", bubble_icon),
                     ("playback", playrect_icon), ("servers", server_icon), ("remote", remote_icon), ("about", info_ring)):
        icon("tab_" + name, 44, fn)
    icon("server", 36, server_icon)
    # Settings: a section card (white 4 % with an 8 % edge, as on the Mac) and the switch
    save(nine(shape(48, 48, 18, (255, 255, 255, 12), (255, 255, 255, 26), 2)), "card_r18.9.png")
    save(nine(shape(44, 44, 22, WHITE)), "switch_track.9.png")
    # library (v1.1.1): skeleton / placeholder cards with the poster's r18 corners (white, tinted faint at
    # runtime, VD-2) and the 96 px glyphs of an empty page (VD-20)
    save(nine(shape(48, 48, 18, WHITE)), "white_r18.9.png")
    for name, fn in (("film", film_icon), ("tv", tv_icon), ("heart", heart), ("folder", folder_icon)):
        icon(name, 96, fn)
    save(circle(36, WHITE), "switch_knob.png")
    save(circle(70, WHITE), "white_circle_70.png")
    icon("play", 72, play)
    icon("pause", 72, pause)
    # player: big glass circle (pause), scrubber thumb, top/bottom shade, Up next card
    save(circle(210, GLASS_FILL, (255, 255, 255, 31), 2), "glass_circle_210.png")
    save(circle(24, WHITE), "dot_24.png")
    save(strip(4, 512, ramp([(0, 115), (0.33, 0), (0.66, 0), (1, 179)])), "scrim_osd.png")
    save(nine(shape(40, 40, 18, (0, 0, 0, 204))), "panel_dark_r18.9.png")
    # player loading: a faint track and the progress arc (white, tinted with the accent) every 4 %
    for pct in range(0, 101, 4):
        save(arc(132, 8, pct), "load_arc_%03d.png" % pct)
    save(arc(132, 8, 100, (255, 255, 255, 46)), "load_track.png")
    # "Who's watching?" profile picker: avatar circle and its focus ring
    save(circle(240, WHITE), "white_circle_240.png")
    save(ring_circle(256, 7), "ring_circle_256.png")


def sync(src, dst):
    """Copies new and changed files from src to dst and deletes the stale ones; returns the counts."""
    os.makedirs(dst, exist_ok=True)
    made = set(os.listdir(src))
    added, changed, same, removed = [], [], [], []
    for name in sorted(made):
        target = os.path.join(dst, name)
        if not os.path.exists(target):
            added.append(name)
        elif filecmp.cmp(os.path.join(src, name), target, shallow=False):
            same.append(name)
            continue
        else:
            changed.append(name)
        shutil.copyfile(os.path.join(src, name), target)
    for name in sorted(os.listdir(dst)):
        if name not in made and name not in HAND_MADE and os.path.isfile(os.path.join(dst, name)):
            os.remove(os.path.join(dst, name))
            removed.append(name)
    return added, changed, same, removed


def compare(src, dst):
    """--check: what a sync would change, without writing anything."""
    made = set(os.listdir(src))
    have = set(os.listdir(dst)) if os.path.isdir(dst) else set()
    added = sorted(made - have)
    changed = sorted(n for n in made & have if not filecmp.cmp(os.path.join(src, n), os.path.join(dst, n), shallow=False))
    removed = sorted(n for n in have - made - HAND_MADE if os.path.isfile(os.path.join(dst, n)))
    return added, changed, removed


def pinned_pillow():
    try:
        with open(os.path.join(HERE, "requirements.txt")) as f:
            for line in f:
                if line.lower().startswith("pillow=="):
                    return line.split("==", 1)[1].split()[0].rstrip("\\")
    except OSError:
        pass
    return None


def main(argv=None):
    global OUT, FONT
    ap = argparse.ArgumentParser(description="Generate the Glass theme UI images (src/images/ui).")
    ap.add_argument("--font", default=DEFAULT_FONT, help="bold TrueType font for the CC / HD / 10-60 labels (default: %(default)s)")
    ap.add_argument("--out", default=DEFAULT_OUT, help="output folder (default: %(default)s)")
    ap.add_argument("--check", action="store_true", help="don't write: exit 1 if the output folder differs from what the script makes")
    args = ap.parse_args(argv)
    if not os.path.isfile(args.font):
        sys.exit("make-ui-assets: font not found: %s (pass --font /path/to/DejaVuSans-Bold.ttf)" % args.font)
    FONT = args.font
    pin = pinned_pillow()
    if pin and PIL.__version__ != pin:
        print("make-ui-assets: warning: Pillow %s, scripts/requirements.txt pins %s; the PNG bytes may differ"
              % (PIL.__version__, pin), file=sys.stderr)
    with tempfile.TemporaryDirectory(prefix="cove-ui-") as tmp:
        OUT = tmp
        del WRITTEN[:]
        draw_all()
        out = os.path.normpath(args.out)
        if args.check:
            added, changed, removed = compare(tmp, out)
            for label, names in (("missing", added), ("different", changed), ("not generated (stale)", removed)):
                for n in names:
                    print("  %s: %s" % (label, n))
            if added or changed or removed:
                print("make-ui-assets --check: %s is out of date (%d missing, %d different, %d stale); run scripts/make-ui-assets.py"
                      % (out, len(added), len(changed), len(removed)))
                return 1
            print("make-ui-assets --check: %d generated files match %s (+%d hand-made kept)"
                  % (len(WRITTEN), out, len(HAND_MADE & set(os.listdir(out)))))
            return 0
        added, changed, same, removed = sync(tmp, out)
    for label, names in (("new", added), ("changed", changed), ("removed", removed)):
        for n in names:
            print("  %s: %s" % (label, n))
    print("make-ui-assets: generated %d files into %s: %d new, %d changed, %d unchanged, %d stale removed"
          % (len(WRITTEN), out, len(added), len(changed), len(same), len(removed)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
