# 上下文接力 ·《玄符侦探》· Phase 3.3 完成（M3 音效 Agent 接入音频工具）

> 接续《上下文接力_玄符侦探_Phase3.2完成_M4开发环境脚手架.md》。
> 至此 **Phase 3 工具链全部就绪**：M1 出图（3.1）+ M4 开发环境（3.2）+ M3 音频检索管道（3.3）。
> 提醒：每个 Claude 对话独立、不跨窗口记忆，**接力文档系列是项目主线**。
> 本阶段只接管道、不生产音频；正式生产在 Phase 5.3。

---

## 〇、本阶段顺带闭环的 P0 安全（重要，已解决）

排查公开仓库 `github.com/BenW48403/xuanfu-shared` 时发现 **飞书 App Secret 明文泄漏**（旧 commit `Phase0-1完成.md` 内），已处理：

- **飞书 App Secret**：已在开放平台重置（旧值 `KcvIafC…` 当场作废）→ 新值经 Claude Code 写入 `~/.openclaw/openclaw.json` 的 `channels.feishu.appSecret` → 网关热重载 → 飞书冒烟恢复正常。
- **DeepSeek key**：已轮换。**旧 GLM key**：已吊销。
- **洗仓库**：明文 secret 已抹除并 `--amend` 折进唯一 commit（`2ce0d6c → 7ccccd6`，force-push），新克隆在当前树与全历史均无残留（已独立复核）。4 个 handoff 文件的 `[P0 安全]` 项已标 `✅ 已完成（2026-06-14）`。
- 残留风险：GitHub 可能按 SHA 短期缓存旧 commit `2ce0d6c`，但 secret 已轮换作废，无害。
- **教训固化**：真实 key 一律不进仓库/对话；本地走 `~/.fal_key` `~/.freesound_key`（chmod 600）或网关 env 注入。

---

## 一、Phase 3.3 完成内容

### 1. 任务①：M3 音效 Agent 已建成
- Agent ID：`m3-audio`；飞书群 chat_id：`oc_63a68c41305c9a242756829c680d5298`。
- Workspace：`~/.openclaw/workspace-m3-audio/`；persona 写入其 `SOUL.md`（含职责 / 许可铁律 / 世界观 / 规格 / 命名 / 流程 / 下载边界 / 已知待办）。
- 常驻上下文：`D-12_音频设计文档_玄符侦探_v1.0.md` 已复制进 workspace。
- 交付目录：`~/xuanfu-shared/assets/audio/ch01/` 已建。
- Binding（互不串）：
  - `m3-audio  ← feishu group:oc_63a68c41305c9a242756829c680d5298`
  - `p1-planner← feishu group:oc_38dec2592fbdd125063d7d15078e913e`
  - `m1-visual ← feishu group:oc_d06fbfe6d927a59ee734b907204b1760`
  - `m4-coder  ← feishu group:oc_d25063c7ecf3e2e64a47b449a856d85d`
- 冒烟①：M3 准确复述许可铁律（CC0/CC-BY、排除 NC、署名、记 ID/作者/许可/链接）与 SFX 规格（WAV 44.1k/16bit）→ persona + D-12 生效。

### 2. 任务②：Freesound MCP 已接通
- **MCP**：`@mushan_bit/freesound-mcp` v1.0.2（npm；入口 `build/index.js`）。
  - 注：最初核定的是 `timjrobinson/FreesoundMCPServer`，Claude Code 实装换成了 mushan 版（带 download 工具）。两者搜索均用 token 认证。mushan 限制见 §三。
- **注册**：全局 MCP（OpenClaw 不支持 per-agent scope），m3-audio persona 内有使用指令。
  - 命令：`openclaw mcp set freesound '{"command":"bash","args":["/home/ben/mcp/freesound-run.sh"]}'`
- **凭证（关键修复）**：直接靠 systemd drop-in 注入网关时，env 未传到 MCP 子进程 → Freesound 回 401（`Token undefined`）。改用 **wrapper 脚本** `~/mcp/freesound-run.sh`：spawn 时从 `~/.freesound_key`（chmod 600）读 key → export → exec node。`openclaw.json` 内无任何 secret（仅 command + args）。
- **可用工具**：`freesound_search`（query / maxDuration / license）、`freesound_download`（soundId / quality hq|lq / downloadDir）。

