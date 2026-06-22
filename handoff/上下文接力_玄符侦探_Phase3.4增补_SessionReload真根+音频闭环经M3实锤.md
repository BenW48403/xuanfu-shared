# 上下文接力 · 玄符侦探 · Phase 3.4 增补

**主题**：Session Reload 完整机制（真根更正）+ 音频闭环经 M3 实锤

> ⚠️ 本增补**更正** Phase3.4 主文档「reload 节」——主文档的 reload 说明不完整、会失效，以本增补为准。

---

## 一、最关键更正：Session Reload 的完整三层（缺一不可）

主文档只写了"轮换 sessionId"，**不够**。完整机制是三层：

1. **`gateway restart` ≠ session reset** —— 重启不清 session（session 持久化在 `~/.openclaw/agents/<id>/sessions/`）。
2. **轮换 `sessions.json` 的 sessionId** —— 必要但**不充分**。
3. **归档旧 `.jsonl`（最初遗漏、真正的根）** —— 网关按 key 发现残留的旧 `.jsonl` 就会**复用旧 session、不建新的** → SOUL 永不刷新。必须把旧 `.jsonl` 改名归档（`.archived.<uuid>`），网关才会真正新建 session、重编译 SOUL。

`~/openclaw-reload.sh` 已更新为：**轮换 sessionId + 归档旧 `.jsonl` + gateway restart**。改完任何 SOUL/TOOLS：
```
~/openclaw-reload.sh <agent...>     # 轮换 + 归档 + 重启
# 然后在对应渠道发一条消息，触发新 session 编译
```

### 血泪教训
- 此前多轮"reload"对活 session **全是空操作**（只轮换没归档），导致 P1 的禁 bypass 铁律**从未进过活 session**——P1 一路"绕过 M 系自己出产物"**不是抗命，是规则根本没加载**。
- **CLI dump 验证会误导**：`openclaw agent --session-key` 开的是 CLI 临时 session、总加载新 SOUL，但飞书活 channel session 仍复用旧 JSONL。**验证要看活 session 的实际行为（是否真新建了 sessionId、是否真派给了 M 系），不能只看 CLI dump。**

---

## 二、音频闭环经 M3 实锤（AUD-CH01-003）

修对 reload 后，音频闭环首次真·走通 M3：

> P1 派 M3（a2a）→ M3 新建 session → Freesound 取 CC0 → ffmpeg 转码 → 落 `audio/ch01/_wip/sfx_ch01_chain_v1.wav`（带 `_v1`）→ 回报 P1 → P1 初验（格式/授权）→ 发可播预览进 P1 群 → Ben 终审 → P1 `cp` 升格 `audio/ch01/sfx_ch01_chain.wav` + commit/push + log。

同一个 reload 开关的 A/B 对照：
| 工单 | 谁出 | 走 M3 | _wip/_vN |
|---|---|---|---|
| AUD-001 木门 | P1 直接 ffmpeg（reload 未生效）| ❌ | ❌ |
| AUD-002 符咒 | P1 直接 ffmpeg（reload 未生效）| ❌ | ❌ |
| **AUD-003 链条** | **M3 经 a2a（reload 生效后）** | **✅** | **✅** |

**结论**：音频走与图片完全一致的制片 SOP（生成/_vN/初验/呈报/终审/升格），经 M3 验通。

---

## 三、强化的铁律（已写入 P1 SOUL）

- **「出图/出音频铁律（你不出产物）」**：P1 只调度/验收/呈报，**禁止 curl / Python / ffmpeg 兜底**替 M 系出产物；M 失败直接回报 Ben + 原因，**不许绕过**。
- **作废 / DONE 属闭合终态**，不列入"未闭合工单"。

---

## 四、当前 ch01 资产

- **图（定稿）**：`bg_ch01_hall`、`bg_ch01_storage`。
- **音（定稿）**：`sfx_ch01_door`（001，P1 绕过产、有效已批）、`sfx_ch01_talisman_burn`（002，同）、`sfx_ch01_chain`（003，M3 干净产）。
- **D-12 音频还差**：SFX 11 条、BGM 3、Stinger 3。
- 002/003/004 场景图仍作废暂存（等文案）。

---

## 五、下一步候选

1. **验一条 BGM**：BGM 是 Freesound **分层合成**（D1=B），比单条 SFX 复杂，先用本 SOP 跑通一条 BGM 再批量。
2. **批量产 D-12 剩余音频**（SFX/BGM/Stinger）。
3. **场景图**等文案定稿。
4. **音频生产级原文件**（Freesound OAuth2 替代预览档）另开一轮。

---

*接力锚点：reload 务必走完整三层（含归档 .jsonl）；验证看活 session 行为不看 CLI dump；图/音同一套制片 SOP。*

## 六、新增决定（音频范围 + 合规）

1. **BGM 手做、不走 Agent**：BGM 量小（D-12 仅 3 条）、是定调的"主角资产"（氛围/循环/器乐凭品味），决定**人工制作**（走 Suno Pro 或正版曲库，商用授权清晰），不走 Agent 流水线。Agent 流水线专注高量重复资产（如 14 条 SFX）。
   > 注：BGM 经 M3 的闭环能力已验通（AUD-004），保留作产品化能力；本游戏自身 3 条 BGM 走人工。

2. **CC-BY 署名 = 开放项（park，后续解）**：当前批量音频暂缓、无 Agent 在产音频，故无合规债累积。后续解法方向——**Agent 流水线强制只用 CC0 素材（免署名）+ BGM 人工走正版商用授权**，如此署名追踪问题可直接消解，无需另建追踪系统。**恢复批量音频生产前必须先落实此项。**
