#!/bin/bash

# 帽子解梦应用图标生成脚本
# 使用神秘梦境风格封面生成Android和iOS应用图标

SOURCE_IMAGE="covers/帽子解梦_mysterious_封面_20260822_160824.png"
ANDROID_RES_DIR="mobile/android/app/src/main/res"
IOS_RES_DIR="mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset"

echo "🎨 开始生成帽子解梦应用图标..."

# 检查源图片是否存在
if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ 源图片不存在: $SOURCE_IMAGE"
    exit 1
fi

echo "✅ 源图片找到: $SOURCE_IMAGE"

# 创建Android图标目录
echo "📱 创建Android图标目录..."
mkdir -p "$ANDROID_RES_DIR/mipmap-mdpi"
mkdir -p "$ANDROID_RES_DIR/mipmap-hdpi" 
mkdir -p "$ANDROID_RES_DIR/mipmap-xhdpi"
mkdir -p "$ANDROID_RES_DIR/mipmap-xxhdpi"
mkdir -p "$ANDROID_RES_DIR/mipmap-xxxhdpi"

# 检查是否安装了ImageMagick
if ! command -v convert &> /dev/null; then
    echo "❌ 需要安装ImageMagick来生成图标"
    echo "   macOS: brew install imagemagick"
    echo "   Ubuntu: sudo apt-get install imagemagick"
    exit 1
fi

echo "✅ ImageMagick已安装"

# 生成Android图标 (正方形，不同尺寸)
echo "🔧 生成Android图标..."

# mipmap-mdpi: 48x48
convert "$SOURCE_IMAGE" -resize 48x48 -background none -gravity center -extent 48x48 "$ANDROID_RES_DIR/mipmap-mdpi/ic_launcher.png"
echo "  ✅ mdpi (48x48)"

# mipmap-hdpi: 72x72  
convert "$SOURCE_IMAGE" -resize 72x72 -background none -gravity center -extent 72x72 "$ANDROID_RES_DIR/mipmap-hdpi/ic_launcher.png"
echo "  ✅ hdpi (72x72)"

# mipmap-xhdpi: 96x96
convert "$SOURCE_IMAGE" -resize 96x96 -background none -gravity center -extent 96x96 "$ANDROID_RES_DIR/mipmap-xhdpi/ic_launcher.png"
echo "  ✅ xhdpi (96x96)"

# mipmap-xxhdpi: 144x144
convert "$SOURCE_IMAGE" -resize 144x144 -background none -gravity center -extent 144x144 "$ANDROID_RES_DIR/mipmap-xxhdpi/ic_launcher.png"
echo "  ✅ xxhdpi (144x144)"

# mipmap-xxxhdpi: 192x192
convert "$SOURCE_IMAGE" -resize 192x192 -background none -gravity center -extent 192x192 "$ANDROID_RES_DIR/mipmap-xxxhdpi/ic_launcher.png"
echo "  ✅ xxxhdpi (192x192)"

# 创建Android图标资源文件
echo "📄 创建Android图标配置..."

# 生成iOS图标
echo "🍎 生成iOS图标..."
mkdir -p "$IOS_RES_DIR"

# iOS图标尺寸
IOS_SIZES=(
    "29:29"
    "40:40" 
    "57:57"
    "60:60"
    "72:72"
    "76:76"
    "80:80"
    "87:87"
    "114:114"
    "120:120"
    "144:144"
    "152:152"
    "167:167"
    "180:180"
    "1024:1024"
)

for size_spec in "${IOS_SIZES[@]}"; do
    size="${size_spec%%:*}"
    filename="Icon-$size.png"
    convert "$SOURCE_IMAGE" -resize ${size}x${size} -background none -gravity center -extent ${size}x${size} "$IOS_RES_DIR/$filename"
    echo "  ✅ iOS Icon-$size"
done

# 创建iOS Contents.json
cat > "$IOS_RES_DIR/Contents.json" << 'EOF'
{
  "images" : [
    {
      "filename" : "Icon-29.png",
      "idiom" : "universal",
      "platform" : "ios", 
      "size" : "29x29"
    },
    {
      "filename" : "Icon-40.png", 
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-57.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "57x57"
    },
    {
      "filename" : "Icon-60.png",
      "idiom" : "universal", 
      "platform" : "ios",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-72.png",
      "idiom" : "universal",
      "platform" : "ios", 
      "size" : "72x72"
    },
    {
      "filename" : "Icon-76.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "76x76" 
    },
    {
      "filename" : "Icon-80.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "80x80"
    },
    {
      "filename" : "Icon-87.png",
      "idiom" : "universal",
      "platform" : "ios", 
      "size" : "87x87"
    },
    {
      "filename" : "Icon-114.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "114x114"
    },
    {
      "filename" : "Icon-120.png", 
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "120x120"
    },
    {
      "filename" : "Icon-144.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "144x144"
    },
    {
      "filename" : "Icon-152.png",
      "idiom" : "universal", 
      "platform" : "ios",
      "size" : "152x152"
    },
    {
      "filename" : "Icon-167.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "167x167"
    },
    {
      "filename" : "Icon-180.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "180x180"
    },
    {
      "filename" : "Icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "🎉 应用图标生成完成！"
echo ""
echo "📱 Android图标: $ANDROID_RES_DIR"
echo "🍎 iOS图标: $IOS_RES_DIR" 
echo ""
echo "🚀 下一步: 提交所有文件到Git"