"""Draws the 1280x640 social preview card for GitHub, LinkedIn and Slack.

GitHub wants 2:1. The card pairs the app's own palette with a real screenshot,
because a card that is only type tells you nothing about a visual app.

Run: python3 scripts/make_social.py
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import pathlib

W, H = 1280, 640
CREAM = (255, 244, 230)
INK = (23, 27, 40)
MUTED = (107, 99, 85)

TILES = [("H", (79, 216, 255)), ("He", (167, 139, 250)),
         ("Li", (255, 201, 60)), ("Be", (255, 107, 107))]


def font(size, bold=True):
    for p in ("/System/Library/Fonts/SFCompactRounded.ttf",
              "/System/Library/Fonts/SFNSRounded.ttf",
              "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
              "/System/Library/Fonts/Helvetica.ttc"):
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            continue
    return ImageFont.load_default()


img = Image.new("RGB", (W, H), CREAM)
bloom = Image.new("RGB", (W, H), CREAM)
ImageDraw.Draw(bloom).ellipse([-200, -260, W + 200, H - 120], fill=(255, 255, 251))
img = Image.blend(img, bloom.filter(ImageFilter.GaussianBlur(160)), 0.9)
d = ImageDraw.Draw(img)

# ---- right: the phone, tilted slightly so the card does not feel like a form
shot = Image.open("docs/screenshots/picture-round.png").convert("RGB")
ph_h = 520
ph_w = int(shot.width * ph_h / shot.height)
shot = shot.resize((ph_w, ph_h), Image.LANCZOS)

card = Image.new("RGBA", (ph_w + 16, ph_h + 16), (0, 0, 0, 0))
cd = ImageDraw.Draw(card)
cd.rounded_rectangle([0, 0, ph_w + 15, ph_h + 15], radius=44, fill=INK + (255,))
mask = Image.new("L", (ph_w, ph_h), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, ph_w - 1, ph_h - 1], radius=36, fill=255)
card.paste(shot, (8, 8), mask)

card = card.rotate(-6, resample=Image.BICUBIC, expand=True)
# A small bleed off the right edge, deliberate; enough of the phone stays on
# canvas that the answer buttons read as whole words.
px, py = W - card.width + 18, (H - card.height) // 2

# Hard ink offset rather than a blur. The app uses solid bottom edges on every
# card, and a soft shadow both looked off-brand and left a grey rectangle where
# the rotated bounding box blurred outward.
img.paste(INK, (px + 14, py + 16), card.split()[3])
img.paste(card.convert("RGB"), (px, py), card.split()[3])
d = ImageDraw.Draw(img)

# ---- left: tiles, name, line
x0, y = 76, 150
for i, (sym, col) in enumerate(TILES):
    s = 74
    bx = x0 + i * (s + 14)
    d.rounded_rectangle([bx, y + 6, bx + s, y + s + 6], radius=20, fill=INK)
    d.rounded_rectangle([bx, y, bx + s, y + s], radius=20, fill=col, outline=INK, width=5)
    f = font(34 if len(sym) == 1 else 28)
    bb = d.textbbox((0, 0), sym, font=f)
    d.text((bx + s / 2 - (bb[2] - bb[0]) / 2 - bb[0],
            y + s / 2 - (bb[3] - bb[1]) / 2 - bb[1]),
           sym, font=f, fill=INK, stroke_width=1, stroke_fill=INK)

f_title = font(92)
d.text((x0 - 4, y + 118), "118 Boxes", font=f_title, fill=INK, stroke_width=1, stroke_fill=INK)

f_sub = font(30)
d.text((x0, y + 232), "A periodic table for children", font=f_sub, fill=INK)
d.text((x0, y + 274), "reading ahead of their vocabulary.", font=f_sub, fill=INK)

f_meta = font(23)
d.text((x0, y + 340), "Every name spoken · every sample drawn · no network",
       font=f_meta, fill=MUTED)

out = pathlib.Path("docs/social-preview.png")
img.convert("RGB").save(out, "PNG", optimize=True)
print(f"wrote {out}  {img.size[0]}x{img.size[1]}  {out.stat().st_size // 1024}KB")
