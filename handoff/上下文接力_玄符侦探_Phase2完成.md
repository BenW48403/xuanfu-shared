# 上下文接力文档 · 玄符侦探 · Phase 2 完成

> 用途：开新对话时把本文档贴给 Claude（军师），即可无缝续上。
> 角色分工：**你=制作人/眼睛/审批**；**Claude（对话）=军师/出方案**；**Claude Code=手/执行**。
> 环境：Windows 11 + WSL2（Ubuntu 24.04，用户 `ben`，主机 WIN-BT14K9T4AH7）。

---

## 0. 项目一句话
中式恐怖解谜手游《玄符侦探：我替爷爷守事务所》——9 章主线、Cocos Creator 3.x + TypeScript、纯 2D，目标平台 **抖音小游戏 → 微信小游戏 → H5**。用 **OpenClaw 多 Agent 团队 + Claude Code** 协作开发，先跑通一条流水线，后续把这套 Agent 团队产品化。关键原则：**H5 优先验证、平台零耦合（走 PlatformAdapter）、控制成本**。剧情世界观目前是临时 Demo，Phase 4 重做。

---

## 1. 当前进度：✅ Phase 2（多 Agent 基座）已完成
- Phase 0 环境 ✅ / Phase 1 飞书通道 ✅ / Phase 1.5 Claude Code 插件（Superpowers+ECC）✅
- 模型已全部切到 DeepSeek（Claude Code + OpenClaw）✅
- **Phase 2 全部完成**：
  - 三个 agent（p1-planner / m1-visual / m4-coder）建好、填好中文人格、各自绑定到对应飞书群，飞书实测进角色、互不串味 ✅
  - Agent 间通信打通（见 2.3 的重要结论）✅
  - 共享目录 `~/xuanfu-shared/` 建好、文件交接连验两次可靠 ✅
  - 协作约定（共享目录 / 同步 send / 协调日志）已固化进三个 AGENTS.md ✅
  - 可观测性：协调日志文件 `~/xuanfu-shared/handoff/coordination-log.md` ✅
- **下一步：Phase 3（工具）**；另有若干待办见第 3 节。

---

## 2. 关键参考事实

### 2.1 飞书四个群 chat_id
| 群 | chat_id | 绑定 |
|---|---|---|
| P1·总策划 | `<P1群_chat_id：见本地 openclaw.json bindings>` | p1-planner ✅ |
| M1·视觉 | `<M1群_chat_id：见本地 openclaw.json bindings>` | m1-visual ✅ |
| M4·开发 | `<M4群_chat_id：见本地 openclaw.json bindings>` | m4-coder ✅ |
| 📋 监控·日志 | `<监控群_chat_id：见本地 openclaw.json bindings>` | 未绑定（留作监控用，方案 B 待做） |
- 一个机器人「密室逃脱开发助手」(Feishu App ID `cli_aa9ff52d12b85bc3`)，按群路由。群内默认 @ 才回。
- 注意：监控群日志里有 `getChatInfo failed ... 400`，机器人可能缺该群"读取群信息"权限（不影响接收消息；做方案 B 时需留意发送权限）。

### 2.2 OpenClaw 配置现状（`~/.openclaw/openclaw.json`）
- gateway = **systemd 用户服务**（`openclaw gateway restart` 管理，从配置文件读 key，不靠环境变量）。
- 默认模型：`agents.defaults.model.primary = "deepseek/deepseek-v4-pro"`（DeepSeek 是内置 provider，自动启用）。
- `agents.list`：main + p1-planner（含 `subagents.allowAgents:["m1-visual","m4-coder"]`）+ m1-visual + m4-coder。
- `bindings`：3 条（P1/M1/M4 → 各自群）。
- `tools.agentToAgent`：`{ enabled:true, allow:["main","p1-planner","m1-visual","m4-coder"] }`。
- `tools.sessions.visibility = "all"`（跨 agent 同步 send 必需）。
- API key 在 agent 层 `~/.openclaw/agents/main/agent/auth-profiles.json`：profile `zai:default`(GLM,保留备用) + `deepseek:default`(现用)。
- `models.providers.zai`、`channels.feishu`、GLM 相关均保留未删（方便回退）。
- 历次改动均有带时间戳 `.bak` 备份。

### 2.3 ⭐ Agent 间通信的重要结论（来之不易，务必记住）
- **可靠通道 = 同步消息 `sessions_send`（带 timeoutSeconds 等回复）**：P1 在自己这一轮拿到对方回复，再用正常群回复转告 → 稳。
- **`sessions_spawn` 的异步"完成通知"在本版本(OpenClaw 2026.5.22)不可靠**（best-effort，报错 `completion agent did not deliver through the message tool`）。所以**派活别用 spawn 等回报，用同步 send**。已写进 AGENTS.md 规则。
- **Agent 无法往"没绑定给它"的飞书群直接发消息**（无 message 工具/不支持跨群投递）。所以监控群"实时推送"要走飞书自定义机器人 webhook（方案 B，待做）。**不要把主 bot token 交给 agent 走 curl**（安全隐患）。
- **真正可靠的协作骨架 = 文件交接**（共享目录），不依赖聊天投递。
- 完整的 agent 间原始往来，OpenClaw 会话转写/gateway 日志（`/tmp/openclaw/`）里全程有记录，可审计。

