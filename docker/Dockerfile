# ─────────────────────────────────────────────────────────────
# caplib Docker Image
# Standalone Docker environment for caplib DolphinDB plugin:
#   - DolphinDB 3.00.5 Community Edition
#   - libPluginCaplib.so (caplib plugin, 211 user-facing functions)
#   - libdqlibc.so (dqlib C interop, ABI0)
#   - dqlibc.lic (RSA-signed license)
#
# Usage:
#   docker build -t caplibdolphin:latest -f docker/Dockerfile .
#   docker run -d -p 8848:8848 --name caplibdolphin caplibdolphin:latest
# ─────────────────────────────────────────────────────────────

FROM ubuntu:24.04

ARG CAPLIB_PLUGIN_TAG=unknown
ARG CAPLIB_PLUGIN_FUNCTIONS=unknown

LABEL org.dqlab.image="caplibdolphin"
LABEL description="DolphinDB + caplib plugin standalone pricing server"
LABEL version="1.0.0"
LABEL org.dqlab.caplib.release="$CAPLIB_PLUGIN_TAG"
LABEL org.dqlab.caplib.functions="$CAPLIB_PLUGIN_FUNCTIONS"

# ─── System Dependencies ────────────────────────────────────
# ubuntu:24.04 ships GCC 13's libstdc++ (GLIBCXX_3.4.32), which
# is required by both libdqlibc.so and libPluginCaplib.so.
# tzdata is needed for DolphinDB timezone database.
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# ─── DolphinDB Server ───────────────────────────────────────
# Copy the pre-downloaded DDB server (Community Edition 3.00.5)
COPY dolphindb-server/ /opt/ddb/server/

# ─── Fix libstdc++ compatibility ────────────────────────────
# DolphinDB ships an ancient libstdc++.so.6 (GCC 4.x).
# Rename it so the system's GCC 13 libstdc++ is used instead.
RUN if [ -f /opt/ddb/server/libstdc++.so.6 ]; then \
        mv /opt/ddb/server/libstdc++.so.6 \
           /opt/ddb/server/libstdc++.so.6.ddb-bundled; \
    fi

# ─── DDB writable directories ───────────────────────────────
# DDB needs write access to its home directory for logs,
# local8848/ storage, plugins/ metadata, etc.
RUN mkdir -p /opt/ddb/server/local8848 \
             /opt/ddb/server/plugins \
             /opt/ddb/server/log \
    && chmod -R 755 /opt/ddb/server
# DDB also needs a writable temp dir for the web server
RUN mkdir -p /opt/ddb/server/tempResults

# ─── caplib Plugin ──────────────────────────────────────────
# Plugin dir is OUTSIDE <home>/plugins/ to avoid DDB auto-load
# (which would crash on startup if loading fails).
COPY libPluginCaplib.so /opt/ddb/server/plugins/caplib/
COPY PluginCaplib.txt   /opt/ddb/server/plugins/caplib/

# ─── dqlibc Runtime ─────────────────────────────────────────
# libdqlibc.so placed next to the plugin (RPATH $ORIGIN resolves it).
COPY libdqlibc.so      /opt/ddb/server/plugins/caplib/
COPY calendars.bin     /opt/ddb/server/plugins/caplib/data/

# ─── License ────────────────────────────────────────────────
# licensecc search order (priority 3): same directory via dladdr.
# Placing dqlibc.lic next to libdqlibc.so is the most reliable location.
COPY dqlibc.lic        /opt/ddb/server/plugins/caplib/

# ─── Configuration ──────────────────────────────────────────
# Override dolphindb.cfg for Docker (localhost, single mode, limited memory)
COPY dolphindb.cfg     /opt/ddb/server/dolphindb.cfg

# ─── Entrypoint & Test Scripts ──────────────────────────────
COPY entrypoint.sh     /opt/ddb/entrypoint.sh
COPY dolphindb.dos     /opt/ddb/server/dolphindb.dos
COPY test_plugin.dos   /opt/ddb/test_plugin.dos
RUN chmod +x /opt/ddb/entrypoint.sh

# ─── Volumes ────────────────────────────────────────────────
# DDB data persists across container restarts
VOLUME ["/opt/ddb/server/local8848", "/opt/ddb/server/log"]

# ─── Ports ──────────────────────────────────────────────────
EXPOSE 8848

# ─── Health Check ───────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD curl -sf http://localhost:8848 || exit 1

# ─── Run ────────────────────────────────────────────────────
WORKDIR /opt/ddb/server
ENTRYPOINT ["/opt/ddb/entrypoint.sh"]
