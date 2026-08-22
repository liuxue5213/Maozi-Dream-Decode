#!/usr/bin/env python3
"""
帽子解梦应用封面生成器
使用智谱AI CogView-4模型生成梦境主题的应用封面
"""

from zai import ZhipuAiClient
import os
import requests
from datetime import datetime

def generate_dream_cover(style="mysterious", output_dir="./covers"):
    """
    生成梦境主题封面
    
    Args:
        style: 风格类型 (mysterious/healing/tech)
        output_dir: 输出目录
    """
    
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)
    
    # 不同的提示词风格
    prompts = {
        "mysterious": """梦境解析应用封面图，画面中心是一只神秘的眼睛，眼睛周围漂浮着梦境符号：月亮、星星、云朵、迷宫图案。背景是深邃的夜空，从深蓝渐变到紫红色，营造神秘梦幻的氛围。柔和的光芒从眼睛散发，照亮周围的梦境符号。背景中有细微的科技电路纹理，体现AI智能解析功能。整体色彩：深蓝、紫色、星光银，神秘而现代。专业应用封面设计，高质量数字绘画，1024x1536比例，无水印""",
        
        "healing": """梦境记录应用封面，温馨治愈风格。画面是梦境场景：星空下的云朵小船，月亮作为灯笼，星星点缀路径。柔和的暖色调，蓝紫色渐变背景。远处有AI助手剪影，正在解析梦境的符号。整体感觉温暖、安全、梦幻。移动应用封面设计，插画风格，1024x1536比例，高 detail""",
        
        "tech": """AI梦境解析应用封面，现代科技风格。中心是大脑轮廓，内部显示梦境场景：飞行、迷宫、水下等。周围有数据流和符号分析的可视化效果。背景是深邃的星空，科技蓝紫色为主。体现AI对梦境的智能分析和解读。科技感应用图标，现代数字艺术，1024x1536比例，清晰构图"""
    }
    
    if style not in prompts:
        raise ValueError(f"未知的风格: {style}，可选: {list(prompts.keys())}")
    
    print(f"🎨 正在生成 {style} 风格的封面...")
    
    try:
        # 初始化客户端
        client = ZhipuAiClient(api_key="8ea54b83b9fb46d58de87fbdceb7193e.u9C7NLTOxFLSazry")
        
        # 生成图片
        response = client.images.generations(
            model="cogView-4-250304",
            prompt=prompts[style],
        )
        
        # 获取图片URL
        image_url = response.data[0].url
        print(f"✅ 生成成功! URL: {image_url}")
        
        # 下载图片到本地
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"帽子解梦_{style}_封面_{timestamp}.png"
        filepath = os.path.join(output_dir, filename)
        
        print(f"📥 正在下载图片到: {filepath}")
        img_response = requests.get(image_url, timeout=60)
        img_response.raise_for_status()
        
        with open(filepath, 'wb') as f:
            f.write(img_response.content)
        
        print(f"💾 图片已保存: {filepath}")
        print(f"📏 文件大小: {len(img_response.content)} 字节")
        
        return filepath, image_url
        
    except Exception as e:
        print(f"❌ 生成失败: {e}")
        raise

def main():
    """主函数：生成多种风格的封面"""
    
    print("🌙 帽子解梦 - 封面生成器启动")
    print("=" * 50)
    
    output_dir = "./covers"
    styles = ["mysterious", "healing", "tech"]
    
    results = {}
    
    for style in styles:
        try:
            filepath, url = generate_dream_cover(style, output_dir)
            results[style] = {"filepath": filepath, "url": url}
            print(f"✨ {style} 风格完成!\n")
        except Exception as e:
            print(f"💥 {style} 风格失败: {e}\n")
    
    # 总结报告
    print("=" * 50)
    print("📊 生成完成总结:")
    print(f"📁 输出目录: {output_dir}")
    print(f"✅ 成功: {len(results)}/{len(styles)}")
    
    for style, info in results.items():
        print(f"  • {style}: {info['filepath']}")
    
    if results:
        print("\n🎉 封面生成完成！您可以查看本地图片文件。")
    else:
        print("\n⚠️  所有风格都生成失败，请检查API配置。")

if __name__ == "__main__":
    main()