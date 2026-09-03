# ─────────────────────────────────────────────────────────────
# caplib DolphinDB Docker Build Script — Windows (PowerShell)
# Self-contained mirror of docker/build.sh. No bash, no python:
#   - download:  curl.exe (retry + resume; this release is public)
#   - extract:   tar.exe (ships with Windows 10+)
#   - build:     docker (on the official dolphindb image)
#
# Usage:
#   docker\build.bat [--run|--test]       build only / +run / +run+smoke test
#   powershell -File docker\build.ps1 [--run|--test]   (equivalent)
#
# Environment variables (same as build.sh):
#   DDB_BASE_IMAGE, CAPLIB_PLUGIN_TAG, IMAGE_NAME, IMAGE_TAG, GITHUB_TOKEN
# ─────────────────────────────────────────────────────────────
# NOTE: deliberately NOT setting $ErrorActionPreference='Stop'. On Windows
# PowerShell 5.1, a native command writing to stderr (e.g. `docker rm -f` on a
# missing container) becomes a TERMINATING error even with *>/2> redirection,
# which aborts the whole script. Failures are handled explicitly via
# $LASTEXITCODE checks (build.sh-style), not via $ErrorActionPreference.

# Read the mode from raw $args: under `powershell -File`, a bare --run/--test
# argument is dropped by param binding (the leading -- is treated as the
# end-of-options marker), so we must not rely on a param() block here.
$Mode = if ($args.Count -gt 0) { $args[0] } else { '' }

function Info { Write-Host "-> $args" -ForegroundColor Green }
function Warn { Write-Host "WARN: $args" -ForegroundColor Yellow }
function Fail { Write-Host "FATAL: $args" -ForegroundColor Red; exit 1 }

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$context   = Join-Path $scriptDir '.staging'
# Use Windows' bundled bsdtar explicitly — a bare `tar` may resolve to Git Bash's
# GNU tar, which mis-parses Windows paths (D:\...) and fails on -tzf.
$tar = Join-Path $env:SystemRoot 'System32\tar.exe'

$env:IMAGE_NAME = if ($env:IMAGE_NAME) { $env:IMAGE_NAME } else { 'caplibdolphin' }
$env:IMAGE_TAG  = if ($env:IMAGE_TAG)  { $env:IMAGE_TAG  } else { 'latest' }
$CAPLIB_PLUGIN_TAG = if ($env:CAPLIB_PLUGIN_TAG) { $env:CAPLIB_PLUGIN_TAG } else { '0.0.10' }
$CAPLIB_PLUGIN_REPO  = 'CapRiskTech/caplib-plugin-dolphindb'
$CAPLIB_PLUGIN_ASSET = "caplib-plugin-dolphindb-$CAPLIB_PLUGIN_TAG.tar.gz"
$LICENSE_ASSET = 'dqlibc.lic'
$EXPECTED_PLUGIN_FUNCTIONS = 202
$REQUIRED_PLUGIN_FUNCTIONS = @('createPricingModelSettings', 'createVolatilityCurve', 'createVolatilitySurface')
$DDB_BASE_IMAGE = if ($env:DDB_BASE_IMAGE) { $env:DDB_BASE_IMAGE } else { 'dolphindb/dolphindb:v3.00.5' }

if ($Mode -and $Mode -ne '--run' -and $Mode -ne '--test') {
    Write-Host 'Usage: docker\build.bat [--run|--test]' -ForegroundColor Yellow
    exit 1
}

Write-Host '==================================================='
Write-Host '  caplib DolphinDB Docker Build (self-contained)'
Write-Host '==================================================='
Write-Host ''
Write-Host "  Image:     $env:IMAGE_NAME`:$env:IMAGE_TAG"
Write-Host "  Base:      $DDB_BASE_IMAGE"
Write-Host "  Release:   $CAPLIB_PLUGIN_REPO@$CAPLIB_PLUGIN_TAG"
Write-Host ''

# ─── Step 1: Obtain + extract plugin release ────────────────
$releaseDir = Join-Path $scriptDir '.cache\caplib-plugin-release'
New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$tgz = Join-Path $releaseDir $CAPLIB_PLUGIN_ASSET
# Release assets are immutable per tag — reuse a valid cached tarball.
$useCache = $false
if ((Test-Path $tgz) -and ((Get-Item $tgz).Length -gt 0)) {
    & $tar -tzf $tgz *> $null
    if ($LASTEXITCODE -eq 0) { $useCache = $true }
}
if ($useCache) {
    Info "Using cached $CAPLIB_PLUGIN_ASSET (delete docker\.cache to force re-download)"
} else {
    Remove-Item $tgz -Force -ErrorAction SilentlyContinue
    $url = "https://github.com/$CAPLIB_PLUGIN_REPO/releases/download/$CAPLIB_PLUGIN_TAG/$CAPLIB_PLUGIN_ASSET"
    Info "Downloading $CAPLIB_PLUGIN_ASSET..."
    $curlArgs = @('-fL', '--retry', '5', '--retry-all-errors', '--retry-delay', '3', '-C', '-', '-o', $tgz, $url)
    if ($env:GITHUB_TOKEN) {
        $curlArgs += @('-H', "Authorization: token $env:GITHUB_TOKEN", '-H', 'Accept: application/octet-stream')
    }
    curl.exe @curlArgs
    if ($LASTEXITCODE -ne 0) { Fail "Download failed for $CAPLIB_PLUGIN_ASSET" }
}

Info "Extracting $CAPLIB_PLUGIN_ASSET..."
& $tar -xzf $tgz -C $releaseDir --strip-components=1
if ($LASTEXITCODE -ne 0) { Fail "tar extraction failed for $CAPLIB_PLUGIN_ASSET" }

# ─── Step 2: Validate the release ───────────────────────────
foreach ($f in @('libPluginCaplib.so', 'PluginCaplib.txt', 'libdqlibc.so', $LICENSE_ASSET)) {
    if (-not (Test-Path (Join-Path $releaseDir $f))) { Fail "Missing in caplib plugin release: $f" }
}
$lines = Get-Content -Path (Join-Path $releaseDir 'PluginCaplib.txt') -Encoding UTF8
$pluginFunctionCount = ($lines | Where-Object { $_ -match '^[A-Z][A-Za-z0-9]*,[a-z][A-Za-z0-9]*,.*' }).Count
if ($pluginFunctionCount -ne $EXPECTED_PLUGIN_FUNCTIONS) {
    Fail "caplib plugin release $CAPLIB_PLUGIN_TAG exposes $pluginFunctionCount functions; expected $EXPECTED_PLUGIN_FUNCTIONS. Refusing to build a mismatched image."
}
foreach ($fn in $REQUIRED_PLUGIN_FUNCTIONS) {
    $found = $false
    foreach ($l in $lines) {
        if (($l -split ',')[1] -eq $fn) { $found = $true; break }
    }
    if (-not $found) { Fail "caplib plugin release $CAPLIB_PLUGIN_TAG is missing required API: $fn" }
}
Info "Validated: $pluginFunctionCount functions, required APIs present"

# ─── Step 3: Assemble build context (small) ─────────────────
if (Test-Path $context) { Remove-Item $context -Recurse -Force }
New-Item -ItemType Directory -Force -Path $context | Out-Null
Copy-Item (Join-Path $scriptDir 'Dockerfile') $context
# Normalize to LF (Windows checkout CRLF breaks .dos scripts in-container).
# MUST read with -Encoding UTF8: the default ANSI/GBK read corrupts the
# multi-byte UTF-8 box-drawing chars in test_plugin.dos, which breaks DDB's
# script parser at runtime.
foreach ($dos in 'dolphindb.dos', 'test_plugin.dos') {
    $dosContent = (Get-Content -Path (Join-Path $scriptDir $dos) -Raw -Encoding UTF8) -replace "`r`n", "`n" -replace "`r", "`n"
    [System.IO.File]::WriteAllText((Join-Path $context $dos), $dosContent, (New-Object System.Text.UTF8Encoding $false))
}

foreach ($f in @('libPluginCaplib.so', 'PluginCaplib.txt', 'libdqlibc.so', $LICENSE_ASSET)) {
    Copy-Item (Join-Path $releaseDir $f) $context
}
if (Test-Path (Join-Path $releaseDir 'data\calendars.bin')) {
    Copy-Item (Join-Path $releaseDir 'data\calendars.bin') (Join-Path $context 'calendars.bin')
} elseif (Test-Path (Join-Path $releaseDir 'calendars.bin')) {
    Copy-Item (Join-Path $releaseDir 'calendars.bin') (Join-Path $context 'calendars.bin')
} else {
    Fail 'calendars.bin not found in caplib plugin release — required by the Dockerfile COPY and at runtime'
}
Info "Build context ready: $context"

