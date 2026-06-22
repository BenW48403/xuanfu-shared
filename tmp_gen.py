#!/usr/bin/env python3
import json
import sys
import os
import subprocess

FAL_KEY_FILE = os.path.expanduser("~/.fal_key")
with open(FAL_KEY_FILE) as f:
    FAL_KEY = f.read().strip()

PROMPT = "flat 2D paper-theater illustration, point-and-click escape room game background, hand-drawn cutout style like a flat stage backdrop, strictly head-on eye-level elevation view with NO perspective and NO depth, wall parallel to the camera, a derelict museum security room at night, an old metal desk against a grimy cracked wall, a desk lamp casting dim yellow light, a wall-mounted security monitor bank with flickering static, a wooden locker cabinet, a bulletin board with faded notices, scattered papers on the floor, thick dust, cobwebs, peeling decayed surfaces, desaturated muted palette of grimy grey-green and brown with cinnabar-red accents, dim uneven candlelight, deep flat shadows, quiet oppressive eerie Chinese folk-horror mood, grungy hand-painted texture, storybook horror, NOT photorealistic, NOT 3d render, NO perspective, flat orthographic composition"

body = {
    "prompt": PROMPT,
    "image_size": "landscape_16_9",
    "quality": "high",
    "num_images": 1,
    "output_format": "png"
}

body_json = json.dumps(body, ensure_ascii=False)

print(">>> Calling fal.ai GPT Image 2 ...")

import urllib.request
import urllib.error

req = urllib.request.Request(
    "https://fal.run/openai/gpt-image-2",
    data=body_json.encode('utf-8'),
    headers={
        "Authorization": f"Key {FAL_KEY}",
        "Content-Type": "application/json"
    }
)

try:
    with urllib.request.urlopen(req, timeout=240) as resp:
        resp_body = resp.read().decode('utf-8')
        data = json.loads(resp_body)
except Exception as e:
    print(f"Request failed: {e}")
    sys.exit(1)

print(f"Response keys: {list(data.keys())}")

if "images" in data:
    image_url = data["images"][0]["url"]
    print(f"Image URL: {image_url}")
    
    outpath = "/home/ben/xuanfu-shared/art/bg_ch01_security.png"
    print(f">>> Downloading to {outpath} ...")
    
    req2 = urllib.request.Request(image_url)
    with urllib.request.urlopen(req2, timeout=120) as resp_img:
        img_data = resp_img.read()
        with open(outpath, 'wb') as f:
            f.write(img_data)
    
    size = os.path.getsize(outpath)
    print(f">>> Done: {outpath} ({size} bytes)")
    
    # Mirror to Windows
    win_path = "/mnt/c/Users/Administrator/Desktop/xuanfu/Demo/M1/bg_ch01_security.png"
    try:
        os.makedirs(os.path.dirname(win_path), exist_ok=True)
        import shutil
        shutil.copy2(outpath, win_path)
        print(f"    Mirrored to: {win_path}")
    except Exception as e:
        print(f"    Mirror failed: {e}")

else:
    print(f"No images in response: {data}")
    sys.exit(1)
