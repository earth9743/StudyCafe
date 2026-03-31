#!/usr/bin/env python3
"""Generate Kagong Map app icon and splash logo."""

from PIL import Image, ImageDraw, ImageFont
import math
import os

# Design System Colors
NAVY = (25, 55, 109)       # #19376D
WHITE = (255, 255, 255)
LIGHT_NAVY = (40, 80, 150) # Slightly lighter for depth
DARK_NAVY = (15, 35, 75)   # Darker shade

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "images")


def draw_rounded_rect(draw, bbox, radius, fill):
    """Draw a rounded rectangle."""
    x0, y0, x1, y1 = bbox
    draw.rectangle([x0 + radius, y0, x1 - radius, y1], fill=fill)
    draw.rectangle([x0, y0 + radius, x1, y1 - radius], fill=fill)
    draw.pieslice([x0, y0, x0 + 2 * radius, y0 + 2 * radius], 180, 270, fill=fill)
    draw.pieslice([x1 - 2 * radius, y0, x1, y0 + 2 * radius], 270, 360, fill=fill)
    draw.pieslice([x0, y1 - 2 * radius, x0 + 2 * radius, y1], 90, 180, fill=fill)
    draw.pieslice([x1 - 2 * radius, y1 - 2 * radius, x1, y1], 0, 90, fill=fill)


def draw_location_pin_with_cup(draw, cx, cy, size):
    """Draw a map location pin with a coffee cup inside."""
    pin_w = size * 0.7
    pin_h = size * 0.9

    # Pin body (teardrop shape)
    # Top circle part
    circle_r = pin_w / 2
    circle_cy = cy - pin_h * 0.15

    # Draw the pin shape using ellipse for top and polygon for bottom point
    # Top circle
    draw.ellipse(
        [cx - circle_r, circle_cy - circle_r, cx + circle_r, circle_cy + circle_r],
        fill=WHITE
    )

    # Bottom triangle (pin point)
    point_y = cy + pin_h * 0.45
    triangle_half_w = circle_r * 0.58
    # Find where triangle meets circle
    draw.polygon(
        [
            (cx - triangle_half_w, circle_cy + circle_r * 0.55),
            (cx, point_y),
            (cx + triangle_half_w, circle_cy + circle_r * 0.55),
        ],
        fill=WHITE
    )

    # Inner circle (navy background for cup icon)
    inner_r = circle_r * 0.7
    draw.ellipse(
        [cx - inner_r, circle_cy - inner_r, cx + inner_r, circle_cy + inner_r],
        fill=NAVY
    )

    # Coffee cup icon inside the pin
    cup_size = inner_r * 0.9
    cup_cx = cx
    cup_cy = circle_cy + cup_size * 0.05

    # Cup body (trapezoid shape)
    cup_top_w = cup_size * 0.65
    cup_bot_w = cup_size * 0.5
    cup_h = cup_size * 0.6
    cup_top_y = cup_cy - cup_h * 0.3
    cup_bot_y = cup_cy + cup_h * 0.5

    draw.polygon(
        [
            (cup_cx - cup_top_w, cup_top_y),
            (cup_cx + cup_top_w, cup_top_y),
            (cup_cx + cup_bot_w, cup_bot_y),
            (cup_cx - cup_bot_w, cup_bot_y),
        ],
        fill=WHITE
    )

    # Cup handle (arc on right side)
    handle_r = cup_size * 0.2
    handle_cx = cup_cx + cup_top_w + handle_r * 0.3
    handle_cy = cup_cy + cup_size * 0.05
    # Outer handle
    draw.ellipse(
        [handle_cx - handle_r, handle_cy - handle_r * 1.2,
         handle_cx + handle_r, handle_cy + handle_r * 1.2],
        fill=WHITE
    )
    # Inner handle (cut out)
    inner_handle_r = handle_r * 0.5
    draw.ellipse(
        [handle_cx - inner_handle_r, handle_cy - inner_handle_r * 1.2,
         handle_cx + inner_handle_r, handle_cy + inner_handle_r * 1.2],
        fill=NAVY
    )

    # Steam lines above the cup
    steam_y_start = cup_top_y - cup_size * 0.15
    steam_h = cup_size * 0.3
    for i, offset_x in enumerate([-cup_size * 0.25, 0, cup_size * 0.25]):
        sx = cup_cx + offset_x
        for j in range(8):
            t = j / 7.0
            sy = steam_y_start - t * steam_h
            wave = math.sin(t * math.pi * 2) * cup_size * 0.06
            dot_r = cup_size * 0.035 * (1 - t * 0.5)
            draw.ellipse(
                [sx + wave - dot_r, sy - dot_r, sx + wave + dot_r, sy + dot_r],
                fill=WHITE
            )


