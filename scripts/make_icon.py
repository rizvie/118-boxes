"""Draws the 1024 app icon for 118 Boxes.

Four chunky specimen boxes on a warm, bright shelf. The name is literal, so the
icon is literal: boxes with stuff glowing inside them.

Why bright rather than the app's navy: an app icon competes on a home screen
full of other children's apps, and a dark tile reads as a utility. The boxes
themselves stay deep so the samples still glow out of them, which is the same
trick the app uses on every element cell.

The four boxes are H, He, Li and Be: literally the top-left corner of the
periodic table, which is where a child starts. Four coloured squares alone
could be any puzzle app, so the symbols do the work of saying what this is.
"118" is not on the icon because it is illegible at 60x60.

Run: python3 scripts/make_icon.py
"""
from PIL import Image, ImageDraw, ImageFilter

S = 1024
CREAM = (255, 243, 224)
INK = (23, 27, 40)

# The first four elements, coloured by family, ordered as they sit on the table.
TILES = [
    ("H",  (79, 216, 255), (198, 243, 255)),   # nonmetal       - cyan
    ("He", (167, 139, 250), (223, 211, 255)),  # noble gas      - violet
    ("Li", (255, 201, 60), (255, 236, 170)),   # alkali metal   - gold
    ("Be", (255, 107, 107), (255, 199, 199)),  # alkaline earth - coral
]


def font(size):
    """SF Rounded if this Mac has it, else something with a similar weight."""
    from PIL import ImageFont
    for path in ("/System/Library/Fonts/SFCompactRounded.ttf",
                 "/System/Library/Fonts/SFNSRounded.ttf",
                 "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
                 "/System/Library/Fonts/Helvetica.ttc"):
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            continue
    return ImageFont.load_default()

img = Image.new("RGB", (S, S), CREAM)

# Soft warm bloom so the flat cream isn't dead.
bloom = Image.new("RGB", (S, S), CREAM)
ImageDraw.Draw(bloom).ellipse([-80, -140, S + 80, S - 200], fill=(255, 255, 250))
img = Image.blend(img, bloom.filter(ImageFilter.GaussianBlur(150)), 0.9)

d = ImageDraw.Draw(img)

M, GAP = 132, 40                      # outer margin, gap between boxes
box_w = (S - 2 * M - GAP) // 2
R = 76                                # corner radius
OUT = 14                              # outline weight
DROP = 20                             # solid bottom edge, the "sticker" depth

for i, (symbol, fill, glow) in enumerate(TILES):
    col, row = i % 2, i // 2
    x0 = M + col * (box_w + GAP)
    y0 = M + row * (box_w + GAP)
    x1, y1 = x0 + box_w, y0 + box_w

    # Solid drop underneath: chunky depth, no soft blur. Reads as pressable.
    d.rounded_rectangle([x0, y0 + DROP, x1, y1 + DROP], radius=R, fill=INK)

    # The box.
    d.rounded_rectangle([x0, y0, x1, y1], radius=R, fill=fill,
                        outline=INK, width=OUT)

    # The sample glowing inside it. Drawn on its own layer so the blur does not
    # bleed over the outline, then masked back into the box.
    layer = Image.new("RGB", (S, S), fill)
    ld = ImageDraw.Draw(layer)
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    rr = box_w // 3
    ld.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=glow)
    layer = layer.filter(ImageFilter.GaussianBlur(34))

    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [x0 + OUT, y0 + OUT, x1 - OUT, y1 - OUT], radius=R - OUT, fill=255)
    img.paste(layer, (0, 0), mask)

    # Re-stroke the outline: the paste above softened it.
    d.rounded_rectangle([x0, y0, x1, y1], radius=R, outline=INK, width=OUT)

    # The symbol, optically centred. Two-letter symbols get a smaller size so
    # "He" and "Be" occupy the same visual width as "H".
    f = font(230 if len(symbol) == 1 else 176)
    bb = d.textbbox((0, 0), symbol, font=f)
    # stroke_width fattens the glyphs. SF Rounded loads at regular weight here,
    # which looks spindly next to 14px box outlines.
    d.text((cx - (bb[2] - bb[0]) / 2 - bb[0],
            cy - (bb[3] - bb[1]) / 2 - bb[1]),
           symbol, font=f, fill=INK, stroke_width=11, stroke_fill=INK)

out = "Sources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
img.convert("RGB").save(out)   # RGB, never RGBA: the App Store rejects alpha.
print(f"wrote {out}  {img.size[0]}x{img.size[1]}")
