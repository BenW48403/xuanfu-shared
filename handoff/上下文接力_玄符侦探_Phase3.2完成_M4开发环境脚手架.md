# 上下文接力 ·《玄符侦探》· Phase 3.2 完成（M4 开发环境 / Cocos 脚手架）

> 接续《上下文接力_玄符侦探_Phase3.1完成_M1出图管道.md》。
> 至此 **Phase 3 核心工具完成**：M1 美术出图管道（3.1）+ M4 开发环境与工程脚手架（3.2）。
> 提醒：每个 Claude 对话独立、不跨窗口记忆，**接力文档系列是项目主线**。

---

## 一、Phase 3.2 完成内容

### 1. 环境与工程
- **Cocos Creator 3.8.8**（Windows）已安装；用 Cocos Dashboard 管理。
- 工程路径：`C:\Users\Administrator\Desktop\xuanfu\game`（WSL 侧 `/mnt/c/Users/Administrator/Desktop/xuanfu/game`），2D 空模板。
- 安装时**跳过了 Visual Studio 2022**（仅原生编译需要；小游戏/H5 走 JS/WebGL，用不到）。

### 2. WSL / Windows 分工（重要）
- **Cocos 编辑器 = Windows GUI**：建场景、挂组件、拖引用、导素材、Build/预览——**由人操作**。
- **Claude Code = WSL**：经 `/mnt/c` 改 TypeScript 代码 + git——**不碰编辑器、不执行构建**。
- M4（OpenClaw）= "开发负责人"人格：接 P1 任务→转 Claude Code→回报；代码角色细分用 Claude Code 内部 subagent，不在 OpenClaw 养代码 agent。

### 3. 脚手架（`assets/scripts/`，9 个 .ts，全是骨架/桩 + TODO）
- `platform/`
  - `IPlatformAdapter.ts` — 平台能力接口（save/load/showRewardedAd/login/share…）
  - `WebPlatformAdapter.ts` — H5/Web 默认实现（localStorage）
  - `DouyinPlatformAdapter.ts` — 抖音实现【桩】，**`tt.*` 只允许出现在此文件**（当前 TODO）
  - `PlatformManager.ts` — 运行时选 adapter 的单例
- `core/`
  - `SceneController.ts` — 场景背景切换骨架
  - `Interactable.ts` — 可交互热点基类，**无热点高亮** + 预留 `onDiscover()` 软发现回调（音效/微动）
  - `InventoryManager.ts` — 道具栏桩
  - `SaveManager.ts` — 存档桩，**经 `PlatformManager.adapter` 存取，绝不直接碰平台 API**
- `HelloXuanfu.ts` — 验证组件

### 4. 架构铁律（已落实）
- **平台零耦合**：游戏逻辑只依赖 `IPlatformAdapter`，永不直接写 `tt.*` / `wx.*`；`tt.*` 被隔离在 `DouyinPlatformAdapter` 一个文件。
- 全部骨架/桩，每个方法标注 Phase 5 填充方向。

### 5. Git
- `git init` + 首次提交 **d0120ee**（master 分支，working tree clean）。
- 身份：`user.name = BenW48403`，`user.email = benw48403@gmail.com`（真实 GitHub 账号，便于日后推送）。
- `.gitignore` 完善（忽略 `library/ temp/ local/ build/ profiles/ node_modules/ .vscode/ .idea/`）。

### 6. 验证通过 ✅
- hello 场景运行：浏览器显示「**玄符侦探 · 骨架已就绪**」。
- 控制台：`[HelloXuanfu] …`（HelloXuanfu.ts）+ `[PlatformManager] → WebPlatformAdapter`（确认平台层正常初始化、选中 Web 适配器、无报错）。
- 结论：**Claude Code 写 TS → 编辑器编译 → 浏览器运行**整条工具链跑通。

---

## 二、Cocos 编辑器操作备忘（给操作者）
- **Label** 在 `Create → 2D Object`（不是 UI Component）；Canvas / Button 等在 `UI Component`。
- Label 等 UI 节点要放在 **Canvas 子节点**下才正常显示。
- Claude Code 在 `/mnt/c` 写好新脚本后，**编辑器获得焦点会自动导入、生成 `.meta`**。
- 挂脚本：选中节点 → Inspector → `Add Component` → 搜脚本名；引用属性靠从 Hierarchy **拖节点**进属性框。
- 运行：顶部工具栏 ▶（Play），默认浏览器预览。

---

## 三、⚠ 关键待办 / 阻塞项（按优先级）

1. **[阻塞] 设计文档 D-01~D-17 不在 `~/xuanfu-shared/docs/`（目录为空）** —— Claude Code 这次找不到 D-13/14/15、只能用基线命名。**Phase 4/5 之前必须把这些 .docx 放进 `docs/`**，并对照 D-13（技术）/D-14（数据）/D-15（功能）reconcile 脚手架的命名与结构。
2. **[P1] D-15 v1.0 硬编码 `tt.*` 与 D-13 零耦合冲突** —— 脚手架已按 D-13 正确建；需 P1 改 D-15 对齐（文档级修正）。
3. **[P0 安全] ✅ 已完成（2026-06-14）**：飞书 App Secret 已轮换、DeepSeek key 已轮换、旧 GLM key 已吊销。
4. **[P1] Phase 4「玄符秘录」移除级联**漏改：D-12（sting_ch01_book_open 音频）、D-07 P-14、D-05/D-06 禁区。
5. 监控群 webhook 实时推送；D-01 版本号（文件名 v1.2 vs 正文 v1.0）；Feishu 配额复核。
6. D-10 v1.2 画风初稿已产出（待你人工审批 / 并入 D-10 体系）。

---

## 四、下一程路线
- **第 0 步（先做、快、解阻塞）**：把 D-01~D-17 放进 `~/xuanfu-shared/docs/`。
- **Phase 4（故事/文档重做）**：世界观 + 9 章主线定稿；处理上面 #2 #4 等 reconcile；P1/P2/P3 + 人工决策。
- **Phase 5（第一章生产）**：用锁定的美术管道 + 开发脚手架 + 定稿文档，正式做第一章（10 场景、34 热点）。
- **Phase 6**：复制流程做第 2~9 章。

---

*文档结束 · Phase 3.2 完成 · Phase 3 核心工具（美术 + 开发环境）就绪 · 下一程：D-docs 入库 → Phase 4*
