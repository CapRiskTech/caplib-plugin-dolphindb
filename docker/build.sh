#!/bin/bash
# ─────────────────────────────────────────────────────────────
# caplib DolphinDB Docker Build Script (self-contained)
#
# Downloads the Caplib plugin release (~18MB), assembles a small
# build context, and builds the image ON TOP of the official
# DolphinDB image (no DDB distribution download, no apt-get).
# Mirrors the docker-compose/ approach; the plugin is baked in.
#
# Usage:
#   bash docker/build.sh                    # build only
#   bash docker/build.sh --run              # build + run container
#   bash docker/build.sh --test             # build + run + smoke test
#   docker\build.bat [--run|--test]         # same, on Windows
#
# Environment variables:
#   DDB_BASE_IMAGE       Override base image (default dolphindb/dolphindb:v3.00.5)
#   CAPLIB_PLUGIN_TAG    Override plugin release tag (default 0.0.11)
#   CAPLIB_PLUGIN_ARCHIVE  Use a local release archive (also works before publication)
#   IMAGE_NAME / IMAGE_TAG   Override image name/tag (default caplibdolphin:latest)
#   GITHUB_TOKEN         For private repos (this release is public; optional)
# ─────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTEXT="$SCRIPT_DIR/.staging"
IMAGE_NAME="${IMAGE_NAME:-caplibdolphin}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# ─── Release versions ───────────────────────────────────────
CAPLIB_PLUGIN_TAG="${CAPLIB_PLUGIN_TAG:-0.0.11}"
CAPLIB_PLUGIN_REPO="CapRiskTech/caplib-plugin-dolphindb"
CAPLIB_PLUGIN_ASSET="caplib-plugin-dolphindb-${CAPLIB_PLUGIN_TAG}.tar.gz"
LICENSE_ASSET="dqlibc.lic"
# Keep in sync with CAPLIB_PLUGIN_TAG (the 0.0.11 descriptor exports 202).
EXPECTED_PLUGIN_FUNCTIONS=202
REQUIRED_PLUGIN_FUNCTIONS=(
    "createPricingModelSettings"
    "createVolatilityCurve"
    "createVolatilitySurface"
)
DDB_BASE_IMAGE="${DDB_BASE_IMAGE:-dolphindb/dolphindb:v3.00.5}"

# ─── Mode: '' (build) | --run | --test ──────────────────────
MODE="${1:-}"
if [ -n "$MODE" ] && [ "$MODE" != "--run" ] && [ "$MODE" != "--test" ]; then
    echo "Usage: bash docker/build.sh [--run|--test]" >&2
    exit 1
fi

# ─── Colors / helpers (ASCII) ───────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
fail() { echo -e "${RED}FATAL: $*${NC}"; exit 1; }
info() { echo -e "${GREEN}->${NC} $*"; }
warn() { echo -e "${YELLOW}WARN:${NC} $*"; }