def generate_app_icon(size=1024):
    """Generate the app icon."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background with rounded corners
    margin = int(size * 0.02)
    radius = int(size * 0.22)  # iOS-style rounded corners
    draw_rounded_rect(draw, [margin, margin, size - margin, size - margin], radius, NAVY)

    # Draw the location pin with coffee cup
    draw_location_pin_with_cup(draw, size // 2, size * 0.45, size * 0.55)

    # Add "카공" text at the bottom
    try:
        font_size = int(size * 0.13)
        font = ImageFont.truetype("/Library/Fonts/NanumSquareEB.ttf", font_size)
    except (OSError, IOError):
        try:
            font = ImageFont.truetype("/System/Library/Fonts/AppleSDGothicNeo.ttc", font_size)
        except (OSError, IOError):
            font = ImageFont.load_default()

    text = "카공"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    text_x = (size - tw) // 2
    text_y = int(size * 0.78)
    draw.text((text_x, text_y), text, fill=WHITE, font=font)

    return img


def generate_splash_logo(size=512):
    """Generate the splash screen logo (transparent background)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Draw the location pin with coffee cup - WHITE for dark/navy background
    draw_location_pin_with_cup(draw, size // 2, size * 0.38, size * 0.5)

    # Add "카공지도" text below
    try:
        font_size = int(size * 0.11)
        font = ImageFont.truetype("/Library/Fonts/NanumSquareEB.ttf", font_size)
    except (OSError, IOError):
        try:
            font = ImageFont.truetype("/System/Library/Fonts/AppleSDGothicNeo.ttc", font_size)
        except (OSError, IOError):
            font = ImageFont.load_default()

    text = "카공지도"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    text_x = (size - tw) // 2
    text_y = int(size * 0.75)
    draw.text((text_x, text_y), text, fill=WHITE, font=font)

    # Subtitle
    try:
        sub_font_size = int(size * 0.05)
        sub_font = ImageFont.truetype("/Library/Fonts/NanumSquareB.ttf", sub_font_size)
    except (OSError, IOError):
        try:
            sub_font = ImageFont.truetype("/System/Library/Fonts/AppleSDGothicNeo.ttc", sub_font_size)
        except (OSError, IOError):
            sub_font = ImageFont.load_default()

    sub_text = "나만의 카공 스팟을 찾아보세요"
    bbox2 = draw.textbbox((0, 0), sub_text, font=sub_font)
    stw = bbox2[2] - bbox2[0]
    sub_x = (size - stw) // 2
    sub_y = int(size * 0.87)
    draw.text((sub_x, sub_y), sub_text, fill=(200, 210, 230, 200), font=sub_font)

    return img


def generate_icon_no_rounded(size=1024):
    """Generate app icon without rounded corners (for flutter_launcher_icons)."""
    img = Image.new("RGBA", (size, size), NAVY + (255,))
    draw = ImageDraw.Draw(img)

    # Draw the location pin with coffee cup
    draw_location_pin_with_cup(draw, size // 2, size * 0.45, size * 0.55)

    # Add "카공" text at the bottom
    try:
        font_size = int(size * 0.13)
        font = ImageFont.truetype("/Library/Fonts/NanumSquareEB.ttf", font_size)
    except (OSError, IOError):
        try:
            font = ImageFont.truetype("/System/Library/Fonts/AppleSDGothicNeo.ttc", font_size)
        except (OSError, IOError):
            font = ImageFont.load_default()

    text = "카공"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    text_x = (size - tw) // 2
    text_y = int(size * 0.78)
    draw.text((text_x, text_y), text, fill=WHITE, font=font)

    return img


def generate_supersampled(generator_fn, target_size, supersample=4):
    """Generate image at higher resolution then downscale for smooth anti-aliasing."""
    large = generator_fn(target_size * supersample)
    return large.resize((target_size, target_size), Image.LANCZOS)


if __name__ == "__main__":
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # App icon (with rounded corners for preview) - supersampled
    icon = generate_supersampled(generate_app_icon, 1024)
    icon_path = os.path.join(OUTPUT_DIR, "app_icon.png")
    icon.save(icon_path, "PNG")
    print(f"App icon saved: {icon_path}")

    # App icon (no rounded corners - for flutter_launcher_icons to process) - supersampled
    icon_raw = generate_supersampled(generate_icon_no_rounded, 1024)
    icon_raw_path = os.path.join(OUTPUT_DIR, "app_icon_raw.png")
    icon_raw.save(icon_raw_path, "PNG")
    print(f"App icon (raw) saved: {icon_raw_path}")

    # Splash logo - standard
    splash = generate_supersampled(generate_splash_logo, 512)
    splash_path = os.path.join(OUTPUT_DIR, "splash_logo.png")
    splash.save(splash_path, "PNG")
    print(f"Splash logo saved: {splash_path}")

    # Splash logo HD - 2048px for xxxhdpi devices like Pixel 7 Pro
    splash_hd = generate_supersampled(generate_splash_logo, 2048, supersample=2)
    splash_hd_path = os.path.join(OUTPUT_DIR, "splash_logo_hd.png")
    splash_hd.save(splash_hd_path, "PNG")
    print(f"Splash logo (HD 2048px) saved: {splash_hd_path}")

    print("\nAll logos generated successfully!")
