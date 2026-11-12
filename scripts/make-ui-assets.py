#!/usr/bin/env python3
"""Generates the Glass theme UI images in src/images/ui (run: python3 scripts/make-ui-assets.py; needs Pillow).

Roku has no blur, clipping or gradients, so they are faked with small PNGs:
- *.9.png are 9-patches: content plus a 1px border whose black top/left pixels mark the stretchable middle.
- Corner and circle masks are painted in the page background colour (one file per background choice).
- Gradient strips are tiny and get stretched by the Poster node.
Shapes are drawn at 4x and scaled down for smooth edges. Colours follow Cove for macOS (Sources/Views.swift).
"""
import os
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "src", "images", "ui")
S = 4  # supersampling
BGS = {"black": (0, 0, 0), "charcoal": (28, 28, 28), "navy": (10, 18, 43), "plum": (31, 13, 38), "forest": (10, 31, 20)}
GLASS_FILL = (28, 28, 28, 179)
GLASS_STROKE = (255, 255, 255, 38)
WHITE = (255, 255, 255, 255)


def save(img, name):
    img.save(os.path.join(OUT, name), optimize=True)


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
    from PIL import ImageFont
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", int(n * 0.36))
    bb = d.textbbox((0, 0), "CC", font=f)
    d.text(((n - (bb[2] - bb[0])) / 2 - bb[0], (n - (bb[3] - bb[1])) / 2 - bb[1]), "CC", font=f, fill=WHITE)


def skip30(forward):
    def draw(d, n):
        from PIL import ImageFont
        w = int(n * 0.08)
        box = [n * 0.1, n * 0.1, n * 0.9, n * 0.9]
        if forward:
            d.arc(box, -60, 250, fill=WHITE, width=w)
            d.polygon([(n * 0.62, n * 0.02), (n * 0.86, n * 0.16), (n * 0.6, n * 0.3)], fill=WHITE)
        else:
            d.arc(box, -70, 240, fill=WHITE, width=w)
            d.polygon([(n * 0.38, n * 0.02), (n * 0.14, n * 0.16), (n * 0.4, n * 0.3)], fill=WHITE)
        f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", int(n * 0.34))
        bb = d.textbbox((0, 0), "30", font=f)
        d.text(((n - (bb[2] - bb[0])) / 2 - bb[0], (n - (bb[3] - bb[1])) / 2 - bb[1] + n * 0.03), "30", font=f, fill=WHITE)
    return draw


def prev_track(d, n):
    d.rectangle([n * 0.2, n * 0.22, n * 0.3, n * 0.78], fill=WHITE)
    d.polygon([(n * 0.8, n * 0.22), (n * 0.8, n * 0.78), (n * 0.32, n * 0.5)], fill=WHITE)


def next_track(d, n):
    d.polygon([(n * 0.2, n * 0.22), (n * 0.2, n * 0.78), (n * 0.68, n * 0.5)], fill=WHITE)
    d.rectangle([n * 0.7, n * 0.22, n * 0.8, n * 0.78], fill=WHITE)


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
    from PIL import ImageFont
    d.rounded_rectangle([n * 0.06, n * 0.2, n * 0.94, n * 0.8], n * 0.12, outline=WHITE, width=int(n * 0.07))
    f = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", int(n * 0.36))
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


def main():
    os.makedirs(OUT, exist_ok=True)
    save(nine(shape(60, 60, 30, GLASS_FILL, GLASS_STROKE, 2)), "glass_pill.9.png")
    save(nine(shape(48, 48, 24, (255, 255, 255, 56))), "sel_pill.9.png")
    save(nine(shape(48, 48, 24, WHITE)), "white_pill.9.png")
    save(nine(ring(84, 84, 42, 4, WHITE)), "focus_ring_pill.9.png")
    save(nine(shape(36, 36, 12, WHITE)), "white_rr12.9.png")
    save(nine(shape(48, 48, 21, (38, 38, 38, 235))), "panel_r21.9.png")
    save(circle(69, GLASS_FILL, GLASS_STROKE, 2), "glass_circle_69.png")
    save(circle(69, WHITE), "white_circle_69.png")
    save(circle(10, WHITE), "dot_10.png")
    save(nine(ring(60, 60, 26, 4, WHITE)), "focus_ring_r26.9.png")
    save(nine(ring(40, 40, 18, 2, (255, 255, 255, 31))), "card_border_r18.9.png")
    save(nine(shadow(96, 24, 18, 14, 153)), "card_shadow.9.png")
    save(circle(36, (0, 0, 0, 179), (255, 255, 255, 217), 2), "badge_circle.png")
    save(nine(shape(36, 36, 18, (0, 0, 0, 179), (255, 255, 255, 217), 2)), "badge_capsule.9.png")
    for name, rgb in BGS.items():
        save(nine(corner_mask(40, 18, rgb)), "mask_r18_%s.9.png" % name)
        save(circle_mask(144, rgb), "mask_circle_%s_144.png" % name)
        # hero/detail bottom fade: clear for the top half, bg at 60 % by 75 %, solid bg at the bottom
        save(strip(4, 512, ramp([(0, 0), (0.5, 0), (0.75, 153), (1, 255)]), rgb), "scrim_bottom_%s.png" % name)
        # a plain clear -> bg fade (under the rows when the backdrop follows the focused title)
        save(strip(4, 256, ramp([(0, 0), (1, 255)]), rgb), "fade_%s.png" % name)
    save(strip(512, 4, ramp([(0, 166), (1, 0)]), vertical=False), "scrim_left.png")
    save(strip(512, 4, ramp([(0, 0), (1, 166)]), vertical=False), "scrim_right.png")
    save(strip(4, 128, ramp([(0, 0), (1, 204)])), "scrim_card.png")
    save(strip(4, 256, ramp([(0, 166), (1, 0)])), "scrim_top.png")
    for size in (48, 28):
        for name, fn in (("play", play), ("plus", plus), ("check", check), ("info", info), ("heart", heart),
                         ("pause", pause), ("restart", restart), ("captions", captions)):
            icon(name, size, fn)
    for name, fn in (("back30", skip30(False)), ("fwd30", skip30(True)), ("prev", prev_track), ("next", next_track),
                     ("episodes", episodes), ("subtitles", subtitles), ("audio", waveform), ("quality", quality),
                     ("chapters", chapters_icon)):
        icon(name, 36, fn)
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
    print("wrote", len(os.listdir(OUT)), "files to", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
