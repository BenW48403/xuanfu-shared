# 上下文接力补遗 — 玄符侦探 · Phase 1.5 完成 + 待跟进清单

**用途：** 本文件是《上下文接力文档_玄符侦探_Phase0-1完成.md》的补遗。在新对话窗口中，可与主接力文档一并发送，用于无缝衔接。
**生成时间：** 2026年5月30日
**进度更新：** Phase 1.5（Claude Code 插件安装）已完成；下一步进入 Phase 2（多 Agent 基础架构）。

---

## 一、Phase 1.5 完成记录

### 1.1 成果
在 WSL2 内的 Claude Code（v2.1.150，接智谱 GLM-5-turbo 端点）上，成功安装并激活两个插件：

- **Superpowers**（obra/superpowers，版本 5.1.0）—— 代码 Agent 的 skills 框架，强制"头脑风暴 → 出计划 → 再写代码 + TDD"的开发纪律。
- **ECC**（affaan-m/ECC）—— agent 运行框架（harness），含持久记忆、调度、安全扫描等能力。

### 1.2 激活后的最终状态
`/reload-plugins` 输出确认：

```
Reloaded: 2 plugins · 79 skills · 69 agents · 29 hooks · 6 plugin MCP servers · 0 plugin LSP servers
```

命令验证（打 `/` 可见）：
- `/brainstorming`（superpowers）
- `/ecc:plan`、`/ecc:learn`、`/ck`（持久记忆）、`/ecc:pr` 等一整排 `/ecc:*` 命令。

### 1.3 为什么装这两个（与项目目标的关联）
当初为 M4 代码 Agent 选型：Superpowers 负责"写代码前先想清楚 + 测试驱动"的质量纪律；ECC 负责给 Agent 加运行框架和跨会话记忆。两者合起来＝**M4 的代码质量脚手架就位**。

### 1.4 待复核的小事（不紧急）
- ECC 带进来了 **6 个 plugin MCP servers**。后续配置 M4 时，建议回头看一下这 6 个分别是什么、哪些用得上、哪些需要配密钥或可以禁用，避免无谓的资源占用或外联。

---

## 二、插件安装避坑清单（可复用套路）

这次安装一路踩了 5 个坑，全部解决。把它沉淀成一套"遇到什么报错 → 怎么处理"的决策清单，**以后再装任何 Claude Code 插件、或给 Agent 接工具时都能直接套用**。

| # | 报错现象 | 根因 | 解法 |
|---|---|---|---|
| 1 | `SSH host key is not in known_hosts` / `Host key verification failed` | 用了 `owner/repo` 简写，被解析成 SSH clone，但没存 GitHub 主机指纹 | **改用 HTTPS 全网址**：`/plugin marketplace add https://github.com/owner/repo` |
| 2 | `Git clone timed out after Ns` | 能连上但下载太慢/仓库太大，超时被掐断 | **调长超时**：退出 claude → `export CLAUDE_CODE_PLUGIN_GIT_TIMEOUT_MS=300000`（5分钟）或 `900000`（15分钟）→ 重启 claude → 重试 |
| 3 | `SSL connection timeout` / `unable to access ... github.com` | 连接根本建立不起来（网络墙/链路不稳），调超时无效 | **配国内镜像**（一次配好，所有 github 下载自动加速）：`git config --global url."https://gitclone.com/github.com/".insteadOf "https://github.com/"` |
| 4 | 镜像也太慢、仍超时 | 仓库过大 + 跨境链路实在吃力 | **终极方案：网页手动下 ZIP → 本地装**。详见下方 2.1 |
| 5 | 插件装好了但 `/` 里看不到新命令 | 安装后未"应用"，光重启在 v2.1.150 不够 | **跑 `/reload-plugins`**，再打 `/` 验证 |

### 2.1 终极方案详解：本地 ZIP 安装（绕开一切网络）
当 git clone 怎么都过不去时，这招最稳：

