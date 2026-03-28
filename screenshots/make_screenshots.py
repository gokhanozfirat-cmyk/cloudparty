#!/usr/bin/env python3
"""Generates Play Store screenshots for CloudParty."""

from PIL import Image, ImageDraw, ImageFont
import os

OUT_DIR = os.path.join(os.path.dirname(__file__), "final")
RAW_DIR = os.path.join(os.path.dirname(__file__), "raw")
os.makedirs(OUT_DIR, exist_ok=True)

# Play Store portrait canvas
CW, CH = 1080, 1920

# Screenshot aspect ratio: 1080x2400 → 0.45
SCR_W = 440
SCR_H = int(SCR_W * 2400 / 1080)   # ~977

# Phone bezel padding
BEZ = 12
PH_W = SCR_W + BEZ * 2   # 464
PH_H = SCR_H + BEZ * 2 + 36 + 28  # screen + top notch area + bottom pill
PH_X = (CW - PH_W) // 2
PH_Y = 110

# Palette
BG1       = (10, 10, 20)
BG2       = (18, 9, 30)
PURPLE    = (124, 58, 237)
PINK      = (236, 72, 153)
PURPLE_L  = (159, 103, 255)
WHITE     = (255, 255, 255)
GRAY      = (155, 155, 190)


def lerp(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(len(c1)))


def gradient_bg(draw, w, h):
    for y in range(h):
        t = y / h
        c = lerp(BG1, BG2, t)
        draw.line([(0, y), (w, y)], fill=c)


def glow(base, cx, cy, radius, color, max_alpha=55):
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    steps = 10
    for i in range(steps, 0, -1):
        r = int(radius * i / steps)
        a = int(max_alpha * (1 - i / steps) * 2)
        a = min(a, max_alpha)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*color, a))
    base.paste(layer, mask=layer)


def try_font(size, bold=False):
    paths = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold
        else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for p in paths:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            pass
    return ImageFont.load_default()


def centered_x(draw, text, font):
    bb = draw.textbbox((0, 0), text, font=font)
    return (CW - (bb[2] - bb[0])) // 2


def draw_text_centered(draw, y, text, font, fill):
    x = centered_x(draw, text, font)
    draw.text((x, y), text, font=font, fill=fill)


