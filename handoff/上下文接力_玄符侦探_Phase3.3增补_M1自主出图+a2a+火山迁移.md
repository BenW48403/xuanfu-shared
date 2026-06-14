# 上下文接力 ·《玄符侦探》· Phase 3.3 增补（M1 自主出图 + a2a + 火山模型迁移）

> 接续《上下文接力_玄符侦探_Phase3.3完成_M3音效Agent接入音频工具.md》。
> 本篇记录 Phase 3.3 完成后、Phase 3.4 开始前的一批**基建升级**（不属于某个新阶段，但必须入库，否则新窗口会断线）。
> 提醒：每个 Claude 窗口独立、不跨窗口记忆，**接力文档系列是项目主线**。

---

## 一、M1 自主出图（已打通）

- 把现有 `~/xuanfu-shared/genimage.sh` 包成 **MCP 工具 `generate_image`**，工程在 `~/mcp/genimage/`（Node/ESM，`index.js` + `package.json`）。
- 全局注册：`openclaw mcp set genimage '{"command":"node","args":["/home/ben/mcp/genimage/index.js"]}'`。
- m1-visual 的 SOUL.md 已加能力说明：M1 可调 `generate_image(prompt, filename, model[gpt|flux])` 直接出图。
- fal key 仍由 `genimage.sh` 内部读 `~/.fal_key`（chmod 600），MCP 不碰 key。
- 出图落 `~/xuanfu-shared/art/`，并自动镜像 Windows `C:\Users\Administrator\Desktop\xuanfu\Demo\M1\`。
- 验证：M1 群直接出 `smoke_m1.png`、`bg_ch01_hall.png` 成功。
- ⚠️ 小挂账：`bg_ch01_hall_v2.png` 实测为 1088×1536 **竖图**，但 genimage 默认 `landscape_16_9`——下次确认 size 参数是否真生效。

## 二、Agent 间转发 a2a（已打通）

- `agentToAgent` 原本就 enabled；`sessions_send.visibility = all`。
- allow 列表 + `p1-planner.subagents.allowAgents` 已含 **m1-visual / m3-audio / m4-coder**（按需开放，未全通）。
- 验证：P1 群下「请让 M1 出图」→ P1 经 a2a 派发 → M1 出图 → 回报 P1，闭环成立。
- 注意：a2a 一轮可能耗时数分钟（派发 + 出图 + 审图叠加），P1 慢回属正常，别误判为挂。

## 三、模型迁移 → 火山方舟 Coding Plan（Lite）

**决策背景**：原视觉/审图模型 `zai/glm-5v-turbo` 账户余额耗尽（429），且文本早已切 DeepSeek、未迁视觉。Ben 订阅了火山方舟 **Coding Plan Lite**（豆包/DeepSeek/GLM/Kimi 等，OpenAI+Anthropic 双协议，国内直连、微信/支付宝付）。

| 项 | 值 |
|---|---|
| Provider | `models.providers.volcengine`，baseUrl=`https://ark.cn-beijing.volces.com/api/coding/v3`（OpenAI 兼容，**Coding Plan 端点**） |
| 默认模型 | `volcengine/doubao-seed-2.0-pro`（text+image 多模态、256K、函数调用） |
| 覆盖 agent | p1-planner / m1-visual / m3-audio / m4-coder / main 全部走 doubao |
| 审图 | 网关自动选第一个 text+image 模型 → 现为 doubao（不再 zai/glm-5v，429 已解） |
| Auth | `volcengine:default`，Ark key 存各 agent `auth-profiles.json`（本地、非仓库）；openclaw.json 无明文 secret |
| Claude Code | **未动，继续 DeepSeek**（最吃量，留 DeepSeek 让 Lite 额度只喂 OpenClaw，更稳） |

**⚠️ 端点铁律**：OpenClaw 必须用 `/api/coding/v3`（消耗套餐）；**别用 `/api/v3`**（那是按量付费、不走套餐）。媒体生成（豆包 TTS、Seedream 图）才在 `/api/v3`。

**额度/兜底**：Lite 额度按 5 小时 / 周 / 月 滚动刷新，约 1.8 万次请求/月。跑干时**手动**切 DeepSeek 直连（无现成自动 failover；要全自动需加 router 代理，一人项目暂不必）。

**模型选型备注**：doubao-seed-2.0-pro 当全局默认最省事；如需特化——M4 可用 `glm-5.1`（编程/长程强、但非多模态），M3 工具调用可保留 `deepseek-v4-pro`（已验过 Freesound 调用）。

**验证**：P1 `/status` = doubao ✓；M1 用 doubao 审 `bg_ch01_hall_v2.png`、报真实尺寸+画面内容、无 429 ✓。

## 四、待确认 / 挂账（开 Phase 3.4 前先扫）

1. **M1 保安室测试图未回报**：P1 已派 `bg_ch01_security_test.png`，但出图+自评未见回。疑似延迟。先查 `~/xuanfu-shared/art/` 是否生成 + M1 群/日志。
2. **配音/语音 scope 未定**：D-12 只含 BGM/SFX/Stinger，**无配音**。若做角色配音→归 M3（扩"音效"为"全音频"），火山有 Doubao 语音合成/音色设计（走 `/api/v3` 按量）。**先和 P1/P2 定 scope（纯文本对白 / 全配音 / 折中：氛围人声当 SFX）再建**。
3. **genimage size 参数**：见上 §一 竖图问题。
4. **a2a allow 列表**：目前只开 P1→制作向；后续按需补（如 Q 系列）。

## 五、下一程

- **Phase 3.4 端到端冒烟**（已暂停，下次开）。开工前军师会把 Phase 0→现在所有定案完整梳理一遍，给一份干净总步骤（含 M1 自主出图 + a2a 这些新能力），不用翻历史。
- 当前可用 agent：P1 / M1 / M3 / M4（均 doubao）；Claude Code（DeepSeek，执行手）。

---

*Phase 3.3 增补 · M1 自主出图 ✅ · a2a 互转 ✅ · 全员迁火山 doubao-seed-2.0-pro ✅ · 审图 429 解除 ✅ · 下一程：Phase 3.4*
