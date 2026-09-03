"""Draws the 1024 app icon: a glowing element cell on a dark lab-bench navy."""
from PIL import Image, ImageDraw, ImageFont, ImageFilter

S = 1024
img = Image.new("RGB", (S, S), (11, 14, 22))
d = ImageDraw.Draw(img)

# Soft blue glow behind the cell.
glow = Image.new("RGB", (S, S), (11, 14, 22))
gd = ImageDraw.Draw(glow)
gd.ellipse([170, 150, 854, 834], fill=(28, 62, 130))
glow = glow.filter(ImageFilter.GaussianBlur(130))
img = Image.blend(img, glow, 0.85)
d = ImageDraw.Draw(img)

# The element cell.
box = [212, 212, 812, 812]
d.rounded_rectangle(box, radius=96, fill=(31, 38, 52), outline=(77, 141, 255), width=12)

def font(size, weight="Bold"):
    for path in (f"/System/Library/Fonts/SFCompactRounded.ttf",
                 f"/System/Library/Fonts/SFNSRounded.ttf",
                 f"/System/Library/Fonts/Supplemental/Arial {weight}.ttf",
                 "/System/Library/Fonts/Helvetica.ttc"):
        try:
            return ImageFont.truetype(path, size)
        except Exception:
            continue
    return ImageFont.load_default()

def centred(text, f, cy, fill):
    l, t, r, b = d.textbbox((0, 0), text, font=f)
    d.text(((S - (r - l)) / 2 - l, cy - (b - t) / 2 - t), text, font=f, fill=fill)

centred("2", font(96), 330, (138, 147, 166))
centred("El", font(280), 540, (243, 246, 251))
centred("ELEMENTARY", font(58), 712, (77, 141, 255))

img.save("scripts/icon-1024.png")
img.save("Sources/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
print("icon written")