1. 浏览器进 GitHub 仓库页 → Code → Download ZIP（走的是网页 CDN，常比 git clone 更通）。
2. 在 WSL2 里解压（Windows 的 C 盘 = WSL 里的 `/mnt/c/`）。无需装 unzip，用 Python 即可：
   ```
   python3 -c "import zipfile; zipfile.ZipFile('/mnt/c/Users/<用户名>/Downloads/<包名>.zip').extractall('/home/<用户名>/')"
   ```
3. 确认插件身份文件在：`ls /home/<用户名>/<解压出的文件夹>/.claude-plugin/`，应能看到 `marketplace.json`。
4. 进 Claude Code，用**本地路径**（不是网址）添加市场，然后安装：
   ```
   /plugin marketplace add /home/<用户名>/<解压出的文件夹>
   /plugin install <插件名>@<市场名>
   ```
5. `/reload-plugins` 激活。

### 2.2 两个易忘点
- **`export` 设的环境变量只在当前终端窗口有效**，关掉窗口就没了。下次新开窗口再装插件，超时设置要重设。
- **`git config --global` 设的镜像是全局持久的**，所有 github clone 都会走它。撤销命令（现在留着不用撤）：
  ```
  git config --global --unset url."https://gitclone.com/github.com/".insteadOf
  ```

---

## 三、待跟进问题清单（按优先级）

以下是审阅文档与 Phase 计划时标记的问题，逐项跟进即可。

### P0 — 安全，尽快处理
- **轮换两个已暴露的密钥。** 飞书 App Secret 以明文写在主接力文档第四章里；GLM API key 主接力文档自己也记了"已暴露需更换"。建议去飞书开发者后台重置 App Secret、去智谱控制台重建 key，新值填回 `~/.claude/settings.json` 与飞书配置。**今后接力文档里只放占位符，真值单独存**，别再写进会到处传阅的文档。

### P1 — 影响后续阶段，进相关 Phase 前处理
- **D-15 与 D-13 v1.1 的平台耦合冲突（进 Phase 5.1 前必须解决）。** D-15 的输入来源标的是 D-13 **v1.0**，里面 FR-12 直接硬编码 TikTok 广告 SDK `showRewardedAd()`、FR-30/FR-31 直接硬编码 `tt.setStorage / tt.getStorage`。但 D-13 已升 **v1.1** 并新增 PlatformAdapter 抽象层，目标是"游戏逻辑零平台耦合"。两者打架。
  - 后果不只是返工：Phase 5.5 计划"**先出 H5 网页版**验证"，而浏览器里根本没有 `tt.*` 这套 API，硬编码版本一上 H5 就崩——会直接挡住最快的验证路径。
  - **处理：** 进 Phase 5.1（M4 搭骨架）之前，先把 D-15 对齐到 D-13 v1.1——存档与广告统一走 PlatformAdapter，不直接调平台 API。
- **Phase 4 级联范围漏了 D-12。** Phase 4 计划去掉"玄符秘录"约束，级联更新写的是 D-02 → D-04 → D-05 → D-06 → D-07 → D-08 → D-09.5。但玄符秘录的依赖比这更深，至少还伸进了：
  - **D-12** 的 `sting_ch01_book_open`（翻开秘录的 Stinger 音效）—— **不在 D-02~D-09.5 区间内，会被漏掉**；
  - D-07 的 P-14 谜题、D-05/D-06 的跨章节禁区也都引用了秘录。
  - **处理：** Phase 4 级联清单补上 D-12（以及核对 D-05/D-06/D-07 的相关条目）。

### P2 — 待核实 / 次要
- **飞书配额数字自相矛盾（需核实）。** Phase 1 写"每 60 秒 health check，约 27,000 次/月，不会超限"。但每 60 秒一次实际是 1,440 次/天 × 30 = **43,200 次/月**，不是 27,000。更要紧的是：43,200 顶着所述的 50,000 次/月免费上限，**真实余量只剩约 6,800 次/月**给实际消息收发，开发高峰多 Agent 并发时可能撞限。
  - **核实两点：** ① health check 真实间隔能否拉长；② 飞书免费额度 50,000 这个数是否为当前真实值。必要时调长 health-check 间隔。
