#!/usr/bin/env python3
"""生成解梦主题的应用图标"""
from zai import ZhipuAiClient
import requests
import os
from datetime import datetime

def generate_icon():
    client = ZhipuAiClient(api_key="8ea54b83b9fb46d58de87fbdceb7193e.u9C7NLTOxFLSazry")
    
    prompt = """手机应用图标设计，解梦主题。
画面中心是一个发光的新月，月牙怀抱着一颗闪烁的星星。
背景是深邃的夜空，深蓝紫色渐变，点缀着细小的星星。
下方有一个闭着的眼睛图案，代表睡眠和梦境。
整体风格：现代简约，神秘梦幻，适合手机应用图标。
色彩：深蓝、紫色、星光银、温暖的月光黄。
圆形图标设计，边缘平滑，适合Android应用图标。"""
    
    print("🎨 正在生成解梦主题图标...")
    response = client.images.generations(
        model="cogView-4-250304",
        prompt=prompt,
    )
    
    image_url = response.data[0].url
    print(f"✅ 生成成功: {image_url}")
    
    # 下载图片
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    os.makedirs("covers", exist_ok=True)
    filepath = f"covers/dream_icon_{timestamp}.png"
    
    img_response = requests.get(image_url, timeout=60)
    with open(filepath, 'wb') as f:
        f.write(img_response.content)
    
    print(f"💾 图标已保存: {filepath}")
    return filepath

if __name__ == "__main__":
    generate_icon()
