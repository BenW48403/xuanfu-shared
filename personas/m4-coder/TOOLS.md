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

## Related

- [Agent workspace](/concepts/agent-workspace)

## 交付回报 P1

代码功能跑通后：
1. 自评（对照工单验收标准）
2. 回报 P1，含：工单号 + 产出文件路径 + 自评结果

**不往 P1 群发预览**——呈报 Ben 终审由 P1 统一发。如需在自己群（M4 群）留预览自查，可执行：
```
python3 ~/mcp/feishu/feishu_send.py oc_d25063c7ecf3e2e64a47b449a856d85d <截图/文件路径> "<自评>"
```
