#!/usr/bin/env bash
# genimage.sh — Generate an image via fal.ai, enforce _wip/_vN naming
# Usage:
#   genimage.sh "<prompt>" <chapter> <base_name> [version] [model]
#     → detached (default): returns QUEUED marker instantly; agent polls .done/.failed
#   genimage.sh --sync "<prompt>" <chapter> <base_name> [version] [model]
#     → synchronous: blocks until done (for direct shell use)
# Output: art/ch<chapter>/_wip/<base>_v<version>.png

set -euo pipefail
shopt -s extglob

FAL_KEY_FILE="$HOME/.fal_key"
ART_DIR="$HOME/xuanfu-shared/art"
WIN_DIR="/mnt/c/Users/Administrator/Desktop/xuanfu/Demo/M1"

die() { echo "ERROR: $*" >&2; exit 1; }

# --- Detach: re-invoke self in background ---
if [ "${1:-}" = "--sync" ]; then
    shift
else
    # Detached mode: validate args enough to build marker path, then fork
    if [ $# -lt 3 ]; then
        die "Usage: genimage.sh \"<prompt>\" <chapter> <base_name> [version] [model]"
    fi
    CHAPTER="${2}"
    BASE="${3}"
    VERSION="${4:-}"
    if ! [[ "$CHAPTER" =~ ^[0-9]{2}$ ]]; then
        die "chapter must be two digits (e.g. 01)"
    fi
    if [[ "$BASE" =~ \. ]]; then
        die "base_name must NOT include extension"
    fi
    # Auto-version if needed (for marker path construction)
    if [ -z "$VERSION" ]; then
        WIP_DIR="$ART_DIR/ch$CHAPTER/_wip"
        mkdir -p "$WIP_DIR"
        HIGHEST=$(find "$WIP_DIR" -maxdepth 1 -name "${BASE}_v*.png" -type f 2>/dev/null | \
            sed "s/.*_v//;s/\.png//" | sort -n | tail -1)
        VERSION=${HIGHEST:-0}
        VERSION=$((VERSION + 1))
    fi
    OUTFILE="ch${CHAPTER}/_wip/${BASE}_v${VERSION}.png"
    OUTPATH="$ART_DIR/$OUTFILE"
    DONE_FILE="${OUTPATH}.done"
    FAIL_FILE="${OUTPATH}.failed"
    LOCK_FILE="${OUTPATH}.lock"

    # Clean stale markers from previous run
    rm -f "$DONE_FILE" "$FAIL_FILE" 2>/dev/null

    # Fork background worker, disown from agent's exec timeout
    nohup bash "$0" --sync "$@" > /dev/null 2>&1 &
    BG_PID=$!
    disown "$BG_PID" 2>/dev/null || true

    echo "QUEUED: ${DONE_FILE}"
    echo "BG_PID: ${BG_PID}"
    echo "OUTPUT: ${OUTPATH}"
    echo "POLL:   test -f ${DONE_FILE} && cat ${DONE_FILE}"
    echo "FAIL:   test -f ${FAIL_FILE} && cat ${FAIL_FILE}"
    exit 0
fi

# ============================================================
# Below: synchronous mode (--sync) — actual work happens here
# ============================================================

if [ $# -lt 3 ] || [ $# -gt 5 ]; then
    die "Usage: genimage.sh --sync \"<prompt>\" <chapter> <base_name> [version] [model]"
fi

PROMPT="$1"
CHAPTER="$2"
BASE="$3"
VERSION="${4:-}"
MODEL="${5:-gpt}"

if ! [[ "$CHAPTER" =~ ^[0-9]{2}$ ]]; then
    die "chapter must be two digits (e.g. 01, 02), got: $CHAPTER"
fi

if [[ "$BASE" =~ \. ]]; then
    die "base_name must NOT include extension, got: $BASE"
fi

if [ -z "$VERSION" ]; then
    WIP_DIR="$ART_DIR/ch$CHAPTER/_wip"
    mkdir -p "$WIP_DIR"
    HIGHEST=$(find "$WIP_DIR" -maxdepth 1 -name "${BASE}_v*.png" -type f 2>/dev/null | \
        sed "s/.*_v//;s/\.png//" | sort -n | tail -1)
    if [ -z "$HIGHEST" ]; then
        VERSION=1
    else
        VERSION=$((HIGHEST + 1))
    fi
    echo ">>> Auto version: v${VERSION} (highest existing: ${HIGHEST:-none})"
fi

if ! [[ "$VERSION" =~ ^[0-9]+$ ]]; then
    die "version must be an integer, got: $VERSION"
fi

OUTFILE="ch${CHAPTER}/_wip/${BASE}_v${VERSION}.png"
OUTPATH="$ART_DIR/$OUTFILE"
DONE_FILE="${OUTPATH}.done"
FAIL_FILE="${OUTPATH}.failed"
ART_SUBDIR=$(dirname "$OUTFILE")
mkdir -p "$ART_DIR/$ART_SUBDIR"

# Trap errors to write .failed marker
trap 'echo "genimage failed at step: $BASH_COMMAND" >&2; echo "FAILED: $BASH_COMMAND" > "$FAIL_FILE"' ERR

echo ">>> Output: art/$OUTFILE" >&2

if [ ! -f "$FAL_KEY_FILE" ]; then
    echo "Key file not found: $FAL_KEY_FILE" > "$FAIL_FILE"
    exit 1
fi
FAL_KEY="$(sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$FAL_KEY_FILE")"
if [ -z "$FAL_KEY" ]; then
    echo "Key file is empty: $FAL_KEY_FILE" > "$FAIL_FILE"
    exit 1
fi

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
        echo "Unknown model: $MODEL (use gpt or flux)" > "$FAIL_FILE"
        exit 1
        ;;
esac

echo ">>> Calling fal.ai ${MODEL_LABEL} ..." >&2
echo "    prompt: ${PROMPT:0:80}..." >&2

call_fal() {
    local attempt=0 max_attempts=2
    local timeout_s=240
    while [ "$attempt" -lt "$max_attempts" ]; do
        attempt=$((attempt + 1))
        echo "    [attempt $attempt/$max_attempts] POST ${FAL_ENDPOINT}" >&2
        RESP=$(curl -s --max-time "$timeout_s" -w "\n%{http_code}" \
            -X POST "$FAL_ENDPOINT" \
            -H "Authorization: Key ${FAL_KEY}" \
            -H "Content-Type: application/json" \
            -d "$BODY" 2>/dev/null) && break
        echo "    curl failed (timeout after ${timeout_s}s or connection error)" >&2
        if [ "$attempt" -lt "$max_attempts" ]; then
            echo "    retrying in 5s..." >&2
            sleep 5
        fi
    done
    echo "$RESP"
}

RESP=$(call_fal)
HTTP_CODE=$(echo "$RESP" | tail -1)
BODY_TEXT=$(echo "$RESP" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
    echo "fal.ai returned HTTP $HTTP_CODE: $BODY_TEXT" > "$FAIL_FILE"
    exit 1
fi

HAS_IMAGES=$(python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
print("yes" if "images" in data else "no")
' <<< "$BODY_TEXT")

if [ "$HAS_IMAGES" = "no" ]; then
    STATUS_URL=$(python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
print(data.get("status_url", ""))
' <<< "$BODY_TEXT")
    if [ -z "$STATUS_URL" ]; then
        echo "no images and no status_url in response: $BODY_TEXT" > "$FAIL_FILE"
        exit 1
    fi
    echo ">>> Queued, polling status..." >&2
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
            echo "    [poll $POLL_COUNT] HTTP $STATUS_CODE, retrying..." >&2
            continue
        fi
        REQ_STATUS=$(python3 -c '
import json, sys
data = json.loads(sys.stdin.read())
print(data.get("status", "unknown"))
' <<< "$STATUS_BODY")
        echo "    [poll $POLL_COUNT] status: $REQ_STATUS" >&2
        case "$REQ_STATUS" in
            COMPLETED) BODY_TEXT="$STATUS_BODY"; break ;;
            FAILED|CANCELLED)
                echo "Request $REQ_STATUS: $STATUS_BODY" > "$FAIL_FILE"
                exit 1
                ;;
        esac
    done
    if [ "$POLL_COUNT" -ge "$MAX_POLLS" ]; then
        echo "timed out waiting for image after ${MAX_POLLS} polls" > "$FAIL_FILE"
        exit 1
    fi
fi

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
' <<< "$BODY_TEXT") || { echo "failed to extract image URL from response" > "$FAIL_FILE"; exit 1; }

if [ -z "$IMAGE_URL" ]; then
    echo "no image URL in fal response" > "$FAIL_FILE"
    exit 1
fi

echo "    image URL: $IMAGE_URL" >&2
echo ">>> Downloading to $OUTPATH ..." >&2

DL_OK=0
for i in 1 2; do
    echo "    [download attempt $i/2]" >&2
    if curl -s --max-time 120 -o "$OUTPATH" "$IMAGE_URL" 2>/dev/null; then
        if [ -f "$OUTPATH" ] && [ -s "$OUTPATH" ]; then
            DL_OK=1; break
        fi
    fi
    echo "    download failed, retrying in 3s..." >&2
    sleep 3
done

if [ "$DL_OK" -ne 1 ]; then
    echo "failed to download image from $IMAGE_URL (2 attempts)" > "$FAIL_FILE"
    exit 1
fi

SIZE=$(stat -c%s "$OUTPATH" 2>/dev/null || stat -f%z "$OUTPATH" 2>/dev/null || echo "unknown")
echo ">>> Done. Art: $OUTPATH (${SIZE} bytes)" >&2

OUTBASE=$(basename "$OUTFILE")
if mkdir -p "$WIN_DIR" && cp "$OUTPATH" "$WIN_DIR/$OUTBASE" 2>/dev/null; then
    echo "    Mirror: $WIN_DIR/$OUTBASE" >&2
else
    echo "    [WARN] Could not mirror to $WIN_DIR (drive not mounted?)" >&2
fi

# Write success marker
echo "$OUTPATH" > "$DONE_FILE"
echo ">>> PATH: $OUTPATH" >&2
