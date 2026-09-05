ARG DDB_BASE_IMAGE=dolphindb/dolphindb:v3.00.5
FROM ${DDB_BASE_IMAGE}

USER root

# 挂载 0.0.11 GCC 8 兼容包，保留官方镜像的 libstdc++.so.6。
# 不再复制 Ubuntu/GCC 13 运行库；旧的 0.0.10 二进制不适用于此镜像。
