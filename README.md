# 梦语 - 梦境记录与 AI 解析

> 帮助用户记录梦境、理解梦境，提供心理学视角、传统文化视角和 AI 启发式解析的自我探索工具。

---

## 项目结构

```
maozi-dream-decode/
├── backend/                    # FastAPI 后端 + Web 前端
│   ├── app/
│   │   ├── api/               # API 路由（认证、梦境、解析、百科）
│   │   ├── core/              # 配置 / 数据库 / JWT 安全
│   │   ├── models/            # SQLAlchemy 数据模型
│   │   ├── schemas/           # Pydantic 校验 schema
│   │   ├── services/          # 百炼大模型调用
│   │   └── web/               # Web 前端静态文件
│   │       ├── index.html
│   │       ├── styles.css
│   │       └── app.js
│   ├── scripts/               # 百科词条初始化脚本
│   ├── requirements.txt
│   └── Dockerfile
│
├── mobile/                     # Flutter 客户端（APK 用 GitHub Actions 打包）
│   ├── lib/
│   ├── .github/workflows/     # GitHub Actions CI/CD
│   └── pubspec.yaml
│
├── docker-compose.yml         # Docker 部署配置
├── nginx.conf                 # Nginx 反向代理配置
└── .env.example               # 环境变量示例
```

---

## 快速部署（服务器）

### 前置条件

- Docker & Docker Compose
- 阿里云百炼 API Key（可选，没有也能运行基础功能）

### 1. 上传代码到服务器

```bash
# 在你的电脑上
scp -r maozi-dream-decode root@120.48.13.152:/root/
```

### 2. 配置环境变量

```bash
cd /root/maozi-dream-decode
cp .env.example .env
nano .env
```

填入你的配置：
```
DB_PASSWORD=你的数据库密码
SECRET_KEY=随机生成的密钥
DASHSCOPE_API_KEY=你的百炼API Key
ALLOWED_ORIGINS=*
```

### 3. 启动服务

```bash
docker-compose up -d
```

### 4. 验证

| 服务 | 地址 |
|------|------|
| Web 前端 | http://120.48.13.152:60180 |
| API 文档 | http://120.48.13.152:60185/docs |
| 健康检查 | http://120.48.13.152:60185/health |

---

## Docker 服务说明

```
┌─────────────────────────────────────────────────────┐
│                    120.48.13.152                      │
│                                                       │
│  :60180 ──→ Nginx ──┬── /api/* ──→ FastAPI :8000    │
│                      └── /      ──→ Web 前端          │
│                                                       │
│  :60185 ──────────────────→ FastAPI (直接访问)        │
│                                                       │
│  :5432  ──────────────────→ PostgreSQL               │
└─────────────────────────────────────────────────────┘
```

| 容器 | 端口 | 说明 |
|------|------|------|
| dream-nginx | 60180 | Nginx 反向代理（前端入口） |
| dream-api | 60185 | FastAPI 后端 + Web 静态文件 |
| dream-db | 5432 | PostgreSQL 数据库 |

---

## 常用命令

```bash
# 查看日志
docker-compose logs -f api

# 重启服务
docker-compose restart

# 停止服务
docker-compose down

# 查看运行状态
docker-compose ps

# 进入数据库
docker exec -it dream-db psql -U postgres -d dream_app
```

---

## API 接口

启动后访问 Swagger UI: `http://120.48.13.152:60185/docs`

### 认证
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/v1/auth/register | 注册 |
| POST | /api/v1/auth/login | 登录 |
| GET | /api/v1/auth/me | 获取当前用户 |

### 梦境
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/v1/dreams | 创建梦境 |
| GET | /api/v1/dreams | 梦境列表 |
| GET | /api/v1/dreams/{id} | 梦境详情 |
| DELETE | /api/v1/dreams/{id} | 删除梦境 |

### AI 解析
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/v1/dreams/{id}/interpretations | 创建解析 |
| POST | /api/v1/dreams/{id}/interpretations/stream | 流式解析 |
| POST | /api/v1/dreams/{id}/interpretations/regenerate | 重新生成 |
| GET | /api/v1/interpretations/{id} | 获取解析结果 |

### 百科
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/encyclopedia | 百科列表 |
| GET | /api/v1/encyclopedia/search?keyword=xxx | 搜索 |
| GET | /api/v1/encyclopedia/categories | 分类列表 |
| GET | /api/v1/encyclopedia/{id} | 词条详情 |

---

## GitHub Actions 打包 APK

1. 在 GitHub 仓库 Settings → Secrets 添加 `API_BASE_URL`
2. 推送代码到 main 分支
3. Actions 自动构建，在 Artifacts 下载 APK

```yaml
# GitHub Secrets 配置
API_BASE_URL=http://120.48.13.152:60185
```

---

## 开发指南

### 本地开发后端

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# 配置 .env
cp .env.example .env

# 启动
uvicorn app.main:app --reload --port 8000
```

### 本地开发 Flutter

```bash
cd mobile
flutter pub get
flutter run
```

---

## 后续迭代

- [ ] 接入百炼 API Key 实现真实 AI 解析
- [ ] 语音输入（接入阿里云语音识别）
- [ ] 订阅付费功能
- [ ] 数据统计图表
- [ ] 分享海报生成
- [ ] iOS 打包上架
