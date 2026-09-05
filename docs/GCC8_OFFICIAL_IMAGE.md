# Caplib 0.0.11：官方 DolphinDB 镜像兼容升级

0.0.11 基于上游 `dqlibdolphin/release-caplib` 提交
`c0cb21d193e276624acbdeb7100196038b038eba`，同步参数校验修复和 GCC 8.4 / ABI0 构建。
发行包与 SHA-256 校验文件见 [0.0.11 GitHub Release](https://github.com/CapRiskTech/caplib-plugin-dolphindb/releases/tag/0.0.11)。

## 运行库要求

| 组件 | 最高 GLIBCXX | 最高 CXXABI |
| --- | --- | --- |
| libPluginCaplib.so | 3.4.20 | 1.3.9 |
| libdqlibc.so | 3.4.23 | 1.3.11 |
| 测试用官方 v3.00.5 镜像提供 | 3.4.25 | 1.3.11 |

包内最高 GLIBC 要求为 2.38，测试镜像为 glibc 2.39；目标为 Linux x86-64。
不承诺旧 glibc 系统、其他 DolphinDB 版本或其他 CPU 架构可直接加载。
ABI0 和 GLIBCXX 版本是两个独立要求，单独设置 ABI0 不能让 GCC 13 库兼容旧运行库。

两个动态库和所链接的 C++ 静态库均已用 GCC 8 重编译，包括 18 个 dqlib 核心库、
Boost、log4cplus、Protobuf、Abseil 和 licensecc；zlib 使用 PIC 静态构建，
OpenSSL 复用原有 C 静态库。构建过程保留许可证校验、公钥和原有业务逻辑。
包内许可证和日历数据的校验值与已发布的 0.0.10 一致。

上游在未替换运行库的 `dolphindb/dolphindb:v3.00.5` 上通过 408/408 项回归，
包括 133 项问题清单校验。镜像 digest：
`sha256:01b1607f0b255a22ace6d41a4c80717c47486886b8f2b5f508035835c379e58b`。
服务端原有 libstdc++ 的 SHA-256 始终为：
`5f0901ff6590cfb426d068d9b6efe969335cb30353c0d1c59787db34ddf09f6c`。

## 完整目录和加载

解压 `caplib-plugin-dolphindb-0.0.11.tar.gz`，将其完整目录安装或挂载到
`/data/ddb/server/plugins/caplib`：

```text
caplib/
  libPluginCaplib.so
  PluginCaplib.txt
  libdqlibc.so
  dqlibc.lic
  data/calendars.bin
  BUILD_INFO.json
  SHA256SUMS
```

停止服务后同时替换两个动态库，保留合法许可证及日历数据，再重启。
动态库已经加载后，不会因为挂载目录里的文件改变而自动重载。

```dolphindb
loadPlugin("/data/ddb/server/plugins/caplib/PluginCaplib.txt")
```

`docker/` 和 `docker-compose/` 都通过启动脚本显式加载插件。
它们不再复制或覆盖镜像的 libstdc++；旧 0.0.10 GCC 13 二进制不适用于这套镜像。

## 校验

在解压后的插件目录中校验文件：

```bash
sha256sum -c SHA256SUMS
```

从仓库根目录检查 GLIBCXX / CXXABI 上限：

```bash
cmake "-DLIBRARY_FILES=/path/caplib/libPluginCaplib.so;/path/caplib/libdqlibc.so" \
  -P cmake/CheckOfficialRuntime.cmake
```

CMake 检查仅覆盖数值型 GLIBCXX / CXXABI 要求；还应运行目标镜像测试。
`docker/Dockerfile` 会用官方镜像的 glibc 加载器检查两个动态库的依赖版本，
以便在构建阶段拒绝旧 GCC 13 包或混用的依赖。

已保留分发仓库最新的八个原生测试文件，并追加
`test/test_issues_regression.dos`：一个原生测试用例执行全部 133 项上游检查，
并断言检查数量。任一子检查失败都会让该用例失败。
完整定价测试使用 `maxMemSize=16`；2 GB 配额会导致 Monte Carlo 内存分配失败。

本次分发仓库验证结果：**379/379 原生用例通过**，其中新增回归用例内部
**133/133 检查通过**。新 Dockerfile 对 0.0.11 包构建成功，对已发布的
0.0.10 GCC 13 包在构建阶段拒绝；测试期间官方 libstdc++ 校验值未变。

```bash
python run_tests.py --container <测试容器> --port <映射端口>
```

源码构建说明见
[上游 GCC 8 构建记录](https://github.com/dqlab/dqlibdolphin/blob/c0cb21d/docs/GCC8_OFFICIAL_IMAGE.md)。
