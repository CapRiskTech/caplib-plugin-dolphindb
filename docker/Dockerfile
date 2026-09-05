# ─────────────────────────────────────────────────────────────
# caplib DolphinDB Docker Image (self-contained)
# Built on top of the official DolphinDB image; preserves its libstdc++
# and bakes in the Caplib plugin. Same mechanism as docker-compose/,
# but the plugin is copied into the image instead of host-mounted.
#
# Usage (assembled by build.sh):
#   docker build -t caplibdolphin:latest .
#   docker run -d -p 8848:8848 --name caplibdolphin caplibdolphin:latest
# ─────────────────────────────────────────────────────────────

ARG DDB_BASE_IMAGE=dolphindb/dolphindb:v3.00.5
FROM ${DDB_BASE_IMAGE}

USER root

ARG CAPLIB_PLUGIN_TAG=unknown
LABEL org.caprisktech.caplib.release="$CAPLIB_PLUGIN_TAG"

# The 0.0.11 GCC 8 package needs at most GLIBCXX_3.4.23 / CXXABI_1.3.11.
# Keep the official server's glibc C++ runtime unchanged.
# Bake in the Caplib plugin (assembled by build.sh / build.ps1).
# Same layout as docker-compose/, so dolphindb.dos finds it at startup.
COPY libPluginCaplib.so /data/ddb/server/plugins/caplib/
COPY PluginCaplib.txt   /data/ddb/server/plugins/caplib/
COPY libdqlibc.so       /data/ddb/server/plugins/caplib/
COPY dqlibc.lic         /data/ddb/server/plugins/caplib/
COPY calendars.bin      /data/ddb/server/plugins/caplib/data/
COPY dolphindb.dos      /data/ddb/server/dolphindb.dos
COPY test_plugin.dos    /data/ddb/test_plugin.dos

# Fail the image build if an old GCC 13 package or mismatched dependency is
# supplied. The glibc loader checks version requirements without running DDB.
# Its --list mode may return 0 after a missing-version diagnostic, so inspect
# the diagnostic text as well as the exit status.
RUN set -eu; for library in libdqlibc.so libPluginCaplib.so; do \
        output="$(LC_ALL=C /usr/glibc-compat/lib/ld-linux-x86-64.so.2 \
            --library-path /data/ddb/server/plugins/caplib:/data/ddb/server:/usr/glibc-compat/lib \
            --list /data/ddb/server/plugins/caplib/$library 2>&1)" || { printf '%s\n' "$output"; exit 1; }; \
        printf '%s\n' "$output"; \
        if printf '%s\n' "$output" | grep -q 'not found'; then exit 1; fi; \
    done