# Download a release asset. This release is public, so curl.exe/curl works
# anonymously; --retry + -C - handle flaky networks and resume partials.
download_release() {
    local repo="$1" tag="$2" asset="$3" dest="$4"
    local url="https://github.com/${repo}/releases/download/${tag}/${asset}"
    mkdir -p "$dest"
    local auth=()
    [ -n "${GITHUB_TOKEN:-}" ] && auth=(-H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/octet-stream")
    curl -fL --retry 5 --retry-all-errors --retry-delay 3 -C - "${auth[@]}" \
        -o "$dest/$asset" "$url"
    [ -s "$dest/$asset" ] || fail "Download produced an empty file for $asset"
}

echo "==================================================="
echo "  caplib DolphinDB Docker Build (self-contained)"
echo "==================================================="
echo ""
echo "  Image:     $IMAGE_NAME:$IMAGE_TAG"
echo "  Base:      $DDB_BASE_IMAGE"
echo "  Release:   $CAPLIB_PLUGIN_REPO@$CAPLIB_PLUGIN_TAG"
echo ""

# ─── Step 1: Obtain + extract plugin release ────────────────
# Release assets are immutable per tag, so reuse a valid cached tarball
# instead of re-downloading on every build (flaky networks).
RELEASE_DIR="$SCRIPT_DIR/.cache/caplib-plugin-release"
mkdir -p "$RELEASE_DIR"
TARBALL="$RELEASE_DIR/$CAPLIB_PLUGIN_ASSET"

if [ -n "${CAPLIB_PLUGIN_ARCHIVE:-}" ]; then
    [ -s "$CAPLIB_PLUGIN_ARCHIVE" ] || fail "Local archive does not exist or is empty: $CAPLIB_PLUGIN_ARCHIVE"
    tar -tzf "$CAPLIB_PLUGIN_ARCHIVE" >/dev/null 2>&1 || fail "Invalid local plugin archive"
    if [ ! "$CAPLIB_PLUGIN_ARCHIVE" -ef "$TARBALL" ]; then
        cp "$CAPLIB_PLUGIN_ARCHIVE" "$TARBALL"
    fi
    info "Using local plugin archive: $CAPLIB_PLUGIN_ARCHIVE"
elif [ -s "$TARBALL" ] && tar -tzf "$TARBALL" >/dev/null 2>&1; then
    info "Using cached $CAPLIB_PLUGIN_ASSET (delete docker/.cache to force re-download)"
else
    rm -f "$TARBALL"
    info "Downloading $CAPLIB_PLUGIN_ASSET..."
    download_release "$CAPLIB_PLUGIN_REPO" "$CAPLIB_PLUGIN_TAG" "$CAPLIB_PLUGIN_ASSET" "$RELEASE_DIR"
fi

info "Extracting $CAPLIB_PLUGIN_ASSET..."
# Extract each archive into its own fresh directory: files omitted by a newer
# archive must not be silently supplied by an older cached release.
PACKAGE_DIR="$(mktemp -d "$RELEASE_DIR/extracted.XXXXXX")"
trap 'rm -rf -- "$PACKAGE_DIR"' EXIT
tar xzf "$TARBALL" -C "$PACKAGE_DIR" --strip-components=1
RELEASE_DIR="$PACKAGE_DIR"
if [ -f "$RELEASE_DIR/SHA256SUMS" ]; then
    (cd "$RELEASE_DIR" && sha256sum -c SHA256SUMS) || fail "Plugin archive checksum verification failed"
fi

# ─── Step 2: Validate the release ───────────────────────────
for f in "libPluginCaplib.so" "PluginCaplib.txt" "libdqlibc.so" "$LICENSE_ASSET"; do
    [ -f "$RELEASE_DIR/$f" ] || fail "Missing in caplib plugin release: $f"
done

plugin_function_count="$(grep -Ec '^[A-Z][A-Za-z0-9]*,[a-z][A-Za-z0-9]*,.*' "$RELEASE_DIR/PluginCaplib.txt" || echo 0)"
[ "$plugin_function_count" -eq "$EXPECTED_PLUGIN_FUNCTIONS" ] || \
    fail "caplib plugin release $CAPLIB_PLUGIN_TAG exposes $plugin_function_count functions; expected $EXPECTED_PLUGIN_FUNCTIONS. Refusing to build a mismatched image."

for fn in "${REQUIRED_PLUGIN_FUNCTIONS[@]}"; do
    awk -F, -v fn="$fn" 'NR>1 && $2 == fn { found=1 } END { exit !found }' \
        "$RELEASE_DIR/PluginCaplib.txt" || \
        fail "caplib plugin release $CAPLIB_PLUGIN_TAG is missing required API: $fn"
done
info "Validated: $plugin_function_count functions, required APIs present"

# ─── Step 3: Assemble build context (small) ─────────────────
rm -rf "$CONTEXT"
mkdir -p "$CONTEXT"
cp "$SCRIPT_DIR/Dockerfile" "$CONTEXT/"
# Normalize to LF: CRLF .dos scripts (Windows checkout with core.autocrlf)
# can break DDB startup/script execution in-container.
sed 's/\r$//' "$SCRIPT_DIR/dolphindb.dos"   > "$CONTEXT/dolphindb.dos"
sed 's/\r$//' "$SCRIPT_DIR/test_plugin.dos" > "$CONTEXT/test_plugin.dos"

cp "$RELEASE_DIR/libPluginCaplib.so" "$CONTEXT/"
cp "$RELEASE_DIR/PluginCaplib.txt"   "$CONTEXT/"
cp "$RELEASE_DIR/libdqlibc.so"       "$CONTEXT/"
cp "$RELEASE_DIR/$LICENSE_ASSET"     "$CONTEXT/$LICENSE_ASSET"

# calendars.bin — may be in data/ subdirectory
if [ -f "$RELEASE_DIR/data/calendars.bin" ]; then
    cp "$RELEASE_DIR/data/calendars.bin" "$CONTEXT/calendars.bin"
elif [ -f "$RELEASE_DIR/calendars.bin" ]; then
    cp "$RELEASE_DIR/calendars.bin" "$CONTEXT/calendars.bin"
else
    fail "calendars.bin not found in caplib plugin release — required by the Dockerfile COPY and at runtime"
fi

info "Build context ready: $CONTEXT"
echo "  $(find "$CONTEXT" -maxdepth 1 -type f | wc -l) files"
echo ""

# ─── Step 4: Build Docker image ─────────────────────────────
info "Building image: $IMAGE_NAME:$IMAGE_TAG"
cd "$CONTEXT"
docker build \
    --build-arg DDB_BASE_IMAGE="$DDB_BASE_IMAGE" \
    --build-arg CAPLIB_PLUGIN_TAG="$CAPLIB_PLUGIN_TAG" \
    -t "$IMAGE_NAME:$IMAGE_TAG" .

echo ""
echo -e "${GREEN}OK Image built:${NC} $IMAGE_NAME:$IMAGE_TAG"
echo ""
echo "  Registry:  docker images $IMAGE_NAME"
echo "  Run:       docker run -d -p 8848:8848 --name caplibdolphin $IMAGE_NAME:$IMAGE_TAG"
echo "  Logs:      docker logs -f caplibdolphin"
echo "  Shell:     docker exec -it caplibdolphin bash"
echo "  Stop:      docker stop caplibdolphin"
echo ""

# ─── Step 5: Optional — Run / Test ──────────────────────────
if [ "$MODE" = "--run" ] || [ "$MODE" = "--test" ]; then
    CONTAINER_NAME="caplibdolphin-test"
    echo "-> Stopping any existing test container..."
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

    echo "-> Starting container: $CONTAINER_NAME"
    docker run -d --name "$CONTAINER_NAME" -p 8848:8848 "$IMAGE_NAME:$IMAGE_TAG" || \
        fail "Failed to start container — is host port 8848 already in use, or is the Docker daemon down?"
    echo -e "${GREEN}OK Container started${NC}"
    echo ""
    echo "  Connect via DolphinDB client:"
    echo "    import dolphindb as ddb"
    echo "    s = ddb.session()"
    echo "    s.connect('localhost', 8848, 'admin', '123456')"
    echo "    s.run('loadPlugin(\"/data/ddb/server/plugins/caplib/PluginCaplib.txt\")')"
    echo ""

    if [ "$MODE" = "--test" ]; then
        echo "-> Waiting for DolphinDB to be ready..."
        READY=false
        for i in $(seq 1 30); do
            if curl -sf http://localhost:8848 >/dev/null 2>&1; then
                echo -e "${GREEN}OK DDB ready after ${i}s${NC}"
                READY=true
                break
            fi
            sleep 1
        done
        [ "$READY" = true ] || warn "DDB not ready after 30s — continue anyway"

        echo ""
        echo "-> Checking container log for plugin load..."
        if docker logs "$CONTAINER_NAME" 2>&1 | grep -qi "caplib"; then
            echo -e "${GREEN}OK Plugin load messages found in log${NC}"
        else
            echo "  No plugin messages in log — check: docker logs $CONTAINER_NAME"
        fi

        echo ""
        echo "-> Running test suite (/data/ddb/test_plugin.dos) via Python client..."
        PY=""
        for c in python python3 py; do
            if command -v "$c" >/dev/null 2>&1; then PY="$c"; break; fi
        done
        if [ -n "$PY" ]; then
            "$PY" - <<'PYEOF' 2>&1 || echo "  (install dolphindb for tests: pip install dolphindb)"
import dolphindb as ddb
s = ddb.session()
s.connect('localhost', 8848, 'admin', '123456')
s.run('run("/data/ddb/test_plugin.dos")')
print('')
print('  (test results shown above - DolphinDB relays print output to the client)')
PYEOF
        else
            echo "  (no python found; install dolphindb for tests: pip install dolphindb)"
        fi
        echo ""
        echo "  Done."
    fi
fi
