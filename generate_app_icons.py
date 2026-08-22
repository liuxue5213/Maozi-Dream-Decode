#!/usr/bin/env python3
"""
帽子解梦应用图标生成器
使用神秘梦境风格封面生成Android和iOS应用图标
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont

# 配置
SOURCE_IMAGE = "covers/帽子解梦_mysterious_封面_20260822_160824.png"
ANDROID_RES_DIR = "mobile/android/app/src/main/res"
IOS_RES_DIR = "mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset"

def create_directory_structure():
    """创建必要的目录结构"""
    dirs = [
        f"{ANDROID_RES_DIR}/mipmap-mdpi",
        f"{ANDROID_RES_DIR}/mipmap-hdpi", 
        f"{ANDROID_RES_DIR}/mipmap-xhdpi",
        f"{ANDROID_RES_DIR}/mipmap-xxhdpi",
        f"{ANDROID_RES_DIR}/mipmap-xxxhdpi",
        IOS_RES_DIR
    ]
    
    for dir_path in dirs:
        os.makedirs(dir_path, exist_ok=True)
    
    print("✅ 目录结构创建完成")

def load_and_resize_source(size):
    """加载并裁剪源图片为正方形"""
    try:
        img = Image.open(SOURCE_IMAGE)
        # 转换为RGBA模式
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # 裁剪为正方形（中心裁剪）
        min_dimension = min(img.size)
        left = (img.size[0] - min_dimension) // 2
        top = (img.size[1] - min_dimension) // 2
        right = left + min_dimension
        bottom = top + min_dimension
        img = img.crop((left, top, right, bottom))
        
        # 调整大小
        img_resized = img.resize((size, size), Image.Resampling.LANCZOS)
        return img_resized
    except Exception as e:
        print(f"❌ 图片处理错误: {e}")
        sys.exit(1)

def generate_android_icons():
    """生成Android应用图标"""
    print("🔧 生成Android应用图标...")
    
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192
    }
    
    for density, size in android_sizes.items():
        try:
            img = load_and_resize_source(size)
            output_path = f"{ANDROID_RES_DIR}/{density}/ic_launcher.png"
            img.save(output_path, "PNG")
            print(f"  ✅ {density} ({size}x{size})")
        except Exception as e:
            print(f"  ❌ {density} 生成失败: {e}")

def generate_ios_icons():
    """生成iOS应用图标"""
    print("🍎 生成iOS应用图标...")
    
    ios_sizes = [29, 40, 57, 60, 72, 76, 80, 87, 114, 120, 144, 152, 167, 180, 1024]
    
    for size in ios_sizes:
        try:
            img = load_and_resize_source(size)
            output_path = f"{IOS_RES_DIR}/Icon-{size}.png"
            img.save(output_path, "PNG")
            print(f"  ✅ Icon-{size}.png")
        except Exception as e:
            print(f"  ❌ Icon-{size} 生成失败: {e}")

def generate_ios_contents_json():
    """生成iOS的Contents.json配置文件"""
    contents = {
        "images": [
            {
                "filename": f"Icon-{size}.png",
                "idiom": "universal",
                "platform": "ios",
                "size": f"{size}x{size}"
            }
            for size in [29, 40, 57, 60, 72, 76, 80, 87, 114, 120, 144, 152, 167, 180, 1024]
        ],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    import json
    with open(f"{IOS_RES_DIR}/Contents.json", 'w') as f:
        json.dump(contents, f, indent=2)
    
    print("📄 iOS Contents.json 创建完成")

def update_android_manifest():
    """更新Android manifest以确保图标配置正确"""
    manifest_path = f"{ANDROID_RES_DIR}/../AndroidManifest.xml"
    
    # 检查manifest文件是否已经存在并配置了图标
    if os.path.exists(manifest_path):
        with open(manifest_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 如果已经配置了图标引用，不需要修改
        if 'android:icon="@mipmap/ic_launcher"' in content:
            print("📄 Android manifest 已有图标配置")
            return

def main():
    """主函数"""
    print("🎨 帽子解梦应用图标生成器")
    print("=" * 50)
    
    # 检查源图片
    if not os.path.exists(SOURCE_IMAGE):
        print(f"❌ 源图片不存在: {SOURCE_IMAGE}")
        sys.exit(1)
    
    print(f"✅ 源图片: {SOURCE_IMAGE}")
    
    try:
        # 创建目录结构
        create_directory_structure()
        
        # 生成Android图标
        generate_android_icons()
        
        # 生成iOS图标  
        generate_ios_icons()
        
        # 生成iOS配置文件
        generate_ios_contents_json()
        
        # 检查Android manifest
        update_android_manifest()
        
        print("=" * 50)
        print("🎉 应用图标生成完成！")
        print("")
        print(f"📱 Android图标位置: {ANDROID_RES_DIR}")
        print(f"🍎 iOS图标位置: {IOS_RES_DIR}")
        print("")
        print("🚀 下一步: 提交所有文件到Git")
        
    except Exception as e:
        print(f"❌ 生成过程出错: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()