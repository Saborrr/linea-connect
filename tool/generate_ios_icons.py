"""Generate Linea's iOS asset catalog. Requires Pillow; no user assets or data."""
import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Same geometry and palette as Runner/AppIcon.icon/Assets/logo.svg. Render at
# four times the largest output size to keep the rounded strokes smooth.
factor = 4096 / 96
image = Image.new("RGB", (4096, 4096), "#153F36")
draw = ImageDraw.Draw(image)
width = round(11 * factor)
for points in [[(30, 27), (30, 69), (56, 69)], [(51, 27), (69, 27), (69, 48)]]:
    scaled = [(round(x * factor), round(y * factor)) for x, y in points]
    draw.line(scaled, fill="#B9E8CE", width=width, joint="curve")
    radius = width / 2
    for x, y in scaled:
        draw.ellipse((x-radius, y-radius, x+radius, y+radius), fill="#B9E8CE")

slots = {
    "iphone": [(20, 2), (20, 3), (29, 1), (29, 2), (29, 3),
               (40, 2), (40, 3), (60, 2), (60, 3)],
    "ipad": [(20, 1), (20, 2), (29, 1), (29, 2), (40, 1), (40, 2),
             (76, 1), (76, 2), (83.5, 2)],
    "ios-marketing": [(1024, 1)],
}
DEST.mkdir(parents=True, exist_ok=True)
entries = []
for idiom, sizes in slots.items():
    for size, scale in sizes:
        name = f"Icon-App-{size}x{size}@{scale}x.png"
        pixels = round(size * scale)
        image.resize((pixels, pixels), Image.Resampling.LANCZOS).save(DEST / name)
        entries.append({"size": f"{size}x{size}", "idiom": idiom,
                        "filename": name, "scale": f"{scale}x"})
(DEST / "Contents.json").write_text(json.dumps({"images": entries,
    "info": {"version": 1, "author": "xcode"}}, indent=2) + "\n")
print(f"Generated {len(entries)} iOS icon slots")
