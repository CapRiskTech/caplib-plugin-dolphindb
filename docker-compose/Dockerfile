FROM ubuntu:24.04 AS libstdc

FROM dolphindb/dolphindb:v3.00.5

USER root

# Caplib 插件的 libdqlibc.so 需要 GLIBCXX_3.4.32，而镜像自带的
# /data/ddb/server/libstdc++.so.6 (glibc 版) 仅到 GLIBCXX_3.4.25。
# 镜像内 /usr/lib 的 libstdc++ 是 musl 版，不兼容 glibc 的服务器。
# 这里从 ubuntu:24.04 复制一个 glibc 版 libstdc++ (含 3.4.32) 覆盖之。
COPY --from=libstdc /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /data/ddb/server/libstdc++.so.6
