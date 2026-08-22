#!/usr/bin/env python3
"""CI中生成Android应用图标 - 从仓库中的解梦图标生成各尺寸"""
import os
import glob
from PIL import Image

def find_source_icon():
    """查找图标源文件"""
    # 优先使用解梦主题图标
    icon_files = sorted(glob.glob("covers/dream_icon_*.png"), reverse=True)
    if icon_files:
        return icon_files[0]
    
    # 后备：使用神秘梦境封面
    icon_files = glob.glob("covers/*mysterious*.png")
    if icon_files:
        return icon_files[0]
    
    return None

def generate_icons(source_path):
    """生成各尺寸的Android图标"""
    img = Image.open(source_path)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # 裁剪为正方形（中心裁剪）
    min_dim = min(img.size)
    left = (img.size[0] - min_dim) // 2
    top = (img.size[1] - min_dim) // 2
    img = img.crop((left, top, left + min_dim, top + min_dim))
    
    # Android各尺寸
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    
    base_dir = "mobile/android/app/src/main/res"
    for density, size in sizes.items():
        out_dir = os.path.join(base_dir, density)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, "ic_launcher.png")
        img.resize((size, size), Image.Resampling.LANCZOS).save(out_path, "PNG")
        print("  OK {} ({}x{})".format(density, size, size))

def main():
    source = find_source_icon()
    if not source:
        print("WARNING: no icon found, using default")
        return
    
    print("Using icon: {}".format(source))
    generate_icons(source)
    print("All icons generated!")

if __name__ == "__main__":
    main()
