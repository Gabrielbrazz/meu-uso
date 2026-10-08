#!/usr/bin/env python3
"""Generates the Meu Uso mark: an open usage ring with a marker dot in the gap.

The mark is one SVG path made only of M/C/Z commands, because the app's SVG parser
(Support/ProviderIconShape.swift) has no arc command. Circular arcs are approximated with cubic
Béziers split into segments of at most 90 degrees.

Writes:
  Sources/MeuUso/Resources/ProviderIcons/meuuso.svg   menu bar, privacy wordmark, share card
  assets/AppIcon.icon/Assets/meuuso-mark.svg          glyph for the Icon Composer app icon
  assets/AppIcon.svg                                  classic app icon artwork, for reference

With --icns it also renders assets/AppIcon.prebuilt/AppIcon.icns, the classic icon every build ships
(the Liquid Glass assets/AppIcon.icon needs Xcode's actool; see script/compile_icon.sh). The icon is
rasterized here from the same geometry, with signed distances for anti-aliasing, so no image library
or Xcode is needed; iconutil (part of macOS) packs the sizes.

Run from the repo root: python3 script/brand/mark.py [--icns]
"""
import math
import os
import struct
import subprocess
import sys
import tempfile
import zlib

CENTER = 12.0
OUTER = 10.0          # ring outer radius
INNER = 6.4           # ring inner radius
MID = (OUTER + INNER) / 2
CAP = (OUTER - INNER) / 2
GAP_CENTER = -45.0    # degrees; screen coordinates (y down), so -45 is top right
DOT = 1.5             # marker dot radius
CLEARANCE = 1.3       # space between the dot and each rounded end of the ring

# Angle from the gap center to each cap center, so the caps clear the dot.
HALF_GAP = math.degrees((DOT + CLEARANCE + CAP) / MID)
START = GAP_CENTER + HALF_GAP            # ring starts after the gap...
END = GAP_CENTER - HALF_GAP + 360.0      # ...and runs clockwise all the way around to it


def point(cx, cy, radius, degrees):
    a = math.radians(degrees)
    return cx + radius * math.cos(a), cy + radius * math.sin(a)


def arc(cx, cy, radius, start, end):
    """Cubic segments from `start` to `end` degrees (either direction). Returns 'C …' strings."""
    sweep = end - start
    count = max(1, math.ceil(abs(sweep) / 90.0))
    step = sweep / count
    parts = []
    for i in range(count):
        a0 = math.radians(start + step * i)
        a1 = math.radians(start + step * (i + 1))
        k = 4.0 / 3.0 * math.tan((a1 - a0) / 4.0)
        x0, y0 = cx + radius * math.cos(a0), cy + radius * math.sin(a0)
        x3, y3 = cx + radius * math.cos(a1), cy + radius * math.sin(a1)
        x1, y1 = x0 - k * radius * math.sin(a0), y0 + k * radius * math.cos(a0)
        x2, y2 = x3 + k * radius * math.sin(a1), y3 - k * radius * math.cos(a1)
        parts.append(f"C{x1:.3f} {y1:.3f} {x2:.3f} {y2:.3f} {x3:.3f} {y3:.3f}")
    return parts


def mark_path():
    ox, oy = point(CENTER, CENTER, OUTER, START)
    commands = [f"M{ox:.3f} {oy:.3f}"]
    commands += arc(CENTER, CENTER, OUTER, START, END)                    # outer edge, clockwise
    ex, ey = point(CENTER, CENTER, MID, END)
    commands += arc(ex, ey, CAP, END, END + 180.0)                        # rounded end
    commands += arc(CENTER, CENTER, INNER, END, START)                    # inner edge, back
    sx, sy = point(CENTER, CENTER, MID, START)
    commands += arc(sx, sy, CAP, START + 180.0, START + 360.0)            # rounded start
    commands.append("Z")
    dx, dy = point(CENTER, CENTER, MID, GAP_CENTER)
    commands.append(f"M{dx + DOT:.3f} {dy:.3f}")
    commands += arc(dx, dy, DOT, 0.0, 360.0)                              # marker dot
    commands.append("Z")
    return "".join(commands)


# macOS icon grid, in 1024-point canvas units: an 824-point tile with a 100-point margin.
CANVAS, TILE, MARGIN, TILE_RADIUS = 1024.0, 824.0, 100.0, 184.0
MARK_SIDE = TILE * 0.62                     # the mark's 24-unit artboard spans 62% of the tile
MARK_SCALE = MARK_SIDE / 24.0
MARK_OFFSET = MARGIN + (TILE - MARK_SIDE) / 2
TOP_COLOR, BOTTOM_COLOR = (0x34, 0xD3, 0x99), (0x04, 0x78, 0x57)


