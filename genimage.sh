#!/usr/bin/env bash
set -euo pipefail

# genimage.sh — Generate an image via fal.ai
# Usage: genimage.sh "<prompt>" "<output_filename.png>" [flux|gpt]
#   flux (default): fal-ai/flux/schnell (fast, cheap)
#   gpt:            openai/gpt-image-2 (high quality, good typography)

FAL_KEY_FILE="$HOME/.fal_key"
ART_DIR="$HOME/xuanfu-shared/art"
WIN_DIR="/mnt/c/Users/Administrator/Desktop/xuanfu/Demo/M1"

die() { echo "ERROR: $*" >&2; exit 1; }

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    die "Usage: genimage.sh \"<prompt>\" \"<output_filename.png>\" [flux|gpt]"
fi

PROMPT="$1"
OUTFILE="$2"
MODEL="${3:-flux}"

# Read and trim the key
if [ ! -f "$FAL_KEY_FILE" ]; then
    die "Key file not found: $FAL_KEY_FILE"
fi
FAL_KEY="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$FAL_KEY_FILE")"
if [ -z "$FAL_KEY" ]; then
    die "Key file is empty: $FAL_KEY_FILE"
fi

ART_SUBDIR=$(dirname "$OUTFILE")
mkdir -p "$ART_DIR/$ART_SUBDIR"
OUTPATH="$ART_DIR/$OUTFILE"

# --- Model-specific settings ---
case "$MODEL" in
    flux)
        FAL_ENDPOINT="https://fal.run/fal-ai/flux/schnell"
        MODEL_LABEL="flux/schnell"
        BODY=$(python3 -c '
import json, sys
body = {
    "prompt": sys.argv[1],
    "image_size": "landscape_16_9",
    "num_inference_steps": 4,
    "num_images": 1,
    "enable_safety_checker": False
}
print(json.dumps(body, ensure_ascii=False))
' "$PROMPT")
        ;;
    gpt)
        FAL_ENDPOINT="https://fal.run/openai/gpt-image-2"
        MODEL_LABEL="GPT Image 2"
        BODY=$(python3 -c '
import json, sys
body = {
    "prompt": sys.argv[1],
    "image_size": "landscape_16_9",
    "quality": "high",
    "num_images": 1,
    "output_format": "png"
}
print(json.dumps(body, ensure_ascii=False))
' "$PROMPT")
        ;;
    *)
        die "Unknown model: $MODEL (use flux or gpt)"
        ;;
esac

echo ">>> Calling fal.ai ${MODEL_LABEL} ..."
echo "    prompt: ${PROMPT:0:80}..."

# --- Retry wrapper for fal.ai submit ---
call_fal() {
    local attempt=0 max_attempts=2
    local timeout_s=240
    while [ "$attempt" -lt "$max_attempts" ]; do
        attempt=$((attempt + 1))
        echo "    [attempt $attempt/$max_attempts] POST ${FAL_ENDPOINT}"
        RESP=$(curl -s --max-time "$timeout_s" -w "\n%{http_code}" \
            -X POST "$FAL_ENDPOINT" \
            -H "Authorization: Key ${FAL_KEY}" \
            -H "Content-Type: application/json" \
            -d "$BODY" 2>&1) && break
        echo "    curl failed (timeout after ${timeout_s}s or connection error)"
        if [ "$attempt" -lt "$max_attempts" ]; then
            echo "    retrying in 5s..."
            sleep 5
        fi
    done
    echo "$RESP"
}

