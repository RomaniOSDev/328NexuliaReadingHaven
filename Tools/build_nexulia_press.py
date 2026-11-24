"""Build the Nexulia Press display face. Requires fontTools."""

import re
from pathlib import Path

from fontTools.feaLib.builder import addOpenTypeFeaturesFromString
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.areaPen import AreaPen
from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.reverseContourPen import ReverseContourPen
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib.path import parse_path


# Coordinates are in a 100-unit em with a 70-unit cap height.
# The contours use asymmetric wedge serifs and angled bar terminals.
def stem(x):
    return (
        f"M{x - 5} 0 H{x + 15} L{x + 14} 3 L{x + 9} 5 "
        f"V65 L{x + 14} 67 L{x + 15} 70 H{x - 5} L{x - 4} 67 "
        f"L{x} 65 V5 L{x - 4} 3 Z"
    )


GLYPHS = {
    "A": (63,
          "M2 0 H20 L19 3 L12 5 L35 61 L31 71 H28 L7 5 L2 3 Z "
          "M31 71 H34 L59 5 L63 3 V0 H39 L40 3 L48 5 L27 62 Z "
          "M16 23 H47 L46 29 L17 27 Z"),
    "B": (58,
          stem(9) +
          " M15 70 H31 C43 70 50 64 50 54 C50 46 44 40 36 36 "
          "C48 35 55 29 55 19 C55 7 46 0 30 0 H14 V4 H28 "
          "C39 4 45 10 45 19 C45 30 37 34 27 34 H17 V38 H26 "
          "C35 38 41 44 41 54 C41 62 37 66 28 66 H15 Z"),
    "C": (64,
          "M59 65 L60 47 H56 C53 59 45 67 34 67 C22 67 14 53 14 35 "
          "C14 17 22 3 35 3 C45 3 54 10 57 20 L61 19 C58 6 48 -2 34 -2 "
          "C16 -2 3 13 3 34 C3 55 16 72 35 72 C47 72 52 67 56 67 L58 70 Z"),
    "D": (67,
          stem(9) +
          " M16 70 H29 C51 70 64 57 64 36 C64 14 51 0 28 0 H15 "
          "V4 H28 C44 4 53 16 53 35 C53 54 45 66 28 66 H16 Z"),
    "E": (56,
          stem(9) +
          " M16 70 H50 L52 56 H48 L43 66 H16 Z "
          "M16 39 H37 L41 45 H44 V29 H41 L37 35 H16 Z "
          "M16 4 H44 L51 15 H54 L51 0 H16 Z"),
    "F": (53,
          stem(9) +
          " M16 70 H49 L51 56 H47 L42 66 H16 Z "
          "M16 39 H36 L40 45 H43 V29 H40 L36 35 H16 Z"),
    "G": (68,
          "M59 65 L60 47 H56 C53 59 45 67 35 67 C22 67 14 53 14 35 "
          "C14 16 22 3 36 3 C43 3 48 5 52 8 V25 L45 28 V31 H67 V28 "
          "L61 25 V7 C54 2 45 -2 35 -2 C16 -2 3 12 3 34 "
          "C3 55 16 72 35 72 C47 72 52 67 56 67 L58 70 Z"),
    "H": (70, stem(9) + stem(52) + " M16 34 H54 V39 H16 Z"),
    "I": (29, stem(10)),
    "J": (39,
          "M15 70 H36 L35 67 L30 65 V20 C30 6 23 -2 12 -2 C5 -2 1 1 1 6 "
          "C1 9 3 11 6 11 C9 11 11 9 11 6 C11 4 10 3 9 3 "
          "C10 2 11 2 13 2 C18 2 21 9 21 19 V65 L16 67 Z"),
    "K": (64,
          stem(9) +
          " M17 32 L49 66 L43 67 L42 70 H62 V67 L55 65 L19 29 Z "
          "M26 39 L56 5 L63 3 V0 H39 V3 L45 5 L21 32 Z"),
    "L": (52, stem(9) + " M16 4 H40 L48 17 H51 L48 0 H16 Z"),
    "M": (82,
          "M3 0 H22 L21 3 L15 5 L17 62 L12 70 H4 L5 67 L12 64 L9 5 L4 3 Z "
          "M12 70 H22 L43 16 L39 3 H36 L13 61 Z "
          "M37 3 H41 L65 63 L63 70 H60 L38 14 Z "
          "M60 70 H76 L75 67 L70 65 L74 5 L80 3 V0 H58 L59 3 L65 5 Z"),
    "N": (68,
          "M3 0 H23 L22 3 L15 5 V62 L10 68 V5 L4 3 Z "
          "M4 70 H20 L59 13 V-1 H55 L10 64 L5 67 Z "
          "M54 12 V65 L47 67 L46 70 H66 L65 67 L59 65 V12 Z"),
    "O": (71,
          "M35 72 C53 72 68 56 68 35 C68 14 53 -2 35 -2 "
          "C17 -2 3 14 3 35 C3 56 17 72 35 72 Z "
          "M35 68 C22 68 14 54 14 35 C14 16 22 2 35 2 "
          "C48 2 57 16 57 35 C57 54 48 68 35 68 Z"),
    "P": (55,
          stem(9) +
          " M16 70 H29 C43 70 51 63 51 50 C51 38 42 31 28 31 H17 V35 H27 "
          "C36 35 41 41 41 51 C41 60 37 66 28 66 H16 Z"),
    "Q": (72,
          "M35 72 C53 72 68 56 68 35 C68 14 53 -2 35 -2 "
          "C17 -2 3 14 3 35 C3 56 17 72 35 72 Z "
          "M35 68 C22 68 14 54 14 35 C14 16 22 2 35 2 "
          "C48 2 57 16 57 35 C57 54 48 68 35 68 Z "
          "M28 8 C41 12 50 2 58 -4 C63 -8 67 -10 71 -9 V-12 "
          "C61 -15 54 -12 46 -5 C38 2 33 5 28 5 Z"),
    "R": (62,
          stem(9) +
          " M16 70 H31 C45 70 53 63 53 51 C53 41 46 35 37 33 "
          "L55 6 L61 3 V0 H45 L25 32 H17 V36 H28 "
          "C38 36 43 42 43 52 C43 61 39 66 29 66 H16 Z"),
    "S": (54,
          "M46 66 L47 51 H43 C41 61 34 68 25 68 C17 68 12 63 12 56 "
          "C12 47 20 43 30 38 C43 32 51 26 51 16 C51 4 41 -2 27 -2 "
          "C18 -2 12 2 8 3 L6 0 H4 L3 19 H7 C9 8 17 2 27 2 "
          "C36 2 42 7 42 14 C42 22 36 27 23 33 C12 38 4 44 4 55 "
          "C4 65 13 72 25 72 C34 72 39 68 43 68 L45 70 Z"),
    "T": (61,
          "M5 70 H56 L59 54 H55 L50 65 H35 V5 L42 3 V0 H19 V3 "
          "L26 5 V65 H11 L6 54 H2 Z"),
    "U": (68,
          "M3 70 H24 L23 67 L18 65 V27 C18 11 24 4 37 4 "
          "C50 4 56 13 56 27 V65 L50 67 L49 70 H67 L66 67 L61 65 "
          "V26 C61 8 51 -2 35 -2 C18 -2 9 7 9 26 V65 L4 67 Z"),
    "V": (63,
          "M0 70 H23 L22 67 L16 65 L34 11 L31 -1 H28 L6 65 L1 67 Z "
          "M28 -1 H33 L57 65 L62 67 L63 70 H44 L45 67 L51 65 L30 7 Z"),
    "W": (91,
          "M0 70 H22 L21 67 L15 65 L32 10 L28 -1 H25 L5 65 L1 67 Z "
          "M25 -1 H30 L49 53 L47 63 L44 57 L27 8 Z "
          "M36 70 H57 L56 67 L50 65 L68 10 L65 -1 H62 L41 65 L37 67 Z "
          "M62 -1 H67 L86 65 L91 67 V70 H73 L74 67 L80 65 L64 8 Z"),
    "X": (63,
          "M4 70 H26 V67 L21 65 L56 5 L62 3 V0 H40 V3 L45 5 L10 65 L4 67 Z "
          "M2 0 H21 L20 3 L14 5 L55 65 L60 67 L61 70 H43 L44 67 "
          "L49 65 L8 5 L2 3 Z"),
    "Y": (62,
          "M0 70 H23 L22 67 L16 65 L35 37 L50 65 L44 67 L43 70 H62 "
          "L61 67 L56 65 L38 34 V5 L45 3 V0 H22 V3 L29 5 V32 L6 65 L1 67 Z"),
    "Z": (61,
          "M7 70 H56 V66 L14 4 H44 L53 17 H57 L54 0 H3 V4 L45 66 "
          "H17 L8 55 H4 Z"),
}

