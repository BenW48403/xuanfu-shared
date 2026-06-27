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

## 飞书发图/发文件

呈报 Ben 终审时，用本脚本把候选图/音/文件直接发进 P1 群（图片内联显示，音视频作附件）。用法：

```
python3 ~/mcp/feishu/feishu_send.py oc_38dec2592fbdd125063d7d15078e913e <文件路径> "<工单号+版本说明>"
```

- 首个参数是 P1 群 chat_id（固定）
- 第二个参数是本地文件的绝对路径
- 第三个参数是附言（可选，如工单号和初验结论）

示例：
```
python3 ~/mcp/feishu/feishu_send.py oc_38dec2592fbdd125063d7d15078e913e ~/xuanfu-shared/art/bg_ch01_hall.png "ART-CH01-001 定稿，7项验收通过，请终审"
```
