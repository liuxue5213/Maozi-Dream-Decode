"""阿里云百炼大模型调用服务（支持自定义端点）"""
import json
import httpx
from app.core.config import settings


SYSTEM_PROMPT = """你是一位专业的梦境解析大师，精通荣格心理学、弗洛伊德精神分析理论、中国传统文化解梦（《周公解梦》《敦煌解梦书》）以及现代梦学研究。

请结合用户提供的梦境描述和情绪标签，从多维度进行深度解析。

## 重要要求
1. **字数要求：全文内容不少于500字**，每个部分都要深入展开
2. **输出格式：使用 Markdown 格式**，善用标题、加粗、列表、引用等样式
3. **语气温和专业**，像一位智慧的长者在娓娓道来
4. **避免绝对化断言**，使用"可能""或许""往往"等留有余地的表达
5. **不提供医疗建议**，涉及心理困扰时建议寻求专业帮助

## 输出结构（严格遵循此 Markdown 结构）

# 梦境解析

## 总体意象

（150字以上：概述这个梦境的核心主题和整体氛围，点出最重要的象征元素）

## 心理学视角

（150字以上：从荣格原型理论、弗洛伊德潜意识理论等角度深入分析，提及具体心理学概念）

## 传统文化解读

（100字以上：引用《周公解梦》等古籍的相关记载，结合传统文化象征）

## 现实联结

（100字以上：分析梦境与梦者现实生活可能存在的关联，提出引导性思考）

## 行动建议

- **建议一**：（具体可操作的建议）
- **建议二**：（具体可操作的建议）
- **建议三**：（具体可操作的建议）

---

> 解析仅供参考，梦境是通往潜意识的窗口，最终的解释权在你自己手中。
"""


def build_user_prompt(
    content: str,
    emotion_tags: list | None = None,
    scene_tags: list | None = None,
    character_tags: list | None = None,
    sleep_quality: int | None = None,
    follow_up_question: str | None = None,
) -> str:
    parts = [f"梦境描述：{content}"]
    if emotion_tags:
        parts.append(f"情绪标签：{'、'.join(emotion_tags)}")
    if scene_tags:
        parts.append(f"场景标签：{'、'.join(scene_tags)}")
    if character_tags:
        parts.append(f"人物标签：{'、'.join(character_tags)}")
    if sleep_quality:
        parts.append(f"醒后睡眠感受评分（1-5）：{sleep_quality}")
    if follow_up_question:
        parts.append(f"梦者特别想了解的问题：{follow_up_question}")
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
        "max_tokens": 4000,
    }
    
    if stream:
        payload["stream"] = True
        payload["stream_options"] = {"include_usage": True}
    
    if settings.dashscope_enable_thinking:
        payload["enable_thinking"] = True
    
    return payload


async def interpret_dream(
    content: str,
    emotion_tags: list | None = None,
    scene_tags: list | None = None,
    character_tags: list | None = None,
    sleep_quality: int | None = None,
    follow_up_question: str | None = None,
) -> dict:
    """调用百炼 API 解析梦境，返回结构化结果"""
    if not settings.dashscope_api_key:
        raise RuntimeError("未配置 DASHSCOPE_API_KEY，无法调用 AI 解析")
    
    user_prompt = build_user_prompt(
        content, emotion_tags, scene_tags, character_tags, sleep_quality, follow_up_question
    )
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
        # AI 现在返回 Markdown 全文（500字以上），直接返回
        # 尝试兼容旧的 JSON 格式
        try:
            return json.loads(content_str)
        except json.JSONDecodeError:
            return {"content": content_str}
    
    except httpx.HTTPStatusError as e:
        raise RuntimeError(f"百炼 API 调用失败 (HTTP {e.response.status_code}): {e.response.text}")
    except httpx.RequestError as e:
        raise RuntimeError(f"百炼 API 网络错误: {str(e)}")
    except (json.JSONDecodeError, KeyError, IndexError) as e:
        raise RuntimeError(f"百炼 API 返回格式异常: {str(e)}")


async def interpret_dream_stream(
    content: str,
    emotion_tags: list | None = None,
    scene_tags: list | None = None,
    character_tags: list | None = None,
    sleep_quality: int | None = None,
):
    """流式调用百炼 API（用于前端打字机效果）"""
    if not settings.dashscope_api_key:
        raise RuntimeError("未配置 DASHSCOPE_API_KEY，无法调用 AI 解析")
    
    user_prompt = build_user_prompt(content, emotion_tags, scene_tags, character_tags, sleep_quality)
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