def draw_pill(draw, cx, y, text, font, bg, fg=WHITE):
    bb = draw.textbbox((0, 0), text, font=font)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    px, py = 28, 12
    x0, y0 = cx - tw // 2 - px, y
    x1, y1 = cx + tw // 2 + px, y + th + py * 2
    draw.rounded_rectangle([x0, y0, x1, y1], radius=(y1 - y0) // 2, fill=bg)
    draw.text((x0 + px, y0 + py), text, font=font, fill=fg)
    return y1 + 12


def draw_phone_frame(canvas, screenshot_path):
    raw = Image.open(screenshot_path).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    scr_x = PH_X + BEZ
    scr_y = PH_Y + BEZ + 28  # 28px for notch/status bar area

    # Phone body
    draw.rounded_rectangle(
        [PH_X, PH_Y, PH_X + PH_W, PH_Y + PH_H],
        radius=36,
        fill=(22, 18, 40),
        outline=(70, 55, 110),
        width=3,
    )

    # Purple inner glow on bezel
    draw.rounded_rectangle(
        [PH_X + 2, PH_Y + 2, PH_X + PH_W - 2, PH_Y + PH_H - 2],
        radius=34,
        outline=(100, 60, 180),
        width=1,
    )

    # Notch pill
    ncx = PH_X + PH_W // 2
    ncy = PH_Y + 18
    draw.rounded_rectangle(
        [ncx - 30, ncy, ncx + 30, ncy + 14],
        radius=7,
        fill=(40, 30, 60),
    )

    # Screen — paste screenshot with rounded mask
    scr_img = raw.resize((SCR_W, SCR_H), Image.LANCZOS)
    mask = Image.new("L", (SCR_W, SCR_H), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [0, 0, SCR_W, SCR_H], radius=24, fill=255
    )
    canvas.paste(scr_img, (scr_x, scr_y), mask)

    # Screen border
    draw.rounded_rectangle(
        [scr_x, scr_y, scr_x + SCR_W, scr_y + SCR_H],
        radius=24,
        outline=(90, 60, 160),
        width=2,
    )

    # Home indicator
    bar_y = PH_Y + PH_H - 20
    bcx = PH_X + PH_W // 2
    draw.rounded_rectangle(
        [bcx - 44, bar_y, bcx + 44, bar_y + 10],
        radius=5,
        fill=(90, 75, 130),
    )


def make_slide(index, raw_file, title, subtitle, tag_text):
    canvas = Image.new("RGBA", (CW, CH), (0, 0, 0, 255))
    draw = ImageDraw.Draw(canvas)

    gradient_bg(draw, CW, CH)

    # Glow blobs
    glow(canvas, CW // 2,  380, 380, PURPLE, 45)
    glow(canvas, CW - 80, CH - 180, 260, PINK, 30)
    glow(canvas, 60, CH - 350, 200, PURPLE, 22)

    # ── Phone frame ──
    draw_phone_frame(canvas, os.path.join(RAW_DIR, raw_file))

    # ── Text area ──
    text_top = PH_Y + PH_H + 40
    font_title = try_font(72, bold=True)
    font_sub   = try_font(38)
    font_tag   = try_font(30, bold=True)
    font_app   = try_font(40, bold=True)

    # App name (subtle, top)
    draw_text_centered(draw, 40, "CloudParty", font_app, fill=PURPLE_L)

    # Title
    draw_text_centered(draw, text_top, title, font_title, fill=WHITE)
    text_top += 88

    # Subtitle
    draw_text_centered(draw, text_top, subtitle, font_sub, fill=GRAY)
    text_top += 56

    # Tag pill (gradient-ish: use pink-purple)
    bb = draw.textbbox((0, 0), tag_text, font=font_tag)
    tw = bb[2] - bb[0]
    th = bb[3] - bb[1]
    px, py = 28, 12
    cx = CW // 2
    x0, y0 = cx - tw // 2 - px, text_top + 10
    x1, y1 = cx + tw // 2 + px, text_top + 10 + th + py * 2
    # Gradient fill for pill
    for x in range(x0, x1):
        t = (x - x0) / max(1, x1 - x0)
        c = lerp(PURPLE, PINK, t)
        draw.line([(x, y0), (x, y1)], fill=c)
    draw.rounded_rectangle([x0, y0, x1, y1], radius=(y1-y0)//2, outline=WHITE, width=0)
    # Re-draw with rounded corners by masking
    pill_mask = Image.new("L", (CW, CH), 0)
    ImageDraw.Draw(pill_mask).rounded_rectangle(
        [x0, y0, x1, y1], radius=(y1-y0)//2, fill=255
    )
    canvas_rgb = canvas.convert("RGB")
    pill_layer = canvas_rgb.copy()
    # Apply pill gradient on layer, paste with mask
    draw2 = ImageDraw.Draw(pill_layer)
    for x in range(x0, x1):
        t = (x - x0) / max(1, x1 - x0)
        c = lerp(PURPLE, PINK, t)
        draw2.line([(x, y0), (x, y1)], fill=c)
    canvas_rgb.paste(pill_layer, mask=pill_mask)
    draw3 = ImageDraw.Draw(canvas_rgb)
    draw3.text((cx - tw // 2, y0 + py), tag_text, font=font_tag, fill=WHITE)

    # Pagination dots
    dot_y = CH - 55
    for i in range(3):
        dx = CW // 2 + (i - 1) * 30
        col = PURPLE_L if i == (index - 1) else (55, 48, 85)
        r = 8 if i == (index - 1) else 5
        draw3.ellipse([dx - r, dot_y - r, dx + r, dot_y + r], fill=col)

    path = os.path.join(OUT_DIR, f"screenshot_{index}.png")
    canvas_rgb.save(path, "PNG")
    print(f"✓  {path}")


slides = [
    (1, "screen1.png",
     "Müziğin Buluttan",
     "Google Drive, OneDrive ve daha fazlası",
     "☁  Bulut Bağla"),
    (2, "screen2.png",
     "Tüm Parçaların",
     "Kütüphaneni her yerde taşı",
     "🎵  Kütüphane"),
    (3, "screen3.png",
     "Çalma Listelerin",
     "Otomatik oynat · Karıştır · Tekrarla",
     "🎶  Playlist"),
]

for args in slides:
    make_slide(*args)

print(f"\nDone → {OUT_DIR}")