# ─── Step 4: Build Docker image ─────────────────────────────
Info "Building image: $env:IMAGE_NAME`:$env:IMAGE_TAG"
Push-Location $context
try {
    docker build --build-arg "CAPLIB_PLUGIN_TAG=$CAPLIB_PLUGIN_TAG" -t "$env:IMAGE_NAME`:$env:IMAGE_TAG" .
    if ($LASTEXITCODE -ne 0) { Fail 'docker build failed' }
} finally {
    Pop-Location
}
Write-Host ''
Write-Host "OK Image built: $env:IMAGE_NAME`:$env:IMAGE_TAG"
Write-Host ''
Write-Host "  Registry:  docker images $env:IMAGE_NAME"
Write-Host "  Run:       docker run -d -p 8848:8848 --name caplibdolphin $env:IMAGE_NAME`:$env:IMAGE_TAG"
Write-Host "  Logs:      docker logs -f caplibdolphin"
Write-Host "  Shell:     docker exec -it caplibdolphin bash"
Write-Host "  Stop:      docker stop caplibdolphin"
Write-Host ''

# ─── Step 5: Optional — Run / Test ──────────────────────────
if ($Mode -eq '--run' -or $Mode -eq '--test') {
    $containerName = 'caplibdolphin-test'
    Write-Host '-> Stopping any existing test container...'
    docker rm -f $containerName *> $null

    Write-Host "-> Starting container: $containerName"
    docker run -d --name $containerName -p 8848:8848 "$env:IMAGE_NAME`:$env:IMAGE_TAG"
    if ($LASTEXITCODE -ne 0) { Fail 'Failed to start container — is host port 8848 already in use, or is the Docker daemon down?' }
    Write-Host 'OK Container started'
    Write-Host ''
    Write-Host '  Connect via DolphinDB client:'
    Write-Host '    import dolphindb as ddb'
    Write-Host '    s = ddb.session()'
    Write-Host "    s.connect('localhost', 8848, 'admin', '123456')"
    Write-Host "    s.run('loadPlugin(`"/data/ddb/server/plugins/caplib/PluginCaplib.txt`")')"
    Write-Host ''

    if ($Mode -eq '--test') {
        Write-Host '-> Waiting for DolphinDB to be ready...'
        $ready = $false
        for ($i = 1; $i -le 30; $i++) {
            curl.exe -sf http://localhost:8848 *> $null
            if ($LASTEXITCODE -eq 0) { Write-Host "OK DDB ready after ${i}s" -ForegroundColor Green; $ready = $true; break }
            Start-Sleep -Seconds 1
        }
        if (-not $ready) { Warn 'DDB not ready after 30s — continue anyway' }

        Write-Host ''
        Write-Host '-> Checking container log for plugin load...'
        $found = docker logs $containerName 2>&1 | Select-String -Quiet 'caplib'
        if ($found) {
            Write-Host 'OK Plugin load messages found in log' -ForegroundColor Green
        } else {
            Write-Host "  No plugin messages in log — check: docker logs $containerName"
        }

        Write-Host ''
        Write-Host '-> Running test suite (/data/ddb/test_plugin.dos) via Python client...'
        $py = $null
        foreach ($c in 'python', 'py', 'python3') {
            if (Get-Command $c -ErrorAction SilentlyContinue) { $py = $c; break }
        }
        if ($py) {
            $pyScript = @'
import dolphindb as ddb
s = ddb.session()
s.connect('localhost', 8848, 'admin', '123456')
s.run('run("/data/ddb/test_plugin.dos")')
print('')
print('  (test results shown above - DolphinDB relays print output to the client)')
'@
            $tmpPy = Join-Path $env:TEMP 'caplib_test.py'
            [System.IO.File]::WriteAllText($tmpPy, $pyScript, (New-Object System.Text.UTF8Encoding $false))
            if ($py -eq 'py') { py $tmpPy } else { & $py $tmpPy }
            if (-not $?) { Write-Host '  (install dolphindb for tests: pip install dolphindb)' }
        } else {
            Write-Host '  (no python found; install dolphindb for tests: pip install dolphindb)'
        }
        Write-Host ''
        Write-Host '  Done.'
    }
}
