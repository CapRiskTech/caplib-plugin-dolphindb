# Caplib DolphinDB Docker Compose

轻量的 Docker Compose 部署方案：基于**官方 DolphinDB 镜像** `dolphindb/dolphindb:v3.00.5`，
保留镜像自带的 libstdc++，将 0.0.11 GCC 8 插件通过**宿主机目录挂载**进容器，由 `dolphindb.dos`
在启动时自动加载。

与 `docker/`（`build.sh`）的区别：`docker/` 会下载 release 并把插件**打进镜像**（自包含）；
本目录只挂载插件，更新插件文件后需要重启服务，但无需重新构建镜像。

## 目录结构

```
docker-compose/
├── README.md           ← 本文档
├── Dockerfile          # 保留官方镜像及原有 libstdc++
├── docker-compose.yml  # 服务编排（端口、插件挂载、dolphindb.dos 挂载）
└── dolphindb.dos       # 启动时自动 loadPlugin
```

## 前置条件

- Docker + Docker Compose
- Caplib 插件文件（来自 `0.0.11` 发行包，下载地址：
  <https://github.com/CapRiskTech/caplib-plugin-dolphindb/releases>）：
  `libPluginCaplib.so`、`PluginCaplib.txt`、`libdqlibc.so`、`dqlibc.lic`、
  `data/calendars.bin`

## 快速开始

1. **设置 `CAPLIB_PLUGIN_DIR`** 为完整 0.0.11 插件目录的绝对路径：

   ```bash
   export CAPLIB_PLUGIN_DIR=/home/user/caplib
   ```

   Windows PowerShell 示例：`$env:CAPLIB_PLUGIN_DIR = 'D:\work\caplib'`。
   插件以只读方式挂载到 `/data/ddb/server/plugins/caplib`。

2. **构建镜像**（仅复用官方镜像，不再拉取 Ubuntu 或复制运行库）：

   ```bash
   docker compose build
   ```

3. **启动**：

   ```bash
   docker compose up -d
   ```

4. **查看日志**（确认插件已加载）：

   ```bash
   docker compose logs -f dolphindb
   # 应能看到 loadPlugin 相关的 regist: 输出，无报错
   ```

5. **停止 / 移除**：

   ```bash
   docker compose down
   ```

## C++ 运行库兼容性

旧 0.0.10 的 `libdqlibc.so` 要求 **GLIBCXX_3.4.32**（GCC 13），不适用于
保留原运行库的镜像。0.0.11 同时重编译了两个动态库和全部 C++ 依赖：

- 插件最高要求 **GLIBCXX_3.4.20 / CXXABI_1.3.9**。
- libdqlibc 最高要求 **GLIBCXX_3.4.23 / CXXABI_1.3.11**。
- 官方 v3.00.5 镜像提供 **GLIBCXX_3.4.25 / CXXABI_1.3.11**，glibc 2.39。

无需覆盖服务器的 `libstdc++.so.6`，也不能使用镜像内 musl 版 C++ 运行库替代。
完整信息见 [官方镜像升级说明](../docs/GCC8_OFFICIAL_IMAGE.md)。

## 关键配置

| 项 | 说明 |
|---|---|
| 镜像 | `dolphindb-caplib:v3.00.5`（由本目录 Dockerfile 本地构建） |
| 端口 `8848` | DolphinDB 客户端连接 |
| 端口 `8900` | Web / 集群端口 |
| 插件挂载 | `<宿主机插件目录>:/data/ddb/server/plugins/caplib` |
| `dolphindb.dos` | 挂载到 DDB 家目录，启动时自动执行 `loadPlugin` |
| `restart` | `unless-stopped`，容器异常退出自动重启 |

## 连接

```python
import dolphindb as ddb

s = ddb.session()
s.connect("localhost", 8848, "admin", "123456")

r = s.run("caplib::calcYearFraction(2025.01.01, 2025.12.31, `ACTUAL_360)")
print(r)  # 1.011111
```

插件已由 `dolphindb.dos` 自动加载；如需手动加载：

```python
s.run('loadPlugin("/data/ddb/server/plugins/caplib/PluginCaplib.txt")')
```

## 注意事项

- 插件目录保持放在 `plugins/caplib/` **子目录**，不要直接散在 `<home>/plugins/` 根下，
  以避免 DDB 启动时自动扫描插件目录因加载失败而静默退出（code 255）。
- 修改 `docker-compose.yml` 或 `Dockerfile` 后需重新 `docker compose build`；
  仅改插件文件内容则无需重建，但必须停止服务后替换两个动态库，再重启加载；不支持热重载。
- `dqlibc.lic` 需与 `libdqlibc.so` 放在同一目录（licensecc 同目录查找优先），挂载目录里必须包含它。
