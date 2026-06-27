# caplib-plugin-dolphindb Docker

Standalone Docker environment packaging **DolphinDB 3.00.5 Community Edition** +
**caplib DolphinDB plugin** + **dqlibc C interop library** into a single runnable
image. Useful for integration testing, CI/CD, and isolated pricing server deployment.

## Directory Structure

```
docker/
├── README.md           ← this file
├── Dockerfile           # multi-layer build definition (ubuntu:24.04 base)
├── build.sh             # orchestrates .staging/ assembly + docker build
├── entrypoint.sh        # DDB startup + plugin loading
├── dolphindb.cfg        # Docker-optimized DDB config (16 GB memory)
├── dolphindb.dos        # auto-startup script (loads plugin on boot)
├── test_plugin.dos      # smoke test runnable inside DDB
└── .staging/            # build-time artifact (gitignored, assembled by build.sh)
```

## Container Filesystem Layout

```
/opt/ddb/server/
├── dolphindb                    # DDB 3.00.5 binary
├── libDolphinDB.so
├── dolphindb.cfg                # Docker config (maxMemSize=16, localSite=0.0.0.0:8848)
├── libstdc++.so.6.ddb-bundled   # renamed → system GCC 13 libstdc++ used instead
├── dolphindb.dos                # auto-loads plugin at startup
├── dolphindb.lic                # DDB license (from official distribution zip)
├── local8848/                   # writable data volume
├── log/                         # writable log volume
└── plugins/
    └── caplib/
        ├── libPluginCaplib.so   # 211 user-facing functions, ABI0
        ├── PluginCaplib.txt     # v3.00.5.0 format, from caplib-plugin-dolphindb release
        ├── libdqlibc.so         # ABI0 variant — from caplib-plugin-dolphindb release
        ├── dqlibc.lic           # from the packaged release tarball (priority 3: dladdr)
        └── data/
            └── calendars.bin    # calendar data

/opt/ddb/
├── entrypoint.sh                # container startup script
└── test_plugin.dos              # smoke test script
```

## Prerequisites

`build.sh` downloads the published plugin package automatically and can use a local
`dqlibc.lic` override when needed. By default, `dqlibc.lic` is taken from the same
`CapRiskTech/caplib-plugin-dolphindb` release tarball as the plugin binaries.

| # | Artifact | Release Source | Notes |
|---|----------|---------------|-------|
| 1 | `libPluginCaplib.so` | `CapRiskTech/caplib-plugin-dolphindb` @ `0.0.8` | 211 user-facing functions, ABI0 |
| 2 | `PluginCaplib.txt` | (bundled in above release) | **Configured** output, NOT source template |
| 3 | `libdqlibc.so` | (bundled in above release) | ABI0 variant |
| 4 | `calendars.bin` | (bundled in above release) | Calendar data |
| 5 | `dqlibc.lic` | (bundled in above release) | RSA-signed license |
| 6 | DolphinDB Server | **EXCEPTION** — DolphinDB official distribution | `dolphindb` binary + `libDolphinDB.so` |

> **Rule**: The caplib plugin package supplies artifacts 1-5 as a single release asset.
> DolphinDB Server is the **only exception** — it comes from the official DolphinDB
> distribution (default URL: `https://cdn.dolphindb.cn/downloads/DolphinDB_Linux64_V3.00.5.zip`).
> Override via `DDB_DOWNLOAD_URL` or provide a local zip via `DDB_ZIP_PATH`.

**Authentication**: authenticate once with GitHub access to `CapRiskTech/caplib-plugin-dolphindb`:
```bash
gh auth login
```
Or set `GITHUB_TOKEN` (requires `repo` scope).

To use an existing license file instead of the packaged release license:
```bash
DQLIBC_LICENSE_PATH=~/.dqlib/dqlibc.lic bash docker/build.sh
```

## Quick Start

```bash
cd caplib-plugin-dolphindb

# Build image only
bash docker/build.sh

# Build and run container (port 8848)
bash docker/build.sh --run

# Build, run, and smoke test
bash docker/build.sh --test
```

### Manual Docker Commands

```bash
# Run
docker run -d -p 8848:8848 --name caplibdolphin caplibdolphin:latest

# View logs
docker logs -f caplibdolphin

# Shell inside container
docker exec -it caplibdolphin bash

# Stop and remove
docker stop caplibdolphin && docker rm caplibdolphin
```

## Connecting from DolphinDB Client

