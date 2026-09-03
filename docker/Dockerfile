# ─────────────────────────────────────────────────────────────
# caplib DolphinDB Docker Image (self-contained)
# Built on top of the official DolphinDB image; only fixes libstdc++
# and bakes in the Caplib plugin. Same mechanism as docker-compose/,
# but the plugin is copied into the image instead of host-mounted.
#
# Usage (assembled by build.sh):
#   docker build -t caplibdolphin:latest .
#   docker run -d -p 8848:8848 --name caplibdolphin caplibdolphin:latest
# ─────────────────────────────────────────────────────────────

FROM ubuntu:24.04 AS libstdc

FROM dolphindb/dolphindb:v3.00.5

USER root

ARG CAPLIB_PLUGIN_TAG=unknown
LABEL org.caprisktech.caplib.release="$CAPLIB_PLUGIN_TAG"

# Caplib's libdqlibc.so requires GLIBCXX_3.4.32 (GCC 13). The official image's
# /data/ddb/server/libstdc++.so.6 only reaches GLIBCXX_3.4.25 and its /usr/lib
# copy is musl (incompatible with the glibc server), so copy a glibc one in.
COPY --from=libstdc /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /data/ddb/server/libstdc++.so.6

# Bake in the Caplib plugin (from the 0.0.10 release, assembled by build.sh).
# Same layout as docker-compose/, so dolphindb.dos finds it at startup.
COPY libPluginCaplib.so /data/ddb/server/plugins/caplib/
COPY PluginCaplib.txt   /data/ddb/server/plugins/caplib/
COPY libdqlibc.so       /data/ddb/server/plugins/caplib/
COPY dqlibc.lic         /data/ddb/server/plugins/caplib/
COPY calendars.bin      /data/ddb/server/plugins/caplib/data/
COPY dolphindb.dos      /data/ddb/server/dolphindb.dos
COPY test_plugin.dos    /data/ddb/test_plugin.dos
