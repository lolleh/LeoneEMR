#!/usr/bin/env python3
"""Build ZPL 1-bit graphics (^GFA) for the MOH + HEAP logos and emit a Java
source constant that embeds them into the ID-card / label layout.

The logos are the same PNGs the EMR already shows (content package
pih/logo/). They are white-backed, resized, thresholded to 1 bit and emitted
as ASCII-hex Zebra graphics. Output: GeneratedLogos.java (a Java source file
committed as a build artifact under branding/zpl/gen).
"""
import argparse
import os
import sys

from PIL import Image

LAYOUT = {
    "moh":  {"width": 190, "height": 190, "x": 365, "y": 15},
    "heap": {"width": 340, "height": 113, "x": 585, "y": 53},
}
DIVIDER_Y = 225
LOGO_SRC = [
    ("moh", "moh-logo.png"),
    ("heap", "heap-logo.png"),
]


def ratio_resize(size, max_w, max_h):
    w, h = size
    scale = min(max_w / w, max_h / h)
    return max(1, int(w * scale)), max(1, int(h * scale))


def binarize(img):
    """Return list of rows; each row is a bytearray of packed 1bpp pixels (1=dark)."""
    g = img.convert("L")
    w, h = g.size
    px = g.load()
    rows = []
    for y in range(h):
        row = bytearray()
        byte, bits = 0, 0
        for x in range(w):
            byte = (byte << 1) | (1 if px[x, y] < 200 else 0)
            bits += 1
            if bits == 8:
                row.append(byte)
                byte, bits = 0, 0
        if bits:
            row.append(byte << (8 - bits))
        rows.append(row)
    return w, h, rows


def gfa(rows, bytes_per_row):
    out = []
    for row in rows:
        out.append("".join("%02X" % b for b in row))
    return "".join(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", default=os.path.join(os.path.dirname(__file__),
                    "..", "..", "content", "configuration",
                    "backend_configuration", "pih", "logo"),
                    help="dir containing moh-logo.png / heap-logo.png")
    ap.add_argument("--out-java", default=os.path.join(os.path.dirname(__file__),
                    "gen", "org", "openmrs", "module", "pihcore", "printer",
                    "template", "GeneratedLogos.java"))
    args = ap.parse_args()

    parts = []
    for key, filename in LOGO_SRC:
        path = os.path.join(args.src, filename)
        if not os.path.exists(path):
            sys.exit("missing logo: %s" % path)
        img = Image.open(path).convert("RGBA")
        bg = Image.new("RGBA", img.size, (255, 255, 255, 255))
        bg.alpha_composite(img)
        img = bg.convert("RGB")

        cfg = LAYOUT[key]
        w, h = ratio_resize(img.size, cfg["width"], cfg["height"])
        img = img.resize((w, h), Image.LANCZOS)
        rw, rh, rows = binarize(img)
        bpr = (rw + 7) // 8
        total = bpr * rh
        data = gfa(rows, bpr)
        parts.append("^FO%d,%d^GFA,%d,%d,%d,%s^FS" %
                     (cfg["x"], cfg["y"], total, total, bpr, data))

    logos = "".join(parts) + "^FO220,%d^GB850,0,5^FS" % DIVIDER_Y

    java = (
        "package org.openmrs.module.pihcore.printer.template;\n"
        "\n"
        "public final class GeneratedLogos {\n"
        "    private GeneratedLogos() { }\n"
        "\n"
        "    public static final String LOGO_ZPL =\n"
    )
    chunk_size = 4096
    chunks = []
    for i in range(0, len(logos), chunk_size):
        chunks.append("        \"%s\"" % logos[i:i + chunk_size])
    java += "            +\n".join(chunks) + ";\n}\n"

    out = args.out_java
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w") as fh:
        fh.write(java)
    print("wrote %s (%d bytes of ZPL)" % (out, len(logos)))


if __name__ == "__main__":
    main()