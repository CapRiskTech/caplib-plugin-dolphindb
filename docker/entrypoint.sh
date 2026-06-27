#!/bin/bash
# ─────────────────────────────────────────────────────────────
# caplib Docker Entrypoint
# 1. Start DolphinDB server in background
# 2. Wait for HTTP readiness (max 30s)
# 3. Load the caplib plugin
# 4. Keep container alive (tail logs)
# ─────────────────────────────────────────────────────────────
set -euo pipefail

DDB_HOME="/opt/ddb/server"
PLUGIN_DIR="$DDB_HOME/plugins/caplib"
LOG_FILE="$DDB_HOME/log/dolphindb.log"
PLUGIN_TXT="$PLUGIN_DIR/PluginCaplib.txt"

echo "═══════════════════════════════════════════"
echo "  caplib Docker Container"
echo "  DolphinDB + caplib Plugin Server"
echo "═══════════════════════════════════════════"
echo ""

# ─── Validation ─────────────────────────────────────────────
fail() { echo "FATAL: $*"; exit 1; }

for f in "$DDB_HOME/dolphindb" "$PLUGIN_TXT" "$PLUGIN_DIR/libPluginCaplib.so" "$PLUGIN_DIR/libdqlibc.so"; do
    [ -f "$f" ] || fail "Missing: $f"
done

echo "✓ All required files present"
echo ""

# ─── Start DolphinDB ────────────────────────────────────────
echo "→ Starting DolphinDB server..."
cd "$DDB_HOME"

# Start DDB with console=0 (daemon mode, HTTP endpoint enabled)
# console=1 causes DDB to read stdin and exit when stdin closes
# tzdb=/usr/share/zoneinfo required for timezone support
# Redirect stdin from /dev/null to prevent DDB from reading script input
./dolphindb -console 0 -home "$DDB_HOME" -config "$DDB_HOME/dolphindb.cfg" -stdoutLog true -tzdb /usr/share/zoneinfo </dev/null &
DDB_PID=$!

# ─── Wait for HTTP readiness ────────────────────────────────
echo "→ Waiting for DolphinDB HTTP endpoint..."
MAX_WAIT=30
ELAPSED=0
READY=false
while [ $ELAPSED -lt $MAX_WAIT ]; do
    # DDB starts its HTTP server when it outputs "Successfully connected" or similar.
    # Check if the log file contains the startup completion marker.
    if [ -f "$LOG_FILE" ] && grep -q "Successfully connected" "$LOG_FILE" 2>/dev/null; then
        echo "✓ DolphinDB ready after ${ELAPSED}s"
        READY=true
        break
    fi
    # Also try curl as a backup check
    if curl -sf http://localhost:8848 > /dev/null 2>&1; then
        echo "✓ DolphinDB HTTP ready after ${ELAPSED}s"
        READY=true
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

if [ "$READY" = false ]; then
    echo "WARNING: DolphinDB HTTP endpoint not responding after ${MAX_WAIT}s"
    echo "Check logs at $LOG_FILE"
    echo "Continuing anyway (DDB may be slow to start)..."
fi

# ─── Plugin Auto-Loaded ─────────────────────────────────────
# dolphindb.dos in the home directory loads the plugin automatically
echo ""
echo "→ Plugin auto-loaded via dolphindb.dos"
echo "  Check $LOG_FILE for plugin load status"

# ─── Print Info ─────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
echo "  Container Ready"
echo "═══════════════════════════════════════════"
echo ""
echo "  DDB HTTP:    http://localhost:8848"
echo "  Plugin:      $PLUGIN_DIR"
echo "  Functions:   $(grep -c '^[A-Z]' "$PLUGIN_TXT" || echo '?') registered"
echo "  License:    $(head -1 "$PLUGIN_DIR/dqlibc.lic" 2>/dev/null || echo 'N/A')"
echo ""
echo "  To test:"
echo "    curl -X POST http://localhost:8848 \\"
echo "      --data-binary 'caplib::CalcYearFraction(2025.01.01,2025.12.31,\`ACTUAL_360)'"
echo ""
echo "═══════════════════════════════════════════"

# ─── Keep Alive ─────────────────────────────────────────────
# Wait for DDB process; if it dies, exit with its code
wait "$DDB_PID" 2>/dev/null || true
DDB_EXIT=$?
echo "DolphinDB exited with code $DDB_EXIT"
exit $DDB_EXIT