RESP=$(call_fal)
# Split status code from body
HTTP_CODE=$(echo "$RESP" | tail -1)
BODY_TEXT=$(echo "$RESP" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
    echo ""
    echo ">>> fal.ai returned HTTP $HTTP_CODE"
    echo "$BODY_TEXT"
    exit 1
fi

# Check if response has images directly, or if it's a queue response
HAS_IMAGES=$(python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
print("yes" if "images" in data else "no")
' <<< "$BODY_TEXT")

if [ "$HAS_IMAGES" = "no" ]; then
    # Queue mode — get status_url and poll
    STATUS_URL=$(python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
print(data.get("status_url", ""))
' <<< "$BODY_TEXT")

    if [ -z "$STATUS_URL" ]; then
        die "no images and no status_url in response: $BODY_TEXT"
    fi

    echo ">>> Queued, polling status..."

    MAX_POLLS=60
    POLL_COUNT=0
    while [ "$POLL_COUNT" -lt "$MAX_POLLS" ]; do
        sleep 5
        POLL_COUNT=$((POLL_COUNT + 1))

        STATUS_RESP=$(curl -s --max-time 30 -w "\n%{http_code}" \
            "$STATUS_URL" \
            -H "Authorization: Key ${FAL_KEY}" 2>&1)
        STATUS_CODE=$(echo "$STATUS_RESP" | tail -1)
        STATUS_BODY=$(echo "$STATUS_RESP" | sed '$d')

        if [ "$STATUS_CODE" != "200" ]; then
            echo "    [poll $POLL_COUNT] HTTP $STATUS_CODE, retrying..."
            continue
        fi

        REQ_STATUS=$(python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
print(data.get("status", "unknown"))
' <<< "$STATUS_BODY")

        echo "    [poll $POLL_COUNT] status: $REQ_STATUS"

        case "$REQ_STATUS" in
            COMPLETED)
                BODY_TEXT="$STATUS_BODY"
                break
                ;;
            FAILED|CANCELLED)
                die "Request $REQ_STATUS: $STATUS_BODY"
                ;;
        esac
    done

    if [ "$POLL_COUNT" -ge "$MAX_POLLS" ]; then
        die "timed out waiting for image after ${MAX_POLLS} polls"
    fi
fi

# Extract image URL (same structure for both models: images[0].url)
IMAGE_URL=$(python3 -c '
import json, sys
try:
    data = json.loads(sys.stdin.read())
    url = data["images"][0]["url"]
    print(url)
except (KeyError, IndexError, json.JSONDecodeError) as e:
    print("", end="")
    print(f"ERROR parsing response: {e}", file=sys.stderr)
    sys.exit(1)
' <<< "$BODY_TEXT") || die "failed to extract image URL from response"

if [ -z "$IMAGE_URL" ]; then
    die "no image URL in fal response"
fi

echo "    image URL: $IMAGE_URL"

# Download with retry
echo ">>> Downloading to $OUTPATH ..."
DL_OK=0
for i in 1 2; do
    echo "    [download attempt $i/2]"
    if curl -s --max-time 120 -o "$OUTPATH" "$IMAGE_URL" 2>/dev/null; then
        if [ -f "$OUTPATH" ] && [ -s "$OUTPATH" ]; then
            DL_OK=1
            break
        fi
    fi
    echo "    download failed, retrying in 3s..."
    sleep 3
done
if [ "$DL_OK" -ne 1 ]; then
    die "failed to download image from $IMAGE_URL (2 attempts)"
fi

SIZE=$(stat -c%s "$OUTPATH" 2>/dev/null || stat -f%z "$OUTPATH" 2>/dev/null || echo "unknown")
echo ">>> Done. Art:     $OUTPATH (${SIZE} bytes)"

# Mirror to Windows-accessible directory (best-effort)
OUTBASE=$(basename "$OUTFILE")
if mkdir -p "$WIN_DIR" && cp "$OUTPATH" "$WIN_DIR/$OUTBASE" 2>/dev/null; then
    echo "    Mirror:  $WIN_DIR/$OUTBASE"
    echo "    Windows: C:\\Users\\Administrator\\Desktop\\xuanfu\\Demo\\M1\\$OUTBASE"
else
    echo "    [WARN] Could not mirror to $WIN_DIR (drive not mounted?)"
fi

echo "    Image URL: $IMAGE_URL"
