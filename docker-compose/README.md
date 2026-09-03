# Caplib DolphinDB Docker Compose

轻量的 Docker Compose 部署方案：基于**官方 DolphinDB 镜像** `dolphindb/dolphindb:v3.00.5`，
只修复 libstdc++ 兼容性问题，Caplib 插件通过**宿主机目录挂载**进容器，由 `dolphindb.dos`
在启动时自动加载。

与 `docker/`（`build.sh`）的区别：`docker/` 会下载 release 并把插件**打进镜像**（自包含）；
本目录只挂载插件，改动插件无需重新构建镜像，适合本地开发与快速接入。

## 目录结构

```
docker-compose/
├── README.md           ← 本文档
├── Dockerfile          # 修复 libstdc++（GLIBCXX_3.4.32）
├── docker-compose.yml  # 服务编排（端口、插件挂载、dolphindb.dos 挂载）
└── dolphindb.dos       # 启动时自动 loadPlugin
```

## 前置条件

- Docker + Docker Compose
- Caplib 插件文件（来自 `0.0.10` release 归档，下载地址：
  <https://github.com/CapRiskTech/caplib-plugin-dolphindb/releases>）：
  `libPluginCaplib.so`、`PluginCaplib.txt`、`libdqlibc.so`、`dqlibc.lic`、
  `data/calendars.bin`

## 快速开始

1. **编辑 `docker-compose.yml`**，把占位符 `这里写入插件位置` 替换成你本地插件目录的绝对路径：

   ```yaml
   volumes:
     - 这里写入插件位置:/data/ddb/server/plugins/caplib   # ← 改成下面的形式
   ```

   - Windows 示例：`D:\work\caplib:/data/ddb/server/plugins/caplib`
   - Linux 示例：`/home/user/caplib:/data/ddb/server/plugins/caplib`

2. **构建镜像**（Dockerfile 需要从 ubuntu:24.04 复制 libstdc++，需联网）：

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

## 为什么需要这个 Dockerfile（libstdc++ 修复）

Caplib 插件的 `libdqlibc.so` 依赖 **GLIBCXX_3.4.32**（GCC 13 编译），但：

- 官方镜像自带的 `/data/ddb/server/libstdc++.so.6` 仅到 **GLIBCXX_3.4.25**
- 镜像内 `/usr/lib` 的 libstdc++ 是 **musl 版**，与 glibc 的 DolphinDB 服务器不兼容

因此 Dockerfile 从 `ubuntu:24.04` 复制一个 glibc 版 `libstdc++.so.6`（含 3.4.32），
覆盖到 `/data/ddb/server/libstdc++.so.6`：

```dockerfile
COPY --from=libstdc /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /data/ddb/server/libstdc++.so.6
```

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
  仅改插件文件内容则无需重建（插件走挂载，热生效）。
- `dqlibc.lic` 需与 `libdqlibc.so` 放在同一目录（licensecc 同目录查找优先），挂载目录里必须包含它。
