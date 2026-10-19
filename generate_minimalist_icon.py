import math
import json
import os
from PIL import Image, ImageDraw, ImageFilter

def create_minimalist_liquid_glass_icon():
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # 1. Sleek Minimalist Obsidian Backdrop with Soft Caustics
    for y in range(size):
        ratio = y / size
        # Deep luxury dark titanium / obsidian gradient
        v = int(8 + ratio * 16)
        b = int(12 + ratio * 28)
        draw.line([(0, y), (size, y)], fill=(v, v + 2, b, 255))

    # Soft ambient glow behind the glass
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ov_draw = ImageDraw.Draw(overlay)
    ov_draw.ellipse([260, 260, 760, 760], fill=(0, 210, 255, 60))
    ov_draw.ellipse([340, 340, 860, 860], fill=(160, 90, 255, 45))
    overlay = overlay.filter(ImageFilter.GaussianBlur(130))
    img = Image.alpha_composite(img, overlay)

    # 2. Minimalist Envelope Geometry
    env_w = 600
    env_h = 420
    env_x = (size - env_w) // 2
    env_y = (size - env_h) // 2 + 10
    corner_r = 75

    # Glass Drop Shadow
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    s_draw = ImageDraw.Draw(shadow)
    s_draw.rounded_rectangle([env_x, env_y + 20, env_x + env_w, env_y + env_h + 30], radius=corner_r, fill=(0, 0, 0, 180))
    shadow = shadow.filter(ImageFilter.GaussianBlur(45))
    img = Image.alpha_composite(img, shadow)

    # Frosted Liquid Glass Card
    glass = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    g_draw = ImageDraw.Draw(glass)

    # Translucent glass body with subtle gradient
    g_draw.rounded_rectangle([env_x, env_y, env_x + env_w, env_y + env_h], radius=corner_r, fill=(255, 255, 255, 30))

    # Minimalist Envelope Flap (Soft geometric fold)
    flap_top = env_y + 2
    flap_left = env_x + 6
    flap_right = env_x + env_w - 6
    flap_point = (size // 2, env_y + int(env_h * 0.58))

    # Inner flap shadow
    fs = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    fs_draw = ImageDraw.Draw(fs)
    fs_draw.polygon([(flap_left, flap_top), (flap_right, flap_top), flap_point], fill=(0, 0, 0, 75))
    fs = fs.filter(ImageFilter.GaussianBlur(14))
    glass = Image.alpha_composite(glass, fs)

    # Flap Glass
    g_draw = ImageDraw.Draw(glass)
    g_draw.polygon([(flap_left, flap_top), (flap_right, flap_top), flap_point], fill=(255, 255, 255, 45))

    # Fold lines to bottom corners
    bottom_left = (env_x + 8, env_y + env_h - 8)
    bottom_right = (env_x + env_w - 8, env_y + env_h - 8)
    g_draw.line([bottom_left, flap_point], fill=(255, 255, 255, 60), width=3)
    g_draw.line([bottom_right, flap_point], fill=(255, 255, 255, 60), width=3)

    # Ultra-refined Specular Liquid Edge (1.5px feel)
    g_draw.rounded_rectangle([env_x, env_y, env_x + env_w, env_y + env_h], radius=corner_r, outline=(255, 255, 255, 160), width=4)
    g_draw.polygon([(flap_left, flap_top), (flap_right, flap_top), flap_point], outline=(255, 255, 255, 140), width=3)

    img = Image.alpha_composite(img, glass)

    # 3. Minimalist Liquid Intelligence Droplet / Pearl in the Center
    pearl_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    p_draw = ImageDraw.Draw(pearl_layer)

    cx, cy = size // 2, env_y + int(env_h * 0.58) - 15
    pearl_r = 52

    # Glowing outer halo
    p_draw.ellipse([cx - pearl_r - 20, cy - pearl_r - 20, cx + pearl_r + 20, cy + pearl_r + 20], fill=(0, 229, 255, 80))
    pearl_layer = pearl_layer.filter(ImageFilter.GaussianBlur(22))
    img = Image.alpha_composite(img, pearl_layer)

    # Liquid pearl core with light reflection
    pearl_core = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pc_draw = ImageDraw.Draw(pearl_core)
    pc_draw.ellipse([cx - pearl_r, cy - pearl_r, cx + pearl_r, cy + pearl_r], fill=(255, 255, 255, 240), outline=(0, 240, 255, 255), width=3)
    # Specular white crescent highlight
    pc_draw.ellipse([cx - int(pearl_r * 0.55), cy - int(pearl_r * 0.65), cx + int(pearl_r * 0.2), cy - int(pearl_r * 0.15)], fill=(255, 255, 255, 255))
    
    img = Image.alpha_composite(img, pearl_core)

    # Save to AppIcon.appiconset
    target_dir = r"C:\Users\flobu\.gemini\antigravity\scratch\LiquidMail\Assets.xcassets\AppIcon.appiconset"
    master_path = os.path.join(target_dir, "app-icon-1024.png")
    img.save(master_path, "PNG")

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

    print("Ultra-minimalist Liquid Glass App Icon generated successfully!")

if __name__ == "__main__":
    create_minimalist_liquid_glass_icon()
