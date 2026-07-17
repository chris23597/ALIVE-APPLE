#!/usr/bin/env python3
"""Generate ALIVE APPLE app icon and asset catalog."""
from pathlib import Path
import json

# Create directories
base = Path(__file__).parent / "Xcode" / "Assets.xcassets"
icon_dir = base / "AppIcon.appiconset"
icon_dir.mkdir(parents=True, exist_ok=True)
launch_dir = base / "LaunchBackground.colorset"
launch_dir.mkdir(parents=True, exist_ok=True)

# App Icon Contents.json
icon_contents = {
    "images": [
        {"idiom": "iphone", "scale": "2x", "size": "60x60"},
        {"idiom": "iphone", "scale": "3x", "size": "60x60"},
        {"idiom": "ipad", "scale": "1x", "size": "76x76"},
        {"idiom": "ipad", "scale": "2x", "size": "76x76"},
        {"idiom": "ipad", "scale": "2x", "size": "83.5x83.5"},
        {
            "idiom": "ios-marketing",
            "scale": "1x",
            "size": "1024x1024",
            "filename": "AppIcon-1024.png"
        }
    ],
    "info": {"author": "xcode", "version": 1}
}
with open(icon_dir / "Contents.json", "w") as f:
    json.dump(icon_contents, f, indent=2)

# Generate a simple 1024x1024 PNG icon (solid dark green with ALIVE text)
# Using a minimal valid PNG with a solid color + text area
# This is a placeholder — replace with real icon later
import struct, zlib

W, H = 1024, 1024

def png_chunk(ctype, data):
    c = ctype + data
    return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xffffffff)

def build_png(width, height, pixels):
    raw = b""
    for y in range(height):
        raw += b"\x00"
        for x in range(width):
            raw += bytes(pixels[y * width + x])
    return (
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(raw))
        + png_chunk(b"IEND", b"")
    )

# Build a simple gradient icon (much faster with list comprehension)
C = W // 2
R = 380
R2 = R * R
pixels = bytearray(W * H * 3)
for y in range(0, H, 4):  # skip pixels for speed, will still look fine
    for x in range(0, W, 4):
        dx, dy = x - C, y - C
        d2 = dx*dx + dy*dy
        
        if d2 < R2:
            # Inner brain area — green
            blend = 1.0 - (d2 / R2)
            r = int(10 + 30 * blend)
            g = int(76 + 175 * blend)  # ALIVE green #4CAF50
            b = int(50 + 80 * blend)
        else:
            # Outer area — dark
            r, g, b = 10, 10, 15
        
        # Write 4x4 block
        for dy2 in range(4):
            if y + dy2 >= H: continue
            for dx2 in range(4):
                if x + dx2 >= W: continue
                idx = ((y + dy2) * W + (x + dx2)) * 3
                pixels[idx:idx+3] = bytes([r, g, b])

png = build_png(W, H, pixels)
with open(icon_dir / "AppIcon-1024.png", "wb") as f:
    f.write(png)

print(f"App icon created: {len(png)} bytes ({W}x{H})")

# Main Contents.json
with open(base / "Contents.json", "w") as f:
    json.dump({"info": {"author": "xcode", "version": 1}}, f, indent=2)

# Launch screen color (dark background)
launch_color = {
    "colors": [{
        "color": {
            "color-space": "srgb",
            "components": {"red": "0.039", "green": "0.039", "blue": "0.059", "alpha": "1.000"}
        },
        "idiom": "universal"
    }],
    "info": {"author": "xcode", "version": 1}
}
with open(launch_dir / "Contents.json", "w") as f:
    json.dump(launch_color, f, indent=2)

print("Assets.xcassets ready: Xcode/Assets.xcassets/")
print("Replace AppIcon-1024.png with your real icon later.")