- **D-01 版本号对不上。** 文件名与接力文档都标 v1.2，但 D-01 文档正文写的是"文档版本：v1.0"。核对哪个为准并统一。
- **（备查）接力文档里的 star 数严重夸大。** 主接力文档把 Superpowers 记作"203k 星"、ECC"192k 星"，实际两个仓库远没这么大（Superpowers 是 2025年10月随 Claude 插件系统首发的项目，量级几百到几千；ECC 主仓已改名 everything-claude-code，规模是几十个 agents、上百个 skills）。两者都是真实可用的好项目，但"最大的框架"这一判断基于错误数字，相关决策建议按实际价值重新审视。
- **（低优先）CVE-2026-22176 无法核实。** Phase 0 中作为"OpenClaw 原生 Windows 有漏洞、改用 WSL2"的理由之一引用。无法在当前核实其真伪；但 Phase 0 已完成、用 WSL2 的决定本身合理，故低优先，不影响推进。

---

## 四、环境现状快照（本次新增/变更）

- **已装插件：** superpowers 5.1.0；ecc（经本地 ZIP 安装）。
- **新增全局 git 配置：** github.com → gitclone.com 镜像改写（`insteadOf`）。注意此改写影响所有 github clone；如日后造成问题，撤销命令见 2.2。
- **当前终端会话内设置的环境变量：** `CLAUDE_CODE_PLUGIN_GIT_TIMEOUT_MS=900000`（仅当前窗口有效，非持久）。
- **新引入待复核：** ECC 带来的 6 个 plugin MCP servers（见 1.4）。

---

## 五、关键决策补记

### 5.1 图像生成管线（M1）

经分析对比三条路径后定案：

- **不采用**"M1 出提示词 → 人工在 ChatGPT 手动出图"为目标方案。原因：① ChatGPT/DALL-E 对鬼怪/血腥/灵异内容常拒绝，与本作"中式灵异恐怖"题材冲突；② 手动不可规模化（89 件素材 × 变体 × 迭代）。
- **架构原则：M1 调图像生成的 HTTP API，而非用计算机操作驱动 GUI**（后者脆弱、烧 token）。
- **验证期：** M1 → 开源模型 API（Flux，经 fal.ai / Replicate）。零内容审查、可自动化、近零搭建、按张计费便宜，先验证提示词质量。
- **生产期：** 转 serverless ComfyUI API（RunComfy / ComfyDeploy / RunPod 等，工作流一键变 API、空闲缩零），配定稿锁定的工作流，必要时训练自有风格 LoRA。优势：真·风格锁定（恰是 D-10"锁风格、只改内容词"规则的技术化身）+ 批量 + 不审查 + 规模成本低。
- **避免：** ① 自建 7×24 常驻云 GPU 服务器（除非每日大量出图）；② 计算机操作驱动 GUI。

此决策已同步进 M1 的 persona（草稿 v2）。

---

## 六、下一步

进入 **Phase 2：多 Agent 基础架构**
- 2.1 ✅ 已完成：三个飞书群已建、机器人已入群。路由钥匙（chat_id）：
  - P1·总策划 → `<P1群_chat_id：见本地 openclaw.json bindings>`
  - M1·视觉 → `<M1群_chat_id：见本地 openclaw.json bindings>`
  - M4·开发 → `<M4群_chat_id：见本地 openclaw.json bindings>`
- 2.2 配置 3 个独立 Agent（p1-planner、m1-visual、m4-coder），各配 workspace + persona — persona 草稿 v2 待定稿
- 2.3 配置 binding 路由规则
- 2.4 配置 Agent 间通信（agentToAgent + 共享文件目录）
- 2.5 冒烟测试：P1 群下指令 → P1 转给 M1 → M1 回结果

**新窗口第一条指令建议：**
"请阅读主接力文档和这份补遗，确认进度后，我们从 Phase 2 开始。注意进 Phase 5 前需先处理 D-15 与 D-13 v1.1 的平台耦合冲突（见补遗 P1）。"