def app_icon_svg(path_data):
    """The classic icon: the mark in white on a rounded green tile, on the 1024-point macOS icon grid
    (an 824-point tile with a 100-point margin). The mark's 24-unit artboard spans 62% of the tile."""
    tile, margin, side, scale, offset = TILE, MARGIN, MARK_SIDE, MARK_SCALE, MARK_OFFSET
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">\n'
        '  <defs>\n'
        '    <linearGradient id="tile" x1="0" y1="0" x2="0" y2="1">\n'
        '      <stop offset="0" stop-color="#34D399"/>\n'
        '      <stop offset="1" stop-color="#047857"/>\n'
        '    </linearGradient>\n'
        '  </defs>\n'
        f'  <rect x="{margin:g}" y="{margin:g}" width="{tile:g}" height="{tile:g}" rx="{TILE_RADIUS:g}" fill="url(#tile)"/>\n'
        f'  <g transform="translate({offset:.3f} {offset:.3f}) scale({scale:.4f})">\n'
        f'    <path fill="#FFFFFF" d="{path_data}"/>\n'
        '  </g>\n'
        '</svg>\n'
    )


def mark_distance(x, y):
    """Signed distance (in mark units) from the mark's edge; negative inside."""
    dx, dy = x - CENTER, y - CENTER
    angle = math.degrees(math.atan2(dy, dx))
    while angle < START:
        angle += 360.0
    while angle >= START + 360.0:
        angle -= 360.0
    if angle <= END:
        ring = abs(math.hypot(dx, dy) - MID) - CAP
    else:
        sx, sy = point(CENTER, CENTER, MID, START)
        ex, ey = point(CENTER, CENTER, MID, END)
        ring = min(math.hypot(x - sx, y - sy), math.hypot(x - ex, y - ey)) - CAP
    gx, gy = point(CENTER, CENTER, MID, GAP_CENTER)
    return min(ring, math.hypot(x - gx, y - gy) - DOT)


def tile_distance(x, y):
    """Signed distance (canvas units) from the rounded tile's edge; negative inside."""
    half = TILE / 2
    qx = abs(x - CANVAS / 2) - (half - TILE_RADIUS)
    qy = abs(y - CANVAS / 2) - (half - TILE_RADIUS)
    outside = math.hypot(max(qx, 0.0), max(qy, 0.0))
    return outside + min(max(qx, qy), 0.0) - TILE_RADIUS


def render_png(pixels):
    """RGBA PNG of the classic icon at `pixels` x `pixels` (straight alpha)."""
    scale = pixels / CANVAS
    shadow_offset, shadow_blur = 10.0, 22.0
    rows = []
    for py in range(pixels):
        row = bytearray([0])  # PNG filter type 0 for this scanline
        y = (py + 0.5) / scale
        t = min(max((y - MARGIN) / TILE, 0.0), 1.0)
        tile_rgb = [TOP_COLOR[i] + (BOTTOM_COLOR[i] - TOP_COLOR[i]) * t for i in range(3)]
        for px in range(pixels):
            x = (px + 0.5) / scale
            tile_cover = min(max(0.5 - tile_distance(x, y) * scale, 0.0), 1.0)
            shadow = 0.0
            if pixels >= 64:
                d = tile_distance(x, y - shadow_offset)
                shadow = 0.28 * min(max(0.5 - d / shadow_blur, 0.0), 1.0)
            if tile_cover <= 0.0 and shadow <= 0.0:
                row += b"\x00\x00\x00\x00"
                continue
            mark_cover = 0.0
            if tile_cover > 0.0:
                ux, uy = (x - MARK_OFFSET) / MARK_SCALE, (y - MARK_OFFSET) / MARK_SCALE
                mark_cover = min(max(0.5 - mark_distance(ux, uy) * MARK_SCALE * scale, 0.0), 1.0)
            rgb = [c + (255.0 - c) * mark_cover for c in tile_rgb]
            alpha = tile_cover + shadow * (1.0 - tile_cover)
            out = [c * tile_cover / alpha for c in rgb]  # shadow is black, so it only adds alpha
            row += bytes(int(round(min(max(c, 0.0), 255.0))) for c in out)
            row.append(int(round(alpha * 255)))
        rows.append(bytes(row))

    def chunk(kind, body):
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))

    header = struct.pack(">IIBBBBB", pixels, pixels, 8, 6, 0, 0, 0)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header)
            + chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b""))


def write_icns(path):
    with tempfile.TemporaryDirectory() as work:
        iconset = os.path.join(work, "AppIcon.iconset")
        os.makedirs(iconset)
        for base in (16, 32, 128, 256, 512):
            for factor, suffix in ((1, ""), (2, "@2x")):
                name = f"icon_{base}x{base}{suffix}.png"
                with open(os.path.join(iconset, name), "wb") as f:
                    f.write(render_png(base * factor))
        os.makedirs(os.path.dirname(path), exist_ok=True)
        subprocess.run(["/usr/bin/iconutil", "-c", "icns", "-o", path, iconset], check=True)
    print(f"wrote {path}")


def main():
    svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor">'
        f'<path d="{mark_path()}"></path></svg>\n'
    )
    for path in (
        "Sources/MeuUso/Resources/ProviderIcons/meuuso.svg",
        "assets/AppIcon.icon/Assets/meuuso-mark.svg",
    ):
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(svg)
        print(f"wrote {path}")
    with open("assets/AppIcon.svg", "w", encoding="utf-8") as f:
        f.write(app_icon_svg(mark_path()))
    print("wrote assets/AppIcon.svg")
    if "--icns" in sys.argv[1:]:
        write_icns("assets/AppIcon.prebuilt/AppIcon.icns")


if __name__ == "__main__":
    main()
