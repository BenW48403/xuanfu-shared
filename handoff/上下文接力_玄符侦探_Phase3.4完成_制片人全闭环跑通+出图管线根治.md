# 上下文接力 · 玄符侦探 · Phase 3.4 完成

**主题**：多 Agent 制片人闭环首次端到端跑通（含质检与迭代）+ 出图管线根治 + session 重载机制确立

**状态**：Phase 3.4（端到端冒烟）✅ 完成

---

## 一、本阶段达成（端到端验证）

以 **ART-CH01-005（镇阴博物馆·地下储藏室）** 为验收单，完整跑通全链路：

> P1 接需求 → 开工单 → a2a 派 M1 → **M1 detached 出图（无 SIGKILL）** → 落 `art/ch01/_wip/bg_ch01_storage_v1.png` → M1 自评回报 → **P1 初验（审图）揪出 v1 不符规格（石狮子≠守墓人陶俑、缺线香铜牌）→ 退回** → M1 重出 v2 → P1 初验过 → P1 发预览进 P1 群 + 呈报 → Ben 终审批准 → **P1 升格 v2 → 定稿 `art/ch01/bg_ch01_storage.png` → git commit/push → 记 coordination-log**。

逐环验证：**分工**（P1 只调度/验收/呈报、不出图；M1 出图）、**迭代**（`_vN` 版本）、**质检**（审图初验能挡不合格稿）、**单一真相源**（定稿入库）、**非阻塞**（待审落盘、P1 不卡死）。

---

## 二、血泪铁律（本阶段最值钱的经验）

**`gateway restart` ≠ session reload。**

OpenClaw 的 session 持久化到磁盘（`~/.openclaw/agents/<id>/sessions/`），context 在**首次编译时快照、之后永不刷新**；只有**新建 sessionId** 才会重新编译 SOUL。所以改完 SOUL/TOOLS 后**光重启网关无效**——活 agent 仍跑旧 SOUL。

本阶段绕最多圈的根就在此：detached、出图铁律、`_wip` 命名全改对了却不生效，皆因 P1/M1 的活 session（11:01–11:02 创建）从未重编译。

**正确做法（改完任何 persona 必走）：**
```
~/openclaw-reload.sh [agent...]   # 轮换 sessionId（缺省全部4个）→ 自动 gateway restart
# 然后在对应渠道发一条消息，触发新 session 创建 + 重编译 SOUL
```
> 安全性：轮换 session 只丢会话闲聊上下文；工单状态在 coordination-log（已落盘），新 session 醒来先读 log 重建。

---

## 三、工具与用法

| 工具 | 用法 | 说明 |
|---|---|---|
| `genimage.sh`（detached） | `genimage.sh "<prompt>" "<章号>" "<基名>" "<版本>" gpt` | 落 `art/ch<章>/_wip/<基名>_v<版>.png`；前台秒返回、后台出图、写 `.done`/`.failed`；agent 两步轮询；`--sync` 供人工/shell 同步调用。强制 `_wip` 路径、章号/基名校验、版本自增。走 fal.ai `fal.run/openai/gpt-image-2`，含超时(240s)+重试。 |
| `feishu_send.py` | `python3 ~/mcp/feishu/feishu_send.py <chat_id> <file> [caption]` | 图内联 / 文件附件。**仅 P1 用、仅发 P1 群**（呈报终审单一声道）。绕开 OpenClaw 内置 message 发图 bug。需飞书 `im:resource` 权限。 |
| `openclaw-reload.sh` | `~/openclaw-reload.sh [agent...]` | 轮换 session 强制重载 SOUL（见铁律）。 |
| `xuanfu-status.sh` | `bash ~/xuanfu-status.sh` | 一键查：出图进程 / `_wip` 最新文件 / coordination-log 末尾 / 网关状态。判"在跑/已完成/疑似卡死"。 |

---

## 四、工作流 SOP

**出图全闭环**：M 出 `_vN` 草稿（detached genimage，落 `_wip`）+ 自评 → 回报 P1（工单号+路径+自评）→ P1 初验（审图）→ 合格则发预览进 P1 群 + 呈报 / 不合格退回重出 → Ben 终审 → P1 升格定稿（`cp _vN → 干净名` 入 `art/ch<章>/`）+ `git commit/push` + 记 coordination-log。

**判"卡死 vs 等待"**：① 先问 P1「<工单号> 状态」（非阻塞、随时可答）；② P1 哑了再跑 `xuanfu-status.sh`；③ 无进程 + 无新图 + 超 5 分钟 → `openclaw-reload.sh` 重启。detached 后台出图约 30–90s。

**改 persona**：必走 `openclaw-reload.sh` + 发消息，否则不生效。

---

## 五、资产 / 目录 / 仓库（单一真相源）

- **权威源**：WSL `~/xuanfu-shared/` + GitHub `github.com/BenW48403/xuanfu-shared`。定稿入库，游戏工程从仓库拉。
- **结构**：`art/ch<章>/` 定稿（git 跟踪）；`art/ch<章>/_wip/` 放 `_vN` 草稿（**git 忽略**：`art/**/_wip/`）；`audio/ch<章>/` 同构。
- **ch01 定稿**：`bg_ch01_hall.png`（入口大厅）、`bg_ch01_storage.png`（地下储藏室）。
- **桌面 `Demo\`** = 临时预览（出图时单向推、可漂移、**非权威**）。
- **命名**：草稿 `<基名>_vN`（小改可 `v2.1`）；定稿干净名；coordination-log 记 `vN→定稿`。
- 注：大量 PNG 入 git，长期建议 git-lfs。

---

## 六、模型配置

- **P1 = `volcengine/deepseek-v4-pro`**（多工具编排稳；纯文本，审图经 image 工具→doubao 解耦，不受影响）。
- **其余 agent / 审图 = `volcengine/doubao-seed-2.0-pro`**。
- 火山 Coding Plan Lite，端点 `/api/coding/v3`（**勿用** `/api/v3`，那是按量计费）。Ark key 存 agent auth-profiles.json。
- Claude Code（执行器）仍走 Ben 的 DeepSeek 直连 API（不占 Lite 配额）。
- 注：火山托管的 deepseek-v4-pro 仍是纯文本（探针证实 `Model do not support image input`）；DeepSeek 消费端识图（5/9）与 V4.1 原生多模态（灰测中）不等于火山 API 端可用。

---

## 七、待办 / 开放项

- **002/003/004 已作废**（均为早期 bypass 绕过 M1 的产物），仅留 005 干净定稿。
- **音频管线尚未走过该闭环** — 下阶段验：M3 出 BGM/SFX 草稿 `_vN`（落 `audio/ch01/_wip/`）→ P1 初验 → 升格 `audio/ch01/`。预览经 feishu_send.py 发音频附件。
- **配音/TTS 范围未定** — D-12 仅覆盖 BGM/SFX/Stinger，无配音；若做由 M3 owns（火山 Doubao TTS 在 `/api/v3` 按量）。Ben 与 P1/P2 定。
- **OpenClaw 升级延后** — 最新官方飞书插件(2026.4.8)原生支持发图/文件，但升级有 break-change 史；放专门维护窗口单独做。当前 feishu_send.py 绕法版本无关、够用。
- **a2a 复用 session 的副作用** — 已靠 openclaw-reload.sh 解决；记住每次 persona 变更都要 reload。

---

*接力锚点：下一阶段（音频闭环 / Ch01 剩余场景批量出图）从「六、模型」「四、SOP」「二、铁律」三节切入即可。*