### 2.4 共享目录 `~/xuanfu-shared/`
- `docs/`（设计文档 D-01~D-17）、`art/`（M1 产出）、`code/`（M4 产出）、`handoff/`（任务交接单）。
- `handoff/coordination-log.md` = 协调日志，agent 派活/交接时追加一行，制作人 `cat` 或 `tail -f` 查看。
- 无文件系统沙箱：三个 agent 都能直接读写此目录。

### 2.5 Agent workspace 文件（每个 `~/.openclaw/workspace-<id>/`）
- `SOUL.md`（中文人格）、`IDENTITY.md`（中文名+emoji：🧠总策划P1 / 🎨视觉M1 / 💻开发M4）、`USER.md`（制作人+项目背景，三者共用）、`AGENTS.md`（默认手册 + 项目追加段：团队结构/中文硬规则/跳过BOOTSTRAP/群聊礼仪/共享目录/通信规则/协调日志）。
- `BOOTSTRAP.md` 已删（否则 agent 会问"给我起名"）；`HEARTBEAT.md` 保持空（省钱）；`TOOLS.md` 默认。
- ⚠️ **AGENTS.md 改动对新会话才生效**（agent 会话每天凌晨 4 点自动刷新）。要立即生效需强制刷新会话。

### 2.6 Claude Code 现状
- 在 DeepSeek 上（`~/.claude/settings.json`：base `https://api.deepseek.com/anthropic`，模型 `deepseek-v4-pro[1m]`，haiku 档→`deepseek-v4-flash`）。插件 Superpowers + ECC 已装。
- **ECC GateGuard hook**：每会话首个 bash/edit 前要求"先陈述事实"——正常机制，不是报错；嫌烦设 `ECC_GATEGUARD=off`。
- Claude Code 是独立会话**看不到本接力文档**，派活时把已知事实直接喂给它。

### 2.7 操作纪律（沿用）
- 只读命令（cat/ls/grep/find/diff/status）→ 自行 Yes；会"动东西"的（改/删文件、改配置、restart gateway）→ 先停问军师。
- 改配置前：备份 + 校验 JSON（`python3 -m json.tool`）+ 只重启一次 + 留 .bak 还原路径 + 一次一件。
- 长终端输出别靠粘贴（会被 Claude Code 折叠/截断）：用 `cat` 直出或存文件上传。

---

## 3. 待跟进 / 下一步（按优先级）
1. **[P0 安全] ✅ 已完成（2026-06-14）**：飞书 App Secret 已轮换、DeepSeek key 已轮换、旧 GLM key 已吊销。今后别把真实 key 写进共享文档/聊天。
2. **[P1] D-15 硬编码 `tt.*`**（建于旧 D-13 v1.0，FR-12 广告 / FR-30/31 存档）与 D-13 v1.1 的 PlatformAdapter 零耦合冲突、破坏 H5 优先——**Phase 5.1 前必须调和**。
3. **[P1] Phase 4 "玄符秘录"删除联动**（D-02~D-09.5）**漏了** D-12(音频 sting_ch01_book_open) + D-07 P-14 + D-05/D-06 禁区。
4. **监控群实时推送（方案 B）**：飞书群加"自定义机器人"拿 webhook URL → 小中继把 coordination-log 新内容推到监控群（chat_id 见 2.1）。顺带解决 2.1 的 getChatInfo 400 权限。
5. **[P2] 飞书配额复核**：60s 健康检查实际 ~43,200/月 vs 5万上限（仅 ~6,800 余量），核对探测间隔。
6. **[P2] D-01 版本号不一致**（文件名 v1.2 vs 正文 v1.0）。
7. **下一阶段**：Phase 3（工具）→ Phase 4（剧情/文档返工）→ Phase 5（第 1 章生产）→ Phase 6（复制 2-9 章）。
8. 团队扩张/剧情返工时，可参考 `agency-agents`（msitarzewski/agency-agents，约 98k 星/147 agents，及中文版 agency-agents-zh）作为人格参考库——**不整体安装**，借文本即可。

---

## 4. 开新对话怎么用
把本文档整篇贴给新的 Claude，说一句："这是玄符侦探项目的接力文档，Phase 2 已完成，现在想做 [Phase 3 / 监控群方案B / 密钥轮换 / ……]。" 即可无缝继续。