```python
import dolphindb as ddb

s = ddb.session()
s.connect("localhost", 8848, "admin", "123456")

# Plugin is auto-loaded via dolphindb.dos at startup.
# If needed, load manually:
# s.run('loadPlugin("/opt/ddb/server/plugins/caplib/PluginCaplib.txt")')

# Quick test
r = s.run("caplib::CalcYearFraction(2025.01.01, 2025.12.31, `ACTUAL_360)")
print(r)  # → 1.013889
```

## Smoke Test

Inside DDB (Python client or console), run the packaged test script:

```dolphindb
run("/opt/ddb/test_plugin.dos")
```

Tests covered:
1. **loadPlugin** — verifies plugin loads and returns non-zero function count
2. **CalcYearFraction** — basic utility function, verifies ABI0 linkage
3. **CreateIrYieldCurve** — ObjectCache-based factory, verifies curve construction
4. **CreatePricingSettings** — settings factory, verifies enum resolution
5. **CreatePricingModelSettings** — model settings factory
6. **CreateEqRiskSettings** — handle-plus-JSON return path, verifies cache serialization

Expected output:
```
═══════════════════════════════════════════
  Results: 6/6 passed
═══════════════════════════════════════════
✓ ALL TESTS PASSED
```

## Configuration

### dolphindb.cfg

Docker-optimized settings for a single-node development server:

| Parameter | Value | Reason |
|-----------|-------|--------|
| `localSite` | `0.0.0.0:8848:local8848` | Binds all interfaces for Docker port mapping |
| `mode` | `single` | Single-node, no cluster |
| `maxMemSize` | `16` | 16 GB — matches Docker memory limits |
| `maxConnections` | `512` | Reasonable for dev/CI |
| `workerNum` | `4` | Parallel job workers |
| `localExecutors` | `3` | Local executor threads |
| `enableAuditLog` | `false` | Disabled to reduce noise |
| `perfMonitoring` | `false` | Disabled for dev |

### dolphindb.dos (Auto-Startup)

DDB automatically executes `dolphindb.dos` from its home directory at startup.
The Docker version loads the caplib plugin:

```dolphindb
try {
    fns = loadPlugin("/opt/ddb/server/plugins/caplib/PluginCaplib.txt");
    print("✓ caplib plugin loaded: " + size(fns) + " functions registered");
} catch(ex) {
    print("✗ Failed to load caplib plugin: " + ex);
}
```

## Key Design Decisions

### libstdc++ Compatibility (CRITICAL)

DolphinDB 3.00.5 ships a `libstdc++.so.6` from GCC 4.x era (only up to
`GLIBCXX_3.4.5`). Both `libdqlibc.so` and `libPluginCaplib.so` are built with
GCC 13 and require `GLIBCXX_3.4.32`.

**Fix**: Rename DDB's `libstdc++.so.6` → `libstdc++.so.6.ddb-bundled` so the
system's GCC 13 `libstdc++.so.6` (from `ubuntu:24.04`) is used instead.

Never delete the file — keep it as `.ddb-bundled` for traceability.

### Timezone Database (tzdata)

DDB exits with code 255 without a timezone database:
```
Can't find time zone database. Please use parameter tzdb to set the root directory.
```

**Fix**: Install `tzdata` package and pass `-tzdb /usr/share/zoneinfo` at startup.

### Console Mode: `-console 0` (daemon)

DDB in `-console 1` mode (interactive) reads from stdin. In Docker, stdin closes
after the entrypoint script finishes, causing DDB to exit cleanly (code 0).

**Fix**: Use `-console 0` (daemon mode) with `</dev/null` as belt-and-suspenders.

### Network Binding

`localSite=0.0.0.0:8848:local8848` binds all interfaces. Using `localhost`
would only bind the loopback, making the port unreachable from the Docker host.

### Plugin Auto-Load: dolphindb.dos, NOT curl

DDB's HTTP endpoint expects JSON-formatted requests. Raw script text sent via
`curl -X POST --data-binary` returns `"not a valid json request"`.

**Fix**: Place `dolphindb.dos` in the DDB home directory — DDB automatically
executes it at startup. Use a Python `dolphindb` client for programmatic invocation.

### Plugin Placement: Outside `<home>/plugins/`

DDB auto-scans `<home>/plugins/` at startup. If a plugin fails to load (format
error, missing symbols, invalid license), DDB exits with code 255 **silently** —
no log output, no error message.

**Fix**: Place the plugin at `/opt/ddb/server/plugins/caplib/` and load it
**manually** via `dolphindb.dos` or `loadPlugin()`. The plugin directory is
OUTSIDE the auto-scan path.

### RPATH Resolution

`libPluginCaplib.so` has RPATH `$ORIGIN` (plus release build paths).
The `$ORIGIN` entry means it searches for `libdqlibc.so` in the same directory.
Placing `libdqlibc.so` next to the plugin satisfies this without `LD_LIBRARY_PATH`.

### License Placement

licensecc search order (from `license_verify.cpp`):
1. `/etc/dqlib/dqlibc.lic`
2. `$HOME/.dqlib/dqlibc.lic`
3. Same directory as `libdqlibc.so` (via `dladdr`)

**Priority 3** is most reliable in Docker — place `dqlibc.lic` next to `libdqlibc.so`.

### PluginCaplib.txt: Build Output, NOT Source Template

The source `PluginCaplib.txt` has CMake template variables (`${PluginVersion}`,
`${CMAKE_SHARED_LIBRARY_SUFFIX}`). DDB v3.00.5 rejects this. Always use the
**configured output** from `build/PluginCaplib.txt`.

Pre-build verification:
```bash
# No comment lines (DDB v3.00.5 rejects #)
grep -c '^#' build/PluginCaplib.txt    # → 0

