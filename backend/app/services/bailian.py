"""阿里云百炼大模型调用服务（支持自定义端点）"""
import json
import httpx
from app.core.config import settings


SYSTEM_PROMPT = """你是一位专业的梦境解析助手，熟悉荣格心理学、弗洛伊德理论和中国传统文化解梦。
请结合用户提供的梦境描述和情绪标签，从"心理视角""传统象征""现实关联"三个角度进行温和的解析。
避免绝对化断言，不提供医疗建议。
严格输出 JSON 格式：
{
  "summary": "梦境主题概述",
  "symbols": [{"element": "象征元素", "traditional_meaning": "传统解梦", "psychology_meaning": "心理学解释", "culture_meaning": "文化象征"}],
  "psychology_analysis": "整体心理分析",
  "traditional_meaning": "传统解梦总述",
  "reality_connection": "与现实生活的可能关联",
  "suggestions": ["建议1", "建议2"],
  "disclaimer": "本解析仅供参考，不构成医疗建议"
}"""


def build_user_prompt(content: str, emotion_tags: list | None = None, scene_tags: list | None = None) -> str:
    parts = [f"梦境描述：{content}"]
    if emotion_tags:
        parts.append(f"情绪标签：{'、'.join(emotion_tags)}")
    if scene_tags:
        parts.append(f"场景标签：{'、'.join(scene_tags)}")
    return "\n".join(parts)


def get_api_url() -> str:
    """获取 API 端点 URL"""
    return f"{settings.dashscope_base_url}/chat/completions"


def get_request_payload(messages: list, stream: bool = False) -> dict:
    """构建请求体"""
    payload = {
        "model": settings.dashscope_model,
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": 2000,
    }
    
    if stream:
        payload["stream"] = True
        payload["stream_options"] = {"include_usage": True}
    else:
        payload["response_format"] = {"type": "json_object"}
    
    if settings.dashscope_enable_thinking:
        payload["enable_thinking"] = True
    
    return payload


async def interpret_dream(content: str, emotion_tags: list | None = None, scene_tags: list | None = None) -> dict:
    """调用百炼 API 解析梦境，返回结构化结果"""
    if not settings.dashscope_api_key:
        raise RuntimeError("未配置 DASHSCOPE_API_KEY，无法调用 AI 解析")
    
    user_prompt = build_user_prompt(content, emotion_tags, scene_tags)
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_prompt},
    ]
    
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                get_api_url(),
                headers={
                    "Authorization": f"Bearer {settings.dashscope_api_key}",
                    "Content-Type": "application/json",
                },
                json=get_request_payload(messages, stream=False),
            )
            response.raise_for_status()
            data = response.json()
        
        content_str = data["choices"][0]["message"]["content"]
        return json.loads(content_str)
    
    except httpx.HTTPStatusError as e:
        raise RuntimeError(f"百炼 API 调用失败 (HTTP {e.response.status_code}): {e.response.text}")
    except httpx.RequestError as e:
        raise RuntimeError(f"百炼 API 网络错误: {str(e)}")
    except (json.JSONDecodeError, KeyError, IndexError) as e:
        raise RuntimeError(f"百炼 API 返回格式异常: {str(e)}")


async def interpret_dream_stream(content: str, emotion_tags: list | None = None, scene_tags: list | None = None):
    """流式调用百炼 API（用于前端打字机效果）"""
    if not settings.dashscope_api_key:
        raise RuntimeError("未配置 DASHSCOPE_API_KEY，无法调用 AI 解析")
    
    user_prompt = build_user_prompt(content, emotion_tags, scene_tags)
    messages = [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user", "content": user_prompt},
    ]
    
    try:
        async with httpx.AsyncClient(timeout=120.0) as client:
            async with client.stream(
                "POST",
                get_api_url(),
                headers={
                    "Authorization": f"Bearer {settings.dashscope_api_key}",
                    "Content-Type": "application/json",
                },
                json=get_request_payload(messages, stream=True),
            ) as response:
                response.raise_for_status()
                async for line in response.aiter_lines():
                    if line.startswith("data: "):
                        chunk_data = line[6:]
                        if chunk_data.strip() == "[DONE]":
                            break
                        yield chunk_data
    
    except httpx.HTTPStatusError as e:
        yield json.dumps({"error": f"API 调用失败: HTTP {e.response.status_code}"})
    except httpx.RequestError as e:
        yield json.dumps({"error": f"网络错误: {str(e)}"})
