# caplib-plugin-dolphindb

这是面向 **DolphinDB 用户** 的 Caplib 插件发布仓库。

仓库主要提供三类内容：

- GitHub Release：可直接下载的插件发布包
- `docs/`：静态文档站点与入口页
- `example/`：按业务场景整理的 DolphinDB 示例脚本

## 适合谁使用

如果你已经在使用 DolphinDB，希望快速接入 Caplib 定价与分析能力，这个仓库就是给你准备的。

你通常不需要关心插件的打包过程，也不需要自己拼接依赖文件。直接使用 Release 中的发布包即可。

## Release 内容

当前发布包 `0.0.8` 为一个完整压缩包，包含运行插件所需的核心文件：

- `libPluginCaplib.so`
- `PluginCaplib.txt`
- `libdqlibc.so`
- `data/calendars.bin`
- `dqlibc.lic`

如果你希望用 Docker 方式启动，可直接使用仓库中的 `docker/` 目录。

## 快速开始

### 方式一：直接使用发布包

1. 从 GitHub Release 下载 `caplib-plugin-dolphindb-0.0.8.tar.gz`
2. 解压到你的 DolphinDB 插件目录
3. 在 DolphinDB 中加载 `PluginCaplib.txt`

示例：

```dolphindb
loadPlugin("/path/to/PluginCaplib.txt")
caplib::CalcYearFraction(2025.01.01, 2025.12.31, `ACTUAL_360)
```

### 方式二：使用 Docker

如果你希望快速得到一个可运行环境，而不是手动处理插件、依赖库和 DolphinDB 服务端文件，推荐直接使用 `docker/README.md` 中的说明。

## 文档

仓库已附带静态文档：

- 中文入口：`docs/CAPLIB_PLUGIN.html`
- 英文站点：`docs/html/index.html`
- 中文站点：`docs/html/zh/index.html`

文档内容包括：

- 插件加载方式
- 常见函数说明
- 按资产类别整理的能力说明
- 使用示例

## 示例脚本

`example/` 目录提供了可直接参考的示例脚本，包括：

- 固收：`BondPricing.dos`、`FiAnalytics.dos`
- 利率：`IrAnalytics.dos`、`IrCurveBuilding.dos`
- 外汇：`FxAnalytics.dos`、`FxOptionPricing.dos`
- 权益：`EqAnalytics.dos`
- 商品：`CmAnalytics.dos`
- 信用：`CrAnalytics.dos`

这些脚本更适合作为接入模板使用：先按你的市场数据、曲线、日历和参数做替换，再接入生产流程。

## Docker 目录说明

`docker/` 目录面向希望一键启动环境的用户，负责自动准备：

- Caplib 插件发布包
- 内置 `dqlibc.lic`
- DolphinDB Server

如果你的目标是尽快启动并验证插件是否可用，直接看 `docker/README.md` 即可。
