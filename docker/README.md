# Caplib DolphinDB Docker（自包含镜像）

把 **官方 DolphinDB 镜像** + **libstdc++ 兼容修复** + **Caplib 插件** 打包成单个自包含镜像。
与 `docker-compose/` 用同一套机制，区别是这里**把插件打进镜像**（适合 CI / 独立部署），
而 `docker-compose/` 把插件从宿主机挂载（适合本地开发 / 插件热更新）。

## 目录结构

```
docker/
├── README.md           ← 本文档
├── Dockerfile          # 基于官方镜像 dolphindb/dolphindb:v3.00.5 + libstdc++ 修复 + 打入插件
├── build.sh            # 下载插件 release → 校验 → 组装小 context → docker build（Linux/macOS）
├── build.ps1 / build.bat  # 同上（Windows，无 Git Bash 时用）
└── dolphindb.dos       # 启动时自动 loadPlugin
```

## 前置条件

- Docker（Linux/macOS/Windows 均可）
- 网络：需拉取官方镜像（Docker Hub）+ 下载插件 release（GitHub，约 18MB）
- （Linux）bash；（Windows）可选 `build.bat`，无需 Git Bash、无需 python

## 快速开始

```bash
cd caplib-plugin-dolphindb

# Linux / macOS / Git Bash
bash docker/build.sh                  # 只构建
bash docker/build.sh --run            # 构建 + 启动容器
bash docker/build.sh --test           # 构建 + 启动 + 运行插件测试套件

# Windows（无需 Git Bash）
docker\build.bat --test
```

脚本自动完成：下载 `0.0.10` release（缓存复用）→ 解压 → 校验（202 个函数、必需 API）→
组装 build context → `docker build -t caplibdolphin:latest`。

`--test` 会启动容器并运行打包的测试套件 `test_plugin.dos`（`/data/ddb/test_plugin.dos`），
覆盖 7 项：loadPlugin、calcYearFraction、createIrYieldCurve、getObjectCacheJson、
createPricingModelSettings、createPricingSettings、createEqRiskSettings，期望 **7/7**。
需宿主机安装 `dolphindb` Python 包（`pip install dolphindb`）以连接 DDB 执行测试。

### 运行

```bash
docker run -d -p 8848:8848 --name caplibdolphin caplibdolphin:latest
docker logs -f caplibdolphin        # 应看到 "caplib plugin loaded: 202 functions registered"
```

### 连接

```python
import dolphindb as ddb

s = ddb.session()
s.connect("localhost", 8848, "admin", "123456")

r = s.run("caplib::calcYearFraction(2025.01.01, 2025.12.31, `ACTUAL_360)")
print(r)  # 1.011111
```

## 镜像内容

```
/data/ddb/server/              ← 官方镜像家目录
├── libstdc++.so.6             # 覆盖为 ubuntu:24.04 的 glibc 版（含 GLIBCXX_3.4.32）
├── dolphindb.dos              # 启动时自动 loadPlugin
└── plugins/caplib/
    ├── libPluginCaplib.so     # Caplib 插件（0.0.10）
    ├── PluginCaplib.txt
    ├── libdqlibc.so
    ├── dqlibc.lic
    └── data/calendars.bin
```

## 为什么这样设计（相比旧版 build.sh）

旧版自己下载 DolphinDB 发行包（129MB）、解压、扁平化、自写 entrypoint、装依赖，踩过
一堆坑（下载慢、apt-get 502、entrypoint CRLF 崩溃、构建上下文 500MB…）。

新版直接复用**官方 DolphinDB 镜像**（`docker-compose/` 已验证的方案），只做两件事：

1. **libstdc++ 修复**：Caplib 的 `libdqlibc.so` 需要 `GLIBCXX_3.4.32`，官方镜像自带的
   libstdc++ 只到 `3.4.25`，`/usr/lib` 下又是 musl 版（与 glibc 服务器不兼容）。
   从 `ubuntu:24.04` 复制一个 glibc 版覆盖。
2. **打入插件 + dolphindb.dos**：容器启动时 DDB 自动执行 `dolphindb.dos` 完成 `loadPlugin`。

没有 `apt-get`（不再撞 Ubuntu 502）、没有 129MB 下载、没有自写 entrypoint（不再有 CRLF 崩溃）。

## 与 docker-compose/ 的对比

| | `docker/`（本目录） | `docker-compose/` |
|---|---|---|
| 插件来源 | **打进镜像**（下载 release） | **宿主挂载** |
| 产物 | `caplibdolphin:latest` 自包含镜像 | `dolphindb-caplib:v3.00.5` + compose 服务 |
| libstdc++ 修复 | 相同 | 相同 |
| 插件加载 | 相同（dolphindb.dos） | 相同（dolphindb.dos） |
| 适用场景 | CI / 分发 / 无宿主依赖 | 本地开发 / 插件热更新 |

## 环境变量

| 变量 | 默认 | 说明 |
|---|---|---|
| `IMAGE_NAME` / `IMAGE_TAG` | `caplibdolphin` / `latest` | 镜像名 / 标签 |
| `CAPLIB_PLUGIN_TAG` | `0.0.10` | 插件 release 版本（改版本时同步改 `EXPECTED_PLUGIN_FUNCTIONS`） |
| `DDB_BASE_IMAGE` | `dolphindb/dolphindb:v3.00.5` | 基础镜像 |
| `GITHUB_TOKEN` | 无 | 私有仓库时需要（当前 release 是公开的，无需） |

## 常见问题

| 现象 | 原因 / 处理 |
|---|---|
| 构建后 `docker images` 看不到镜像 | 检查 `docker context ls` / `DOCKER_HOST` —— 构建和查询可能连了不同 daemon（尤其 WSL 与 Docker Desktop 分离） |
| 下载 `caplib-plugin-dolphindb-*.tar.gz` 很慢 / 卡住 | 脚本用 `curl --retry 5` + 断点续传，耐心等待或重跑；网络差可先手动 `curl -C -` 下好再重跑 |
| 插件没加载 | `docker logs caplibdolphin` 看是否报 `loadPlugin` 错误；确认镜像内 `plugins/caplib/` 文件齐全 |
| Windows checkout 后 dos/sh 变 CRLF | 仓库已配 `.gitattributes`（`*.sh`/`*.dos` 强制 LF）；build 脚本也会在进 context 前归一化 |