### 3. 验收（端到端 + 反幻觉）
- **真实调用验证**：M3 群搜 `guqin` ≤15s 返回 3 条；与 Claude Code 直连 Freesound 同查询 curl 结果**逐条吻合**（176266/CC-BY4.0/7.12s、448159/CC-BY3.0/6.50s、415167/CC0/13.24s）→ 确认 M3 真调 MCP、字段回得全、自动套许可铁律，非幻觉。
- **封管道（ffmpeg 转规格）**：源 id=415167（CC0）→
  - SFX：`pcm_s16le 44100Hz 1ch` ✅（D-12：WAV 44100Hz 16bit）
  - BGM：`mp3 44100Hz 128kbps 10.03s` ✅（D-12：MP3 128kbps 循环）
  - 工具链就绪：`ffmpeg` + `sox` 已装于 WSL。

---

## 二、决策记录（D1 / D2，本阶段拍板）

- **D1 = B 主 + Suno 兜底**：BGM/Stinger 以 **Freesound 分层合成**为主（古琴单音 / 低频 drone / 风声 / 滴水 / 编钟单音等 CC0 素材，ffmpeg/sox 混音 + 无缝循环）。**Suno Pro 仅作两条音乐性 Stinger 的兜底**，是否启用待 Phase 5.3 生产时定。
- **D2 = A 人工下载**：Freesound 原件下载需 OAuth2，当前 MCP 不支持；第一章 14 条 SFX 量小，**人工下载原件**最省事。OAuth2 自动化留 Phase 6 量产再议。
- **许可红线**：仅 CC0 / CC-BY；排除 CC-BY-NC、Sampling+ 等限商用许可。CC-BY 须在游戏「鸣谢」页署名。

---

## 三、⚠ 已知限制 / 待办（主要给 Phase 5）

1. **mushan MCP 两处限制**：
   - search 返回字段写死（id/name/duration/previews/license），**无 username**，且无 get_sound → **CC-BY 作者名拿不到**。对策：D2=A 人工下载时，作者就在 Freesound 声音页面上，下载/审批那步顺手记进 D-12 §五。
   - `license` 参数**只能传单值**。对策：Phase 5 让 M3 搜完**按返回的 license 字段客户端筛** CC0/CC-BY（字段本就回），不依赖该参数。
   - 若上述两点嫌烦：备选换回 `timjrobinson/FreesoundMCPServer`（吃完整 Solr `filter` 字符串 + 有 get_sound / get_similar）。
2. **Freesound 中式素材偏少**：英文关键词 `guqin / zither pluck / bianzhong / chinese bell / bamboo flute / xiao`；找不到时降级 `asian zither` / `temple bell` + 后期处理。
3. **`sting_ch01_book_open`（玄符秘录）**：Phase 4 将级联改名，**生产顺序排最后，本阶段未检索/未生产**。
4. **Stinger 兜底**：是否启用 Suno Pro（$10/月，需虚拟卡）待 Phase 5.3 定。
5. **Phase 4「玄符秘录」移除级联**（沿用旧账）：仍涉 D-12（book_open 音频）、D-07 P-14、D-05/D-06 等，待 Phase 4 统一处理。

---

## 四、下一程路线

- **Phase 3.4 端到端冒烟**：串一条最小跨 Agent 链路验证整体协作。例：P1 群下达 → M1 出场景图提示词 → 落共享目录 → M3 配该场景音频候选 → M4 确认能读取素材。
- **Phase 4（故事/文档重做）**：世界观 + 9 章主线定稿；处理「玄符秘录」移除级联等 reconcile；P1/P2/P3 + 人工决策。
- **Phase 5（第一章生产）**：M3 正式按 D-12 产 **BGM×3 / SFX×14 / Stinger×3**——SFX 走 Freesound 搜索+人工下载+ffmpeg 转规格；BGM/Stinger 走 Freesound 分层合成（sox/ffmpeg）。与 M1/M2/M4 并行，逐项人工审批 → 归档提示词/来源至 D-12 §五 → LOCKED。

---

*文档结束 · Phase 3.3 完成 · Phase 3 工具链（出图 + 开发 + 音频）全部就绪 · P0 安全闭环 · 下一程：Phase 3.4 端到端冒烟*
