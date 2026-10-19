import math
import json
import os
from PIL import Image, ImageDraw, ImageFilter

def create_liquid_glass_icon():
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # 1. Base Gradient Background (Deep Obsidian & Cosmic Indigo)
    for y in range(size):
        ratio = y / size
        r = int(10 + ratio * 15)
        g = int(14 + ratio * 20)
        b = int(32 + ratio * 55)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    # 2. Glowing Liquid Orbs / Caustics behind the glass
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)

    # Cyan orb (top left)
    ov_draw.ellipse([80, 80, 680, 680], fill=(0, 229, 255, 110))
    # Magenta/Purple orb (bottom right)
    ov_draw.ellipse([340, 360, 950, 970], fill=(168, 85, 247, 120))
    # Center electric blue pulse
    ov_draw.ellipse([260, 260, 760, 760], fill=(30, 144, 255, 90))

    overlay = overlay.filter(ImageFilter.GaussianBlur(110))
    img = Image.alpha_composite(img, overlay)

    # 3. Liquid Glass Envelope Geometry
    # Envelope dimensions
    env_w = 640
    env_h = 440
    env_x = (size - env_w) // 2
    env_y = (size - env_h) // 2 + 30
    corner_r = 70

    # Draw Frosted Glass Shadow
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([env_x, env_y + 25, env_x + env_w, env_y + env_h + 35], radius=corner_r, fill=(0, 0, 0, 160))
    shadow = shadow.filter(ImageFilter.GaussianBlur(40))
    img = Image.alpha_composite(img, shadow)

    # Draw Glass Envelope Body
    glass_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glass_layer)

    # Translucent glass fill with specular highlights
    g_draw.rounded_rectangle([env_x, env_y, env_x + env_w, env_y + env_h], radius=corner_r, fill=(255, 255, 255, 45))

    # Glass Envelope Flap (Triangle fold)
    flap_top = env_y + 4
    flap_left = env_x + 10
    flap_right = env_x + env_w - 10
    flap_point = (size // 2, env_y + int(env_h * 0.60))

    # Flap shadow
    flap_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fs_draw = ImageDraw.Draw(flap_shadow)
    fs_draw.polygon([(flap_left, flap_top), (flap_right, flap_top), flap_point], fill=(0, 0, 0, 90))
    flap_shadow = flap_shadow.filter(ImageFilter.GaussianBlur(16))
    glass_layer = Image.alpha_composite(glass_layer, flap_shadow)

    # Flap glass
    g_draw = ImageDraw.Draw(glass_layer)
    g_draw.polygon([(flap_left, flap_top), (flap_right, flap_top), flap_point], fill=(255, 255, 255, 60))

    # Fold lines to bottom corners
    bottom_left = (env_x + 10, env_y + env_h - 10)
    bottom_right = (env_x + env_w - 10, env_y + env_h - 10)
    g_draw.line([bottom_left, flap_point], fill=(255, 255, 255, 80), width=3)
    g_draw.line([bottom_right, flap_point], fill=(255, 255, 255, 80), width=3)

    # Iridescent Specular Rim (Glowing border)
    g_draw.rounded_rectangle([env_x, env_y, env_x + env_w, env_y + env_h], radius=corner_r, outline=(0, 240, 255, 200), width=6)
    g_draw.polygon([(flap_left, flap_top), (flap_right, flap_top), flap_point], outline=(255, 255, 255, 180), width=4)

    img = Image.alpha_composite(img, glass_layer)

    # 4. Central Glowing AI Core / Sparkle (Liquid Intelligence Badge)
    sparkle_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sp_draw = ImageDraw.Draw(sparkle_layer)

    cx, cy = size // 2, env_y + int(env_h * 0.60) - 25

    def draw_star(draw_obj, center_x, center_y, radius, color):
        points = []
        inner_r = radius * 0.28
        for i in range(8):
            angle = i * math.pi / 4
            r_cur = radius if i % 2 == 0 else inner_r
            px = center_x + r_cur * math.cos(angle - math.pi/2)
            py = center_y + r_cur * math.sin(angle - math.pi/2)
            points.append((px, py))
        draw_obj.polygon(points, fill=color)

    # Big AI Core Sparkle
    draw_star(sp_draw, cx, cy, 95, (255, 255, 255, 255))
    # Accompanying mini sparkles
    draw_star(sp_draw, cx + 180, cy - 140, 42, (0, 240, 255, 230))
    draw_star(sp_draw, cx - 190, cy - 110, 32, (192, 132, 252, 230))
    draw_star(sp_draw, cx + 220, cy + 90, 26, (255, 255, 255, 200))

    # Core Glow Blur
    sparkle_glow = sparkle_layer.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img, sparkle_glow)
    img = Image.alpha_composite(img, sparkle_layer)

    # Save Master Icon
    target_dir = r"C:\Users\flobu\.gemini\antigravity\scratch\LiquidMail\Assets.xcassets\AppIcon.appiconset"
    master_path = os.path.join(target_dir, "app-icon-1024.png")
    img.save(master_path, "PNG")
    print(f"Master icon saved to {master_path}")

    # Generate all iOS asset sizes
    sizes = [
        ("icon-1024.png", 1024),
        ("icon-180.png", 180),
        ("icon-167.png", 167),
        ("icon-152.png", 152),
        ("icon-120.png", 120),
        ("icon-87.png", 87),
        ("icon-80.png", 80),
        ("icon-60.png", 60),
        ("icon-58.png", 58),
        ("icon-40.png", 40),
        ("icon-29.png", 29),
        ("icon-20.png", 20),
    ]

    for fname, dim in sizes:
        resized = img.resize((dim, dim), Image.Resampling.LANCZOS)
        resized.save(os.path.join(target_dir, fname), "PNG")

    # Generate Apple standard Contents.json
    contents = {
        "images": [
            {
                "filename": "icon-1024.png",
                "idiom": "universal",
                "platform": "ios",
                "size": "1024x1024"
            },
            {
                "filename": "icon-180.png",
                "idiom": "iphone",
                "scale": "3x",
                "size": "60x60"
            },
            {
                "filename": "icon-120.png",
                "idiom": "iphone",
                "scale": "2x",
                "size": "60x60"
            },
            {
                "filename": "icon-87.png",
                "idiom": "iphone",
                "scale": "3x",
                "size": "29x29"
            },
            {
                "filename": "icon-58.png",
                "idiom": "iphone",
                "scale": "2x",
                "size": "29x29"
            },
            {
                "filename": "icon-120.png",
                "idiom": "iphone",
                "scale": "3x",
                "size": "40x40"
            },
            {
                "filename": "icon-80.png",
                "idiom": "iphone",
                "scale": "2x",
                "size": "40x40"
            },
            {
                "filename": "icon-60.png",
                "idiom": "iphone",
                "scale": "3x",
                "size": "20x20"
            },
            {
                "filename": "icon-40.png",
                "idiom": "iphone",
                "scale": "2x",
                "size": "20x20"
            }
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }

    with open(os.path.join(target_dir, "Contents.json"), "w", encoding="utf-8") as f:
        json.dump(contents, f, indent=2)

    print("AppIcon.appiconset generated successfully with all standard Apple resolutions!")

if __name__ == "__main__":
    create_liquid_glass_icon()
