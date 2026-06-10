# 上下文接力 ·《玄符侦探》· Phase 3.1 完成（M1 出图管道）

> 本文档接续《上下文接力_玄符侦探_Phase2完成.md》。续上 Phase 2（多 agent 基座完成）之后的 Phase 3.1 进展。
> 用法提醒：每个 Claude 对话相互独立、不跨窗口记忆，**这份接力文档才是项目主线/总线**。新窗口先读它 → 干活 → 更新它。重活（M1/M4 搭建等）开新窗口跑。

---

## 一、本程完成：Phase 3.1 — M1 出图管道（工具层 ✅ 完成）

### 1. 平台与模型决策
- **平台：fal.ai**（付款已由用户解决，有 API key，国内直连可用）。
- **背景出图主力：GPT Image 2**（OpenAI 模型，已上架 fal）。
  - fal 模型 id：`openai/gpt-image-2`（文生图）；`openai/gpt-image-2/edit`（图像编辑/图生图）。
  - 同步端点：`POST https://fal.run/openai/gpt-image-2`（实测直接返回，无需队列轮询）。
  - 参数：`prompt` / `image_size`（如 `landscape_16_9`）/ `quality`（low/medium/high）/ `num_images` / `output_format`。
  - 计费：$0.01（低质量）~ $0.41（4K 高质量）每张。迭代用 medium、定稿用 high。
  - 优点：质量高、**中文渲染准确**、跟提示词紧、可商用。
- **内容兜底/快速草图：Flux schnell**（`fal-ai/flux/schnell`）。Apache 2.0 可商用、快且便宜、`enable_safety_checker:false` 可关安全检查 → 内容最自由。
- **不要直接接 OpenAI 官方 API**：要过组织验证 + 国区封锁（`api.openai.com` 国内直连不通）+ 另套付款。既然 fal 上有 GPT Image 2，全绕开。
- **国内文生图 API（通义万相等）不作恐怖题材主力**：强制内容审核（prompt+出图都审，违规报错），鬼怪/灵异画面易被拦。

### 2. 出图脚本 genimage.sh
- 路径：`~/xuanfu-shared/genimage.sh`
- 用法：`genimage.sh "<prompt>" "<文件名.png>" [gpt]`
  - 第三参数 `gpt` = 走 GPT Image 2；省略 = 默认 Flux schnell。
