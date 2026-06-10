# 上下文接力文档 — 玄符侦探多Agent开发项目

**用途：** 在新的Claude对话窗口中，将本文档作为第一条消息发送，即可无缝继续。

**生成时间：** 2026年5月26日
**当前进度：** Phase 0 + Phase 1 完成，Phase 2 即将开始

---

## 一、项目概述

**项目名称：** 玄符侦探：我替爷爷守事务所
**类型：** 中式灵异密室解谜手游，共9个章节（关卡），每章60-90分钟
**目标平台：** TikTok Minis（抖音小游戏）→ 微信小游戏 → H5
**开发引擎：** Cocos Creator 3.x，TypeScript，纯2D
**开发模式：** 一人公司（OPC），通过OpenClaw多Agent团队 + 飞书通道完成所有开发
**商业目标：** 第一步验证流程可行性，第二步将Agent团队产品化为SaaS服务

## 二、用户背景

- 有项目管理和产品设计经验，曾带过App开发团队
- AI方面是新手，需要详细的操作指导
- 追求性价比，优先使用免费或低成本的API/工具
- 电脑是专用实验机，Windows 11 24H2

## 三、文档体系（已完成初稿，全部IN REVIEW状态）

共17份策划文档（D-01至D-17）+ Agent架构文档 + 人工验收机制v2.0：

- D-01 GDC v1.2（游戏核心策划案）
- D-02 世界观设定 v1.0（注意：用户计划去掉"玄符秘录"约束）
- D-03 文件命名规范 v1.1
- D-04 本章GDD v1.1（第一章《清代幽影》）
- D-05 剧情主线 v1.0 + 内部审批记录
- D-06 角色设定 v1.0 + 内部审批记录
- D-07 谜题设计 v1.0（16个谜题，最终密码9401）
- D-08 PRD验收标准 v1.2
- D-09 WBS任务拆解 v1.2
- D-09.5 素材总清单 v1.1（89件素材）
- D-10 美术风格指南 v1.0 + v1.1
- D-11 UI视觉规范 v1.0
- D-12 音频设计文档 v1.0
- D-13 技术设计文档 v1.1（已新增跨平台抽象层PlatformAdapter）
- D-14 数据表规范 v1.0
- D-15 功能需求清单 v1.0
- D-16 测试用例 v1.0
- D-17 本地化合规报告 v1.0

**重要决策：** 故事线是临时的（服务于Demo），世界观和9章主线需要在Phase 4重新打磨。

## 四、技术环境（已搭建完成）

### 4.1 WSL2环境
- **系统：** Windows 11 24H2 + WSL2 Ubuntu 24.04
- **用户名：** ben
- **systemd：** 已启用
- **sudo：** 已配置免密（ben ALL=(ALL) NOPASSWD: ALL）
- **启动命令：** `wsl -d Ubuntu-24.04`

### 4.2 Node.js
- **版本：** v22.22.2（via nodesource）

### 4.3 Claude Code
- **版本：** v2.1.150
- **配置文件：** `~/.claude/settings.json`
- **模型：** glm-5-turbo（通过智谱Anthropic兼容端点）
- **关键配置：**
```json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "[需要用户重新填入，旧key已暴露需更换]",
    "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5-turbo",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5-turbo",
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
```
- **onboarding跳过：** `~/.claude.json` 中 `hasCompletedOnboarding: true`

### 4.4 OpenClaw
- **版本：** 2026.5.22
- **配置文件：** `~/.openclaw/openclaw.json`
- **模型：** zai/glm-5.1
- **Web UI：** http://127.0.0.1:18789/
- **Gateway：** systemd服务，`openclaw gateway restart` 管理
- **搜索引擎：** DuckDuckGo（免费，无需API key）

### 4.5 已启用的OpenClaw Skills
- coding-agent（调用Claude Code）
- clawhub（ClawHub技能市场）
- session-logs（会话日志）
- gh-issues（GitHub issue管理）
- session-memory hook（会话记忆）

### 4.6 已安装的系统工具
- gh（GitHub CLI）
- jq（JSON处理）
- ripgrep（文本搜索）

### 4.7 飞书通道
- **应用名：** 密室逃脱开发助手
- **App ID：** cli_aa9ff52d12b85bc3
- **App Secret：** [REDACTED — App Secret 已于 2026-06-14 轮换]
- **连接模式：** WebSocket长连接
- **群聊策略：** Open（requires mention）
- **DM策略：** Pairing（已批准用户ben的配对）
- **权限：** im:message, im:message:send_as_bot, im:message.group_at_msg:readonly, im:message.p2p_msg:readonly, contact:user.base:readonly
- **事件订阅：** im.message.receive_v1
- **应用版本：** v1.1.0已发布
- **飞书用户ID：** ou_3c093505848e815361b6210a07943351
- **Command Owner：** 已配置为上述用户ID

## 五、全局行动清单与进度

### ✅ Phase 0：环境稳定化（已完成）
- 0.1 WSL2 + Ubuntu 24.04 ✅
- 0.2 OpenClaw安装 ✅
- 0.3 冒烟测试通过 ✅

