# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

## Image Generation (fal.ai)

genimage.sh **detached 模式**（前台毫秒返回，不会被 SIGKILL）：

```bash
# 步骤1: 派活（瞬间返回）
~/xuanfu-shared/genimage.sh "<D-10 prompt>" <章号> <基名> [版本] gpt
# → QUEUED: /path/to/output.png.done

# 步骤2: 轮询等结果（每5s查标记文件）
while true; do
  test -f /path/to/output.png.done && cat /path/to/output.png.done && break
  test -f /path/to/output.png.failed && cat /path/to/output.png.failed && break
  sleep 5
done
```

- Model: **GPT Image 2** (gpt)，不用 flux
- 强制落点 `art/ch<章>/_wip/<base>_vN.png`
- 自动镜像 Windows 桌面预览区
- 直接 shell 调试用 `--sync` 阻塞模式

**D-10 style lock**: 换场景只改内容词，不碰风格参数。模板：

```
"Chinese horror, <scene description>, ink-wash atmosphere, desaturated, cinematic"
```

## Related

- [Agent workspace](/concepts/agent-workspace)

## 交付回报 P1

出图草稿完成后：
1. 自评（对照工单验收标准逐条检查）
2. 回报 P1，含：工单号 + 草稿文件绝对路径 + 自评结果

**不往 P1 群发预览**——呈报 Ben 终审由 P1 统一发。如需在自己群（M1 群）留预览自查，可执行：
```
python3 ~/mcp/feishu/feishu_send.py oc_d06fbfe6d927a59ee734b907204b1760 <图片路径> "<自评>"
```