- key：从 `~/.fal_key` 读（chmod 600，明文绝不进对话/指令）。
- 输出：存 `~/xuanfu-shared/art/`，并**自动镜像复制**到 Windows 桌面 `C:\Users\Administrator\Desktop\xuanfu\Demo\M1\`（WSL 路径 `/mnt/c/Users/Administrator/Desktop/xuanfu/Demo/M1/`）。
  - 原因：`\\wsl$\Ubuntu\...` 在资源管理器常打不开，改用 `/mnt/c` 正向镜像更稳。

### 3. 中文文字处理（已定方案）
- Flux：中文乱码（扩散模型通病）。GPT Image 2：中文基本准确、可读。
- **分工**：装饰性背景文字（匾额/对联）可让 GPT 烤进图；**玩家要精确读的文字（线索/UI）走引擎文字层**，保证清晰、可改、可本地化。
- 备选：Qwen-Image（fal 上，中文最强、也能编辑改字）。

---

## 二、画风方向（初步 · 待 Phase 5 与 M1 落定）

### 目标画风
- **扁平正视"纸片剧场"**（对标《Forgotten Hill: Surgery》"Grotesque Paper-Theater" / 2D cutout）+ **中式恐怖**。
- 手绘做旧、不写实/不电影感/无透视纵深；灰脏冷调（脏奶白/青绿/棕）+ **朱砂红**做唯一签名点缀。
- 氛围词（用户敲定）：破败、旧、老、灰尘、不稳定（灯一闪一闪）、散乱、蛛网、剥落。
- 内核：**熟悉的民俗物件被轻微扭曲**生诡异，留白克制，不靠血腥/jump scare。
- 中式母题（替换日式）：青砖墙、木格窗、八仙桌、太师椅、供桌香炉、黄符朱砂、白幡纸扎、铜锁、算盘、老座钟、对联、油灯烛火、老宅/祠堂/事务所。

### 已达标样板图
- `ch1-ritual-gpt-01.png`（第一章·祭祀陈列室；GPT Image 2 + 下方 prompt 出图）——扁平、手绘做旧、中文正确（慎終追遠 / 歷代宗親之位 / 对联 / 福 / 八卦）、中式恐怖氛围到位、未被审核拒。

### 草稿 prompt 模板（恒定风格句 + 每场景换内容句）
```
flat 2D paper-theater illustration, point-and-click escape room game background, hand-drawn cutout style like a flat stage backdrop, strictly head-on eye-level elevation view with NO perspective and NO depth, wall parallel to the camera, [本场景内容：房间+物件], thick dust, cobwebs, peeling decayed surfaces, desaturated muted palette of grimy grey-green and brown with cinnabar-red accents, dim uneven candlelight, deep flat shadows, quiet oppressive eerie Chinese folk-horror mood, grungy hand-painted texture, storybook horror, NOT photorealistic, NOT 3d render, NO perspective, flat orthographic composition
```

---

## 三、⭐ 关键设计结论（决定 Phase 5 的生产方法）

> 这是本程最重要的认知，务必带到第一章生产。

1. **本作可交互道具"无热点高亮"**（用户明确的玩法设定）→ 道具必须"看得见但不送分"，且要按 D-07 谜题设计**精确摆在指定位置**。
2. **纯文生图给的是"长相"，给不了"受控构图"**——模型自动构图满足不了"哪个道具必须在哪 + 不高亮还得能被找到"。
3. **所以构图必须人工编排，不能交给模型自动生成整张成品场景。** 这也是为什么"单看很漂亮的整图"离项目要的成品还差一截。
4. **生产方法（Phase 5 落定）= "AI 出零件 + 人工拼装"**：
   - GPT Image 2 出**背景板**（墙、固定陈设、氛围，装饰性中文可烤进）；
   - 可交互**道具单独出贴片**（GPT 或 Flux）；
   - 在 **Cocos**（成品，每个可交互物=一个 sprite 节点）/ **Photopea**（免费，美术合成）里**人工拼装、按谜题定位摆放**；
   - 做旧/光影/可读中文作为**叠加图层**后期加。
   - 这也与引擎天然契合（交互物本就是独立 sprite；整图烤死反而难做交互）。
5. **精确构图的技术手段**：布局约束生成（GPT `…/edit` 图生图、Flux ControlNet）或 零件+拼装。
6. **三个轴别混淆**：
   - 锁画风（统一长相）= prompt 模板 + 参考图；
   - seed（复现/微调某一张具体图）= 同 prompt+同 seed→同图，GPT Image 支持；
   - 构图控制（指定摆放）= 布局约束 或 零件拼装。
   - GPT Image 2 是**闭源、不能训自定义 LoRA**；Demo 靠 prompt 模板 + 参考图 + `/edit` 保持一致即可，**LoRA 是 Flux 路线才需要的**，Demo 先不碰。

---

## 四、Phase 3.1 状态判定
- **工具层：完成 ✅**。M1 具备可用且已验证的出图能力；平台/模型/付款/内容/中文全部解决；最大未知（AI 能否出我们要的画风+中文、在付款已解决的平台上）已排除。
- **画风 + 构图方法的最终锁定：留到 Phase 5（第一章生产）与 M1 一起、对着真实谜题布局和"无高亮可发现性"落定**。现在在抽象层面锁死过早（这正是样板图"好看但还不像成品"的原因）。

---

## 五、Agent 团队补记（本程澄清）

### 10-Agent 名册（三段式）
- **策划（串行）**：P1 总策划 · P2 叙事 · P3 谜题设计
- **制作（并行）**：M1 视觉 · **M2 界面/UI 设计（对应 D-11 UI视觉规范）** · M3 音效 · M4 开发
- **质检（串行）**：Q1 · Q2 · Q3 本地化

### 现状
- 已实例化进 OpenClaw 的只有 **P1、M1、M4**（验证"计划→出图→代码"核心环）。
- **M2（UI）、M3（音效）、P2/P3、Q1-3 尚未建进 OpenClaw**，设计已就绪，核心环跑通后按需补。
- UI/UX 不缺位：= M2 出视觉设计（D-11）+ M4/Claude Code 在 Cocos 实现。

### 代码分工结论（重要）
- **M4 不是"写代码的"**：真正改文件/跑命令的是 **Claude Code**；M4（OpenClaw）只是"开发负责人"人格（接 P1 任务→转 Claude Code→守规范→回报）。
- **代码的角色细分（架构/实现/验收）放在 Claude Code 内部、用其 subagent 编排**——代码 = 共享文件 + 真执行，是 Claude Code 主场。
- **不要在 OpenClaw 里养一堆代码 agent**：各自独立 DeepSeek 会话、不共享代码库、交接脆，隔着聊天框协调代码慢且易错。
- **Demo 保持精简**：一个 M4 + Claude Code（带 Superpowers/ECC/subagent）足够；别在没代码库前先搭代码组。将来扩展也是在 Claude Code 内部加子角色。
- 边界：**OpenClaw 管协调/规范/人格；Claude Code 管真正工程（及工程内部角色细分）。**

---

## 六、下一步 / 待办（接续，按优先级）

1. **把初步画风方向 + 样板图 + prompt 模板写入 D-10 / M1 的 TOOLS.md**（作为 Phase 5 起点，标注"初步、待生产时与 M1 最终锁定"）。
2. **Phase 3.2：M4 开发环境**（Cocos 工程脚手架）。⚠ 注意 **D-15 硬编码 `tt.*` 与 D-13 PlatformAdapter 零耦合冲突**（P1 待解，Phase 5.1 前必须 reconcile）。
3. **按需实例化剩余 agent**：优先 M2（UI）、M3（音效）。
4. （Phase 5）落定"AI 出零件 + 人工拼装"生产流程 + 交互道具贴片工作流 + Cocos 合成。

### 保留的旧待办（来自 Phase 2 文档）
- **[P0 安全] ✅ 已完成（2026-06-14）**：飞书 App Secret 已轮换、DeepSeek key 已轮换、旧 GLM key 已吊销。
- **监控群（📋监控·日志 `<监控群_chat_id：见本地 openclaw.json bindings>`）实时推送**：agent 不能往非绑定群发消息 → 需 Feishu 自定义机器人 webhook + 小中继（option B，待做）。
- **[P1] Phase 4 玄符秘录-移除级联** 漏改：D-12（sting_ch01_book_open 音频）、D-07 P-14、D-05/D-06 禁区。
- **[P2] Feishu 配额复核**（~43,200/月 vs 50,000 上限）；**D-01 版本号**（文件名 v1.2 vs 正文 v1.0）。

---

## 七、关键路径 / 文件速查
- key：`~/.fal_key`（chmod 600）
- 共享目录：`~/xuanfu-shared/`（`genimage.sh` / `art/` / `docs/` / `code/` / `handoff/` + `handoff/coordination-log.md`）
- Windows 镜像：`C:\Users\Administrator\Desktop\xuanfu\Demo\M1\`（= WSL `/mnt/c/Users/Administrator/Desktop/xuanfu/Demo/M1/`）
- chat_ids / OpenClaw 配置 / agent-comms 发现：见《上下文接力_玄符侦探_Phase2完成.md》
- 环境：Windows 11 + WSL2（Ubuntu 24.04，用户 ben）；OpenClaw gateway = systemd 用户服务；模型全走 DeepSeek（国内直连，仅 GitHub 需镜像）。

---

*文档结束 · Phase 3.1 完成 · 下一程：Phase 3.2（M4 开发环境）/ 把画风初稿写入 D-10*
