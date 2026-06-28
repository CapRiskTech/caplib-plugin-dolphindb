#!/bin/bash
# ─────────────────────────────────────────────────────────────
# caplib DolphinDB Docker Build Script
#
# Downloads the published plugin package plus DolphinDB server,
# assembles a staging directory, and builds
# the Docker image.
#
# Artifact sources:
#   1. libPluginCaplib.so ─┐
#   2. PluginCaplib.txt    │
#   3. libdqlibc.so        │   CapRiskTech/caplib-plugin-dolphindb release
#   4. calendars.bin       │   (0.0.8)
#   5. dqlibc.lic        ─┘
#   6. DolphinDB Server  ─── EXCEPTION — DolphinDB official distribution
#
# Usage:
#   bash docker/build.sh                    # build only
#   bash docker/build.sh --run              # build + run container
#   bash docker/build.sh --test             # build + run + smoke test
#
# Environment variables:
#   DDB_DOWNLOAD_URL   Override DolphinDB download URL
#   DDB_ZIP_PATH       Skip download, use local DDB zip
#   DQLIBC_LICENSE_PATH Explicitly override packaged license with local dqlibc.lic
#   GITHUB_TOKEN       For curl-based downloads (optional; prefers gh CLI)
# ─────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STAGING="$SCRIPT_DIR/.staging"
IMAGE_NAME="${IMAGE_NAME:-caplibdolphin}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# ─── Release versions ───────────────────────────────────────
CAPLIB_PLUGIN_TAG="${CAPLIB_PLUGIN_TAG:-0.0.9}"
CAPLIB_PLUGIN_REPO="CapRiskTech/caplib-plugin-dolphindb"
CAPLIB_PLUGIN_ASSET="caplib-plugin-dolphindb-${CAPLIB_PLUGIN_TAG}.tar.gz"
EXPECTED_PLUGIN_FUNCTIONS="${EXPECTED_PLUGIN_FUNCTIONS:-211}"
REQUIRED_PLUGIN_FUNCTIONS=(
    "CreatePricingModelSettings"
    "CreateVolatilityCurve"
    "CreateVolatilitySurface"
)
PACKAGED_LICENSE_ASSET="dqlibc.lic"

# DolphinDB Server (EXCEPTION — not from dqlab)
# Override with DDB_DOWNLOAD_URL env var or provide a local zip via DDB_ZIP_PATH
DDB_DOWNLOAD_URL="${DDB_DOWNLOAD_URL:-https://cdn.dolphindb.cn/downloads/DolphinDB_Linux64_V3.00.5.zip}"
DDB_EXPECTED_BIN="dolphindb"

# ─── Colors ─────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