GLYPH_NAMES = {character: character for character in GLYPHS}
GLYPH_NAMES[" "] = "space"
GLYPH_NAMES["–"] = "endash"

KERNING = {
    "AV": -45, "AW": -35, "AY": -43, "LA": -20, "LT": -45,
    "LV": -43, "LW": -31, "LY": -49, "PA": -37, "TA": -43,
    "TO": -22, "VA": -45, "WA": -34, "YA": -44, "YO": -30,
}


def build():
    family = "Nexulia Press"
    postscript_name = "NexuliaPress-Regular"
    font = FontBuilder(1000, isTTF=False)
    glyph_order = [".notdef", "space", "endash", *GLYPHS]
    font.setupGlyphOrder(glyph_order)
    font.setupCharacterMap({ord(character): name for character, name in GLYPH_NAMES.items()})

    contours = {
        ".notdef": (56, ""),
        "space": (26, ""),
        "endash": (43, "M3 31 H40 V35 H3 Z"),
        **GLYPHS,
    }
    charstrings = {}
    metrics = {}
    for name in glyph_order:
        width, path = contours[name]
        pen = T2CharStringPen(width * 10, None)
        scaled = TransformPen(pen, (10, 0, 0, 10, 0, 0))
        for index, contour in enumerate(re.findall(r"M[^M]+", path)):
            area = AreaPen()
            parse_path(contour, area)
            is_counter = name in ("O", "Q") and index == 1
            destination = ReverseContourPen(scaled) if (area.value > 0) != is_counter else scaled
            parse_path(contour, destination)
        bounds = BoundsPen(None)
        parse_path(path, bounds)
        charstrings[name] = pen.getCharString()
        metrics[name] = (width * 10, round(bounds.bounds[0] * 10) if bounds.bounds else 0)

    font.setupCFF(postscript_name, {"FullName": family, "FamilyName": family, "Weight": "Regular"}, charstrings, {})
    font.setupHorizontalMetrics(metrics)
    font.setupHorizontalHeader(ascent=770, descent=-180)
    font.setupNameTable({
        "familyName": family,
        "styleName": "Regular",
        "uniqueFontIdentifier": "NexuliaPress-Regular-1.0",
        "fullName": family,
        "psName": postscript_name,
        "version": "Version 1.0",
    })
    font.setupOS2(sTypoAscender=770, sTypoDescender=-180, usWinAscent=770, usWinDescent=180, sCapHeight=700)
    font.setupPost()

    kerning = "\n".join(f"pos {a} {b} {value};" for (a, b), value in KERNING.items())
    addOpenTypeFeaturesFromString(font.font, "feature kern {\n" + kerning + "\n} kern;")
    target = Path(__file__).resolve().parents[1] / "328NexuliaReadingHaven/Resources/NexuliaPress.otf"
    font.save(target)


if __name__ == "__main__":
    build()
