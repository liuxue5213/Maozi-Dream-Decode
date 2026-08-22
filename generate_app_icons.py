#!/usr/bin/env python3
"""从解梦主题图标生成Android应用图标"""
import os
import sys
import glob
from PIL import Image

# 找到最新的dream_icon
icon_files = sorted(glob.glob("covers/dream_icon_*.png"), reverse=True)
if not icon_files:
    print("❌ 未找到解梦图标，请先运行 generate_dream_icon.py")
    sys.exit(1)

SOURCE_IMAGE = icon_files[0]
print(f"🎨 使用图标: {SOURCE_IMAGE}")

ANDROID_RES_DIR = "mobile/android/app/src/main/res"

def load_and_resize_source(size):
    """加载并裁剪源图片为正方形"""
    img = Image.open(SOURCE_IMAGE)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # 裁剪为正方形（中心裁剪）
    min_dimension = min(img.size)
    left = (img.size[0] - min_dimension) // 2
    top = (img.size[1] - min_dimension) // 2
    img = img.crop((left, top, left + min_dimension, top + min_dimension))
    
    return img.resize((size, size), Image.Resampling.LANCZOS)

def main():
    # Android图标尺寸
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192
    }
    
    print("📱 生成Android应用图标...")
    for density, size in android_sizes.items():
        os.makedirs(f"{ANDROID_RES_DIR}/{density}", exist_ok=True)
        img = load_and_resize_source(size)
        img.save(f"{ANDROID_RES_DIR}/{density}/ic_launcher.png", "PNG")
        print(f"  ✅ {density} ({size}x{size})")
    
    print("🎉 Android应用图标生成完成！")

if __name__ == "__main__":
    main()