# All 8 fields (7 commas per function line)
awk -F',' 'NR>1 && NF!=8 {print NR": "NF" fields"}' build/PluginCaplib.txt

# maxArgCount >= minArgCount
awk -F',' 'NR>1 && $4+0 > $5+0 {print NR": min="$4" > max="$5": "$1}' build/PluginCaplib.txt
```

## build.sh Details

`build.sh` assembles a staging directory at `docker/.staging/` (gitignored),
then runs `docker build` with only that directory as context. This keeps the
build context small and avoids accidentally including the full repo.

### Assembly Steps

1. **Download caplib-plugin-dolphindb release** → extract `libPluginCaplib.so`, `PluginCaplib.txt`, `libdqlibc.so`, `calendars.bin`, `dqlibc.lic`
3. **Download DolphinDB Server** from official distribution → extract `dolphindb` + `libDolphinDB.so` + `dolphindb.lic`
4. **Prepare staging** — `rm -rf docker/.staging && mkdir -p`
5. **Copy Docker sources** — Dockerfile, entrypoint.sh, config, .dos scripts
6. **Copy downloaded artifacts** into staging directory
7. **Build image** — `docker build -t caplibdolphin:latest .` from staging dir

### Optional Flags

| Flag | Behavior |
|------|----------|
| `--run` | Build + start container on port 8848 |
| `--test` | Build + start + wait for HTTP (30s) + smoke test via curl |

## Common Pitfalls

| Symptom | Cause | Fix |
|---------|-------|-----|
| DDB exits code 255, no output | Plugin in auto-scan path failing to load | Move plugin outside `<home>/plugins/` |
| DDB exits code 255, no output | Missing tzdata | `apt-get install tzdata` + `-tzdb /usr/share/zoneinfo` |
| DDB exits code 0, no output | `-console 1` reads stdin, exits when stdin closes | Use `-console 0` + `</dev/null` |
| Port 8848 unreachable from host | `localSite=localhost` only binds loopback | Set `localSite=0.0.0.0:8848:local8848` |
| `GLIBCXX_3.4.32 not found` | DDB's bundled libstdc++ taking priority | Rename to `.ddb-bundled` |
| `LICENSE_FILE_NOT_FOUND` | dqlibc.lic not in search path | Place next to libdqlibc.so |
| Plugin loads but 0 functions work | Column 2 case mismatch in PluginCaplib.txt | Verify PascalCase matches C++ exports |
| `Invalid plugin file` | Deployed source template (`${PluginVersion}`) | Use `build/PluginCaplib.txt` configured output |
| `minArgCount can't exceed maxArgCount` | Old `maxArgs=0` convention | Set `maxArgCount = minArgCount` |
| `not a valid json request` from curl | DDB HTTP endpoint expects JSON | Use `dolphindb.dos` or Python client |
| `std::bad_alloc` on ProcessRequest | Wrong ProcessRequest signature | ProcessRequest takes 6 args, not 3 |

## Volumes & Persistence

Two directories are declared as Docker volumes and persist across container restarts:

- `/opt/ddb/server/local8848` — DDB's in-memory table persistence
- `/opt/ddb/server/log` — DDB and plugin logs

To inspect logs:
```bash
docker exec caplibdolphin tail -100 /opt/ddb/server/log/dolphindb.log
```

## Health Check

The Dockerfile includes a health check that polls DDB's HTTP endpoint every 30 seconds:

```
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -sf http://localhost:8848 || exit 1
```

Check health status:
```bash
docker inspect --format='{{.State.Health.Status}}' caplibdolphin
```

## Rebuilding

To rebuild after source changes:

```bash
# Rebuild the plugin
cd caplib-plugin-dolphindb
cmake --build build -j$(nproc)

# Rebuild Docker image
bash docker/build.sh --test
```