fail() { echo -e "${RED}FATAL: $*${NC}"; exit 1; }
info() { echo -e "${GREEN}→${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }

# ─── Helpers ────────────────────────────────────────────────

# Download a release asset using gh CLI (preferred) or curl+GITHUB_TOKEN
download_release() {
    local repo="$1"
    local tag="$2"
    local asset="$3"
    local dest_dir="$4"

    mkdir -p "$dest_dir"

    if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
        info "Downloading $asset from $repo@$tag (gh CLI)..."
        gh release download "$tag" -R "$repo" -p "$asset" -D "$dest_dir" --clobber
    elif [ -n "${GITHUB_TOKEN:-}" ]; then
        local url="https://github.com/${repo}/releases/download/${tag}/${asset}"
        info "Downloading $asset from $repo@$tag (curl + GITHUB_TOKEN)..."
        curl -fsSL -o "$dest_dir/$asset" \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/octet-stream" \
            "$url"
    else
        fail "Neither 'gh' CLI nor GITHUB_TOKEN available. Authenticate with: gh auth login"
    fi
}

echo "═══════════════════════════════════════════"
echo "  caplib DolphinDB Docker Build"
echo "═══════════════════════════════════════════"
echo ""
echo "Image:     $IMAGE_NAME:$IMAGE_TAG"
echo "Release:   $CAPLIB_PLUGIN_REPO@$CAPLIB_PLUGIN_TAG"
echo "Staging:   $STAGING"
echo ""

# ─── Step 1: Prepare staging directory ──────────────────────
info "Preparing staging directory..."
rm -rf "$STAGING"
mkdir -p "$STAGING"

# Copy Dockerfile + scripts (must be at root of build context)
cp "$SCRIPT_DIR/Dockerfile"      "$STAGING/"
cp "$SCRIPT_DIR/entrypoint.sh"   "$STAGING/"
cp "$SCRIPT_DIR/dolphindb.cfg"   "$STAGING/"
cp "$SCRIPT_DIR/dolphindb.dos"   "$STAGING/"
cp "$SCRIPT_DIR/test_plugin.dos" "$STAGING/"

# ─── Step 2: Download caplib plugin package release ─────────
# Contains: libPluginCaplib.so, PluginCaplib.txt, libdqlibc.so, calendars.bin, dqlibc.lic
CAPLIB_PLUGIN_DIR="$SCRIPT_DIR/.cache/caplib-plugin-release"
rm -rf "$CAPLIB_PLUGIN_DIR"
mkdir -p "$CAPLIB_PLUGIN_DIR"

download_release "$CAPLIB_PLUGIN_REPO" "$CAPLIB_PLUGIN_TAG" "$CAPLIB_PLUGIN_ASSET" "$CAPLIB_PLUGIN_DIR"

info "Extracting $CAPLIB_PLUGIN_ASSET..."
tar xzf "$CAPLIB_PLUGIN_DIR/$CAPLIB_PLUGIN_ASSET" -C "$CAPLIB_PLUGIN_DIR" --strip-components=1

# Validate contents (extracted flat — no wrapper directory)
for f in "libPluginCaplib.so" "PluginCaplib.txt" "libdqlibc.so" "$PACKAGED_LICENSE_ASSET"; do
    [ -f "$CAPLIB_PLUGIN_DIR/$f" ] || fail "Missing in caplib plugin release: $f"
done

plugin_function_count="$(grep -c '^[A-Z]' "$CAPLIB_PLUGIN_DIR/PluginCaplib.txt" 2>/dev/null || echo 0)"
if [ "$plugin_function_count" -ne "$EXPECTED_PLUGIN_FUNCTIONS" ]; then
    fail "caplib plugin release $CAPLIB_PLUGIN_TAG exposes $plugin_function_count functions; expected $EXPECTED_PLUGIN_FUNCTIONS. Refusing to build a stale/mismatched Docker image."
fi

for fn in "${REQUIRED_PLUGIN_FUNCTIONS[@]}"; do
    grep -q "^${fn},${fn}," "$CAPLIB_PLUGIN_DIR/PluginCaplib.txt" || \
        fail "caplib plugin release $CAPLIB_PLUGIN_TAG is missing required API: $fn"
done

# Copy artifacts to staging
cp "$CAPLIB_PLUGIN_DIR/libPluginCaplib.so" "$STAGING/"
cp "$CAPLIB_PLUGIN_DIR/PluginCaplib.txt"   "$STAGING/"
cp "$CAPLIB_PLUGIN_DIR/libdqlibc.so"       "$STAGING/"

# calendars.bin — may be in data/ subdirectory
if [ -f "$CAPLIB_PLUGIN_DIR/data/calendars.bin" ]; then
    cp "$CAPLIB_PLUGIN_DIR/data/calendars.bin" "$STAGING/calendars.bin"
elif [ -f "$CAPLIB_PLUGIN_DIR/calendars.bin" ]; then
    cp "$CAPLIB_PLUGIN_DIR/calendars.bin" "$STAGING/calendars.bin"
else
    warn "calendars.bin not found in caplib plugin release — this may cause runtime errors"
fi

echo "  libPluginCaplib.so: $(ls -lh "$STAGING/libPluginCaplib.so" | awk '{print $5}')"
echo "  libdqlibc.so:       $(ls -lh "$STAGING/libdqlibc.so" | awk '{print $5}')"
echo "  Release tag:        $CAPLIB_PLUGIN_TAG"
echo "  Functions:          $plugin_function_count registered"
echo ""

# ─── Step 3: Stage dqlibc license ───────────────────────────
if [ -n "${DQLIBC_LICENSE_PATH:-}" ]; then
    [ -f "$DQLIBC_LICENSE_PATH" ] || fail "DQLIBC_LICENSE_PATH does not exist: $DQLIBC_LICENSE_PATH"
    info "Using local dqlibc license: $DQLIBC_LICENSE_PATH"
    cp "$DQLIBC_LICENSE_PATH" "$STAGING/dqlibc.lic"
else
    cp "$CAPLIB_PLUGIN_DIR/$PACKAGED_LICENSE_ASSET" "$STAGING/dqlibc.lic"
fi

[ -f "$STAGING/dqlibc.lic" ] || fail "Packaged license staging failed"

echo "  License:           $(head -1 "$STAGING/dqlibc.lic" | tr -d '\n\r')"
echo ""

# ─── Step 4: Download DolphinDB Server (EXCEPTION) ──────────
# DolphinDB is the only artifact NOT from dqlab releases.
DDB_SERVER_DIR="$STAGING/dolphindb-server"
mkdir -p "$DDB_SERVER_DIR"

if [ -n "${DDB_ZIP_PATH:-}" ] && [ -f "$DDB_ZIP_PATH" ]; then
    info "Using local DolphinDB zip: $DDB_ZIP_PATH"
    DDB_ZIP="$DDB_ZIP_PATH"
else
    info "Downloading DolphinDB Server from official distribution..."
    info "  URL: $DDB_DOWNLOAD_URL"
    DDB_ZIP="$SCRIPT_DIR/.cache/dolphindb-server.zip"
    mkdir -p "$(dirname "$DDB_ZIP")"
    curl -fsSL -o "$DDB_ZIP" "$DDB_DOWNLOAD_URL" || {
        warn "DDB download failed. If the URL has changed, set DDB_DOWNLOAD_URL or DDB_ZIP_PATH."
        warn "You can also provide a pre-downloaded zip via DDB_ZIP_PATH env var."
        fail "DolphinDB server download failed — see instructions above"
    }
fi

info "Extracting DolphinDB server..."
if [[ "$DDB_ZIP" == *.zip ]]; then
    python3 -c "
import zipfile, sys
with zipfile.ZipFile(sys.argv[1]) as z:
    z.extractall(sys.argv[2])
" "$DDB_ZIP" "$DDB_SERVER_DIR"
elif [[ "$DDB_ZIP" == *.tar.gz ]] || [[ "$DDB_ZIP" == *.tgz ]]; then
    tar xzf "$DDB_ZIP" -C "$DDB_SERVER_DIR" --strip-components=1
else
    fail "Unsupported DDB archive format: $DDB_ZIP (expected .zip or .tar.gz)"
fi

# Find dolphindb binary — may be nested
DDB_BIN=$(find "$DDB_SERVER_DIR" -name "$DDB_EXPECTED_BIN" -type f | head -1)
if [ -z "$DDB_BIN" ]; then
    fail "DolphinDB binary '$DDB_EXPECTED_BIN' not found in extracted archive"
fi

# Flatten: move everything to server/ root
DDB_EXTRACTED_DIR=$(dirname "$DDB_BIN")
if [ "$DDB_EXTRACTED_DIR" != "$DDB_SERVER_DIR" ]; then
    info "Flattening DDB directory structure..."
    # Move all files up, skip the subdirectory itself
    find "$DDB_EXTRACTED_DIR" -mindepth 1 -maxdepth 1 | while read -r item; do
        mv "$item" "$DDB_SERVER_DIR/" 2>/dev/null || true
    done
    # Remove the now-empty nested directory (and any siblings)
    find "$DDB_SERVER_DIR" -mindepth 1 -maxdepth 1 -type d | while read -r d; do
        [ "$(ls -A "$d" 2>/dev/null)" ] || rm -rf "$d"
    done
fi

# Validate DDB server
[ -f "$DDB_SERVER_DIR/$DDB_EXPECTED_BIN" ] || fail "DDB binary missing after extraction"
[ -f "$DDB_SERVER_DIR/libDolphinDB.so" ] || warn "libDolphinDB.so not found — DDB may fail to start"

echo "  DDB binary:        $(ls -lh "$DDB_SERVER_DIR/$DDB_EXPECTED_BIN" | awk '{print $5}')"
echo ""

# ─── Step 5: Verify DDB license ─────────────────────────────
# The official DDB zip includes dolphindb.lic — verify after extraction/flatten
if [ -f "$DDB_SERVER_DIR/dolphindb.lic" ]; then
    info "DDB license found in server archive"
else
    warn "dolphindb.lic not found — DDB may require a license file"
fi

# ─── Step 6: Fix libstdc++ compatibility ────────────────────
# The Dockerfile handles this, but we can verify here.
if [ -f "$DDB_SERVER_DIR/libstdc++.so.6" ]; then
    info "DDB ships bundled libstdc++.so.6 — Dockerfile will rename to .ddb-bundled"
fi

echo ""
info "Staging directory ready:"
echo "  $(find "$STAGING" -maxdepth 2 -type f | wc -l) files"

# ─── Step 7: Build Docker image ─────────────────────────────
echo ""
info "Building Docker image: $IMAGE_NAME:$IMAGE_TAG"
cd "$STAGING"
docker build \
    --build-arg CAPLIB_PLUGIN_TAG="$CAPLIB_PLUGIN_TAG" \
    --build-arg CAPLIB_PLUGIN_FUNCTIONS="$plugin_function_count" \
    -t "$IMAGE_NAME:$IMAGE_TAG" .

echo ""
echo -e "${GREEN}✓ Image built:${NC} $IMAGE_NAME:$IMAGE_TAG"
echo ""

# ─── Step 8: Optional — Run / Test ──────────────────────────
if [[ "${1:-}" == "--run" ]] || [[ "${1:-}" == "--test" ]]; then
    CONTAINER_NAME="caplibdolphin-test"
    echo "→ Stopping any existing test container..."
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

    echo "→ Starting container: $CONTAINER_NAME"
    docker run -d --name "$CONTAINER_NAME" -p 8848:8848 "$IMAGE_NAME:$IMAGE_TAG"
    echo -e "${GREEN}✓ Container started${NC}"
    echo ""
    echo "  Connect via DolphinDB client:"
    echo "    import dolphindb as ddb"
    echo "    s = ddb.session()"
    echo "    s.connect('localhost', 8848, 'admin', '123456')"
    echo "    s.run('loadPlugin(\"/opt/ddb/server/plugins/caplib/PluginCaplib.txt\")')"
    echo ""

    # ─── Optional: Smoke test ────────────────────────────────
    if [[ "${1:-}" == "--test" ]]; then
        echo "→ Waiting for DolphinDB to be ready..."
        for i in $(seq 1 30); do
            if curl -sf http://localhost:8848 > /dev/null 2>&1; then
                echo -e "${GREEN}✓ DDB ready after ${i}s${NC}"
                break
            fi
            sleep 1
        done

        echo ""
        echo "→ Plugin auto-loaded via dolphindb.dos — checking DDB log..."
        # Check if plugin loaded from dolphindb.dos
        docker exec "$CONTAINER_NAME" grep -q "caplib plugin loaded" /opt/ddb/server/log/dolphindb.log 2>/dev/null && \
            echo -e "${GREEN}✓ Plugin loaded successfully${NC}" || \
            echo "  Checking log for errors..."

        echo ""
        echo "→ Running smoke test via Python client..."
        python3 -c "
import dolphindb as ddb
s = ddb.session()
s.connect('localhost', 8848, 'admin', '123456')
r = s.run('caplib::CalcYearFraction(2025.01.01, 2025.12.31, \x60ACTUAL_360)')
print(f'  CalcYearFraction(2025.01.01, 2025.12.31, ACTUAL_360) = {r}')
expected = 364.0 / 360.0
if abs(float(str(r)) - expected) < 1e-6:
    print(f'  ✓ PASS (expected {expected})')
else:
    print(f'  ✗ FAIL (expected {expected}, got {r})')
" 2>&1 || echo "  (install dolphindb for smoke tests: pip install dolphindb)"

        echo ""
        echo "  For full test suite, connect to DDB and run:"
        echo "    run(\"/opt/ddb/test_plugin.dos\")"
    fi
fi

echo ""
echo "═══════════════════════════════════════════"
echo "  Build Complete"
echo "═══════════════════════════════════════════"
echo ""
echo "  Registry:  docker images $IMAGE_NAME"
echo "  Run:       docker run -d -p 8848:8848 --name caplibdolphin $IMAGE_NAME:$IMAGE_TAG"
echo "  Logs:      docker logs -f caplibdolphin"
echo "  Shell:     docker exec -it caplibdolphin bash"
echo "  Stop:      docker stop caplibdolphin"
echo ""

# ─── Cleanup caches (optional — keep for faster rebuilds) ──
# Uncomment to clean up downloaded release artifacts:
# rm -rf "$SCRIPT_DIR/.cache"