### ✅ Phase 1：飞书通道搭建（已完成）
- 1.1 飞书企业应用创建 ✅
- 1.2 OpenClaw飞书通道配置 ✅
- 1.3 冒烟测试（飞书↔Agent对话）✅

### 🔄 Phase 1.5：Claude Code插件安装（进行中）
正在安装：
1. **Superpowers**（obra/superpowers）— 203k星，最大的Claude Code skills框架，M4代码Agent必备
2. **ECC**（affaan-m/ECC）— 192k星，agent harness安全扫描和性能优化

安装命令（在Claude Code内执行）：
```
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
/plugin marketplace add https://github.com/affaan-m/ECC
/plugin install ecc@ecc
```

### ⬜ Phase 2：多Agent基础架构（下一步）
- 2.1 创建飞书群组（P1-总策划、M1-视觉、M4-开发）
- 2.2 配置3个独立Agent（p1-planner、m1-visual、m4-coder）
- 2.3 配置binding路由规则
- 2.4 配置Agent间通信（共享文件目录 + sessions_send）
- 2.5 冒烟测试多Agent协作

### ⬜ Phase 3：工具链接入
- 3.1 M1接图像生成（ChatGPT Plus手动 → GPT Image API自动化）
- 3.2 M4接编码工具（Claude Code CLI / OpenCode CLI）
- 3.3 M3接音频工具（Freesound免费库 + Suno免费额度）
- 3.4 端到端冒烟测试

### ⬜ Phase 4：故事与文档打磨
- 去掉"玄符秘录"约束
- 重新设计9章主线
- 级联更新全套文档

### ⬜ Phase 5：第一章素材生产与开发
### ⬜ Phase 6：复制到第2-9章 + 引入Hermes

## 六、关键技术决策记录

1. **编码工具选型：** OpenCode作为跨平台统一方案（海外配Claude/OpenAI API，国内配豆包/GLM）；Claude Code用于WSL2内操作
2. **图像生成：** ChatGPT Plus手动生成（验证阶段）→ GPT Image API自动化
3. **音频生成：** SFX用Freesound免费音效库，BGM/Stinger用Suno免费额度
4. **模型策略：** GLM-5-turbo/5.1作为主力（性价比），遇到质量瓶颈时单个Agent升级为更强模型
5. **跨平台架构：** D-13 v1.1新增PlatformAdapter抽象层，游戏逻辑零平台耦合
6. **Hermes引入时机：** 第一章用纯OpenClaw，第二章起引入Hermes学习循环
7. **协作模式：** Claude（本对话）当"军师"出方案，Claude Code当"手"执行操作，用户当"眼睛"确认

## 七、待调研/待安装的项目

已调研完成，按优先级排序：

**已决定安装（Phase 1.5）：**
- Superpowers — M4代码Agent的skills框架
- ECC — 安全扫描和harness优化

**Phase 2时参考：**
- Claude-Code-Game-Studios（Donchitos）— 49个游戏开发Agent + 73个skills，借鉴其层级结构
- agency-agents（msitarzewski）— 147个专业Agent角色模板，有中文版
- agency-agents-zh（jnMetaCode）— 中文版，含50个中国市场原创智能体

**Phase 3时安装：**
- ui-ux-pro-max（nextlevelbuilder）— M2 UI Agent的设计智能工具包

**关注但不急：**
- gstack（garrytan）— YC CEO的Claude Code setup，31个skills，原生支持OpenClaw
- Wanman（chekusu）— agent matrix runtime，概念类似OpenClaw多Agent
- Slock.ai — 人+AI协作平台，SaaS阶段的竞品参考

## 八、已知问题

1. **[P0 安全] ✅ 已完成（2026-06-14）：旧 GLM key 已吊销。** 用户在截图中暴露了GLM API key，已去智谱后台吊销
2. **Homebrew安装失败：** 因GitHub网络问题，改用apt安装依赖
3. **中国大陆网络限制：** GitHub访问不稳定，Claude Code首次连接需跳过onboarding
4. **GLM模型能力上限：** 编码能力与Claude Sonnet有差距，M4可能需要升级模型
5. **41个OpenClaw skills因缺依赖被禁用：** 大部分是macOS专用或需要Homebrew，已禁用不影响使用

## 九、用户收集的经验（已整合到方法论）

1. **五步超级智能体：** 角色知识→联网→专属数据→成本管控→完整闭环
2. **Skill Graphs 2.0：** 组合skills产生杠杆效应
3. **Skills工程化：** commands是触发入口，skills是完整工作流定义

这三条经验对应项目三个阶段：Phase 2每个Agent配persona+知识库（经验一），Phase 3把工作流写成SKILL.md（经验三），Phase 6 Hermes学习循环形成协作图谱（经验二）。

---

**新窗口的第一条指令建议：**
"请阅读这份上下文接力文档，确认你了解项目全貌和当前进度后，我们继续Phase 1.5（安装Superpowers和ECC插件）。"
