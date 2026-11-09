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
    save(strip(4, 128, ramp([(0, 0), (1, 204)])), "scrim_card.png")
    save(strip(4, 256, ramp([(0, 166), (1, 0)])), "scrim_top.png")
    for size in (48, 28):
        for name, fn in (("play", play), ("plus", plus), ("check", check), ("info", info), ("heart", heart)):
            icon(name, size, fn)
    print("wrote", len(os.listdir(OUT)), "files to", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
