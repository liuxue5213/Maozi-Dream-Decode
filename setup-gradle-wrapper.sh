#!/bin/bash

# Gradle Wrapper设置脚本
# 为GitHub Actions构建准备Gradle环境

set -e

echo "🔧 设置Gradle Wrapper..."

GRADLE_WRAPPER_DIR="mobile/android/gradle/wrapper"
GRADLE_WRAPPER_JAR="$GRADLE_WRAPPER_DIR/gradle-wrapper.jar"

# 检查gradle wrapper jar是否存在
if [ ! -f "$GRADLE_WRAPPER_JAR" ]; then
    echo "📥 下载Gradle Wrapper JAR..."
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    
    # 下载gradle wrapper
    curl -L -o "$TEMP_DIR/gradle-wrapper.jar" \
        "https://github.com/gradle/gradle/raw/v8.0.0/gradle/wrapper/gradle-wrapper.jar"
    
    # 移动到目标位置
    mkdir -p "$GRADLE_WRAPPER_DIR"
    mv "$TEMP_DIR/gradle-wrapper.jar" "$GRADLE_WRAPPER_JAR"
    
    # 清理临时目录
    rm -rf "$TEMP_DIR"
    
    echo "✅ Gradle Wrapper JAR下载完成"
else
    echo "✅ Gradle Wrapper JAR已存在"
fi

echo "🎉 Gradle Wrapper设置完成！"
echo ""
echo "📁 Gradle文件："
ls -la mobile/android/gradle/