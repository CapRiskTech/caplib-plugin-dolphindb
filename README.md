# DolphinDB Caplib 插件使用说明

Caplib 是面向 DolphinDB 用户的金融衍生品定价与风险分析插件。插件通过 CapRiskTech 提供的 `dqlibc` 计算库，覆盖固定收益（Fixed Income，FI）、利率（Interest Rate，IR）、外汇（Foreign Exchange，FX）、权益（Equity，EQ）、商品（Commodity，CM）和信用（Credit，CR）等资产类别，可用于曲线构建、市场数据组装、金融工具创建、定价和风险分析。

当前发行版本为 `0.0.10`，基于 `dqlibdolphin` 的 `release-caplib`
提交 `2867f08` 构建，提供 202 个对外接口。完整文档入口：

- [完整中文使用说明](docs/DQLIB_DOCUMENTATION.md)
- [中文文档](docs/html/zh/index.html)
- [English documentation](docs/html/index.html)
- [文档语言入口](docs/index.html)

## 功能说明

| 领域 | 主要能力 |
| --- | --- |
| 固定收益与信用 | 债券、信用违约互换（CDS）定价；到期收益率、Z-spread、转换因子、隐含回购利率计算；收益率曲线和信用曲线构建 |
| 利率 | 单币种与跨币种曲线构建；存款、远期利率协议、互换、跨币种互换、Cap/Floor 和 Swaption 定价 |
| 外汇 | 即期、远期、掉期、NDF 和外汇期权定价；远期汇率、掉期点和波动率曲面计算 |
| 权益 | 欧式、美式、亚式、数字、障碍、触碰、雪球等期权定价；股息曲线和波动率曲面构建 |
| 商品 | 商品及贵金属曲线、波动率曲面和期权定价 |
| 市场风险 | 历史模拟、风险价值（VaR）、预期损失（ES）、敏感度转换和情景分析 |

## 第三方库说明

本插件依赖 CapRiskTech 提供的 `dqlibc` 库。`dqlibc` 负责底层金融计算、protobuf 数据处理和许可证校验；插件负责 DolphinDB 数据类型转换、内存对象管理和函数注册。

`dqlibc` 为专有软件。使用前必须准备有效的 `dqlibc.lic`，并遵守其许可证条款。许可证格式要求 `lic_ver = 200`，申请方式见 [License 说明](#license-说明)。

## 安装插件

### 版本要求

| 组件 | 要求 |
| --- | --- |
| DolphinDB Server | 3.00.5 或更高版本；插件描述文件中的版本必须与 Server 版本一致 |
| 操作系统 | Linux x86-64（CentOS/RHEL 9 或 Ubuntu 22.04 及兼容发行版） |
| 运行时 ABI | `_GLIBCXX_USE_CXX11_ABI=0`（ABI0） |
| 许可证 | 有效的 `dqlibc.lic` |

### 通过插件市场安装

先执行 `listRemotePlugins()`，确认结果中包含 `caplib`。若存在，可直接安装并加载：

```dolphindb
login("admin", "123456")

listRemotePlugins()
installPlugin("caplib")
loadPlugin("caplib")
```

如果远程插件列表中没有 `caplib`，请使用预编译发行包。

### 使用预编译发行包安装

1. 从本仓库的 GitHub Releases 下载
   `caplib-plugin-dolphindb-0.0.10.tar.gz`。
2. 将下列文件放在同一插件目录中，并保留 `data` 子目录：

   ```text
   caplib/
   ├── libPluginCaplib.so
   ├── PluginCaplib.txt
   ├── libdqlibc.so
   ├── dqlibc.lic
   └── data/
       └── calendars.bin
   ```

3. 加载生成后的插件描述文件：

   ```dolphindb
   loadPlugin("/your/path/to/caplib/PluginCaplib.txt")
   ```

> `PluginCaplib.txt` 是 CMake 生成物。请使用发行包内已经配置好的文件，
> 不要使用 `dqlibdolphin` 源码仓库中的 CMake 模板。

## 核心概念

插件对外函数统一使用 lowerCamelCase，例如 `caplib::calcYearFraction`。`PluginCaplib.txt` 第一列保留 PascalCase C++ 实现符号，第二列记录 lowerCamelCase 外部名称。


### 工厂函数与内存对象

`create*` 和 `build*` 工厂函数创建曲线、报价、模板、设置、市场数据或金融工具，并将对象写入内存对象缓存（ObjectCache）。调用方通过返回的 STRING 句柄引用对象，不需要反复传递序列化数据。

工厂函数通常把 `returnJson` 作为最后一个可选参数：

- 省略或设为 `false`：返回对象句柄。
- 设为 `true`：返回 `[handle, protobufJson]`，便于检查对象内容。

### 统一定价参数

原生定价函数使用一致的七个必填参数，并可追加 `returnJson`：

| 位置 | 参数 | 类型 | 含义 |
| --- | --- | --- | --- |
| 1 | `instrumentHandle` | STRING | 金融工具句柄 |
| 2 | `pricingDate` | DATE | 定价日 |
| 3 | `mktDataHandle` | STRING | 市场数据句柄 |
| 4 | `pricingSettingsHandle` | STRING | 定价设置句柄 |
| 5 | `riskSettingsHandle` | STRING | 风险设置句柄 |
| 6 | `scnSettingsHandle` | STRING | 情景设置句柄；不使用时传空字符串 |
| 7 | `mode` | STRING | 定价模式；使用默认值时传空字符串 |
| 8 | `returnJson` | BOOL，可选 | 是否同时返回 protobuf JSON；默认 `false` |

### 参数命名约定

- `asOfDate` 或 `referenceDate`：曲线、报价或市场数据的基准日。
- `pricingDate`：执行估值的日期。
- `calculationDate`：执行独立计算器函数的日期。
- `handle`：新建对象在 ObjectCache 中的唯一名称。
- `*Handle`：由前序工厂函数返回、且 protobuf 类型必须匹配的对象句柄。

语法使用方括号表示可选参数，如 `[, returnJson BOOL]`；其余参数均为必填参数。

## 数据类型转换

| DolphinDB 类型 | Caplib 含义或转换规则 |
| --- | --- |
| DATE | 转为 `dqlibc` 日期序号；日期向量必须使用 DATE 或接口明确允许的 INT 向量 |
| STRING | 枚举名、币种、期限、对象名称或 ObjectCache 句柄；枚举值以参数表为准 |
| DOUBLE | 利率、价格、波动率、名义本金或风险扰动；除接口另有说明外必须为有限值 |
| BOOL | 开关或 `returnJson` 标志 |
| 向量和矩阵 | 元素类型、长度、形状和配对关系以参数表为准 |
| protobuf 字节串 | 仅用于少量序列化接口；普通工作流优先使用原生类型和句柄接口 |

服务返回失败状态、参数校验失败、句柄类型不匹配、解析失败或序列化失败时，插件会抛出 DolphinDB `RuntimeException`，不会返回部分结果或备用值。

## 接口说明

接口按功能分类。每个接口均包含“语法、详情、参数、返回值、示例”，参数表给出类型、可选值、有效范围和跨参数约束。

| 分类 | 接口数 | 中文 | English |
| --- | ---: | --- | --- |
| 通用函数与共享设置 | 29 | [查看](docs/html/zh/shared.html#api-reference) | [View](docs/html/shared.html#api-reference) |
| 固定收益、利率与信用 | 73 | [查看](docs/html/zh/fixed-income.html#api-reference) | [View](docs/html/fixed-income.html#api-reference) |
| 外汇 | 39 | [查看](docs/html/zh/currency.html#api-reference) | [View](docs/html/currency.html#api-reference) |
| 商品 | 25 | [查看](docs/html/zh/commodity.html#api-reference) | [View](docs/html/commodity.html#api-reference) |
| 权益 | 36 | [查看](docs/html/zh/equity.html#api-reference) | [View](docs/html/equity.html#api-reference) |

### 接口格式示例：`calcYearFraction`

#### 语法

```dolphindb
caplib::calcYearFraction(startDate, endDate, dayCountConvention)
```

#### 详情

计算两个日期之间的年分数（Year Fraction）。

#### 参数

- `startDate`：DATE，必填。起始日期。
- `endDate`：DATE，必填。结束日期，不能早于 `startDate`。
- `dayCountConvention`：STRING，必填。日计数惯例，例如 `"ACTUAL_360"`、`"ACT_365_FIXED"`、`"ACT_ACT_ISDA"` 或 `"THIRTY_360"`。

#### 返回值

返回 DOUBLE 类型的年分数；失败时抛出异常。

#### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::calcYearFraction(
    2025.01.01, 2025.12.31, "ACTUAL_360")
print(result)
// output: 1.011111
```

## 使用示例

以下示例展示“加载插件 → 创建曲线和金融工具 → 创建设置 → 组装市场数据 → 债券定价 → 输出结果”的完整流程。可直接运行的完整脚本见 [`example/FiAnalytics.dos`](example/FiAnalytics.dos)。

```dolphindb
loadPlugin("PluginCaplib")

asOfDate = 2021.07.22
currency = "CNY"

discountCurve = caplib::createIrYieldCurve(
    asOfDate,
    [2021.08.22, 2022.07.22, 2023.07.22, 2024.07.22],
    [0.02, 0.022, 0.024, 0.026],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_TREAS", "FI_IR_CURVE", false)

spreadCurve = caplib::createCreditCurve(
    asOfDate,
    [2021.08.22, 2022.07.22, 2023.07.22, 2024.07.22],
    [0.0010, 0.0012, 0.0014, 0.0016],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CNY_MTN_AAA", "FI_CREDIT_CURVE", false)

bondLeg = caplib::createBondLegDefinition(
    "FIXED_COUPON_BOND", 1, currency, "ACT_365_FIXED", "CAL_CFETS",
    "ANNUAL", "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "", "", "ANNUAL",
    "MODIFIED_FOLLOWING", "IN_ADVANCE", -1, "FI_BOND_LEG", false)

bondTemplate = caplib::createVanillaBondTemplate(
    "CNY_TREAS_CPN_BOND", "FIXED_COUPON_BOND",
    2020.07.22, 1, 2020.07.22, "5Y",
    0.03, 100.0, 0.4, bondLeg, false)
vanillaBond = caplib::buildVanillaBond(
    1000000.0, bondTemplate, "", 2020.07.22, "FI_VANILLA_BOND", false)

pricingModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", "", 0, [0.0], "FI_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 1, 1, pricingModel, "", "", "FI_PRICING", false)

irRisk = caplib::createIrCurveRiskSettings(
    1, 1, 1, 1.0e-4, 5.0e-3, 0, 1, 1.0e-4, 0, "FI_IR_RISK", false)
creditRisk = caplib::createCreditCurveRiskSettings(
    1, 1, 1.0e-4, 0, 1, 1.0e-4, 0, "FI_CREDIT_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(
    1, 1, 1.0 / 365.0, "FI_THETA_RISK", false)
fiRisk = caplib::createFiRiskSettings(
    irRisk, creditRisk, thetaRisk, "FI_RISK_NAME", "FI_RISK", true)

fiMktData = caplib::createFiMktDataSet(
    asOfDate, discountCurve, spreadCurve, "", "", "",
    "FI_MKT_NAME", "FI_MKT", true)

result = caplib::priceVanillaBond(
    vanillaBond, asOfDate, fiMktData[0],
    pricingSettings, fiRisk[0], "", "", true)
print(result)
```

## 附录

### Docker 部署

Docker 镜像构建、目录布局、启动、健康检查和故障排查见 [`docker/README.md`](docker/README.md)。

```bash
bash docker/build.sh --test
```

### 编译说明

源码编译需要 DolphinDB Plugin SDK、ABI0 版本 `dqlibc`、Boost 和 log4cplus，以及 CMake 3.22+、GCC 9+ 和 Protobuf。完整说明见 [`BUILD_REQUIREMENTS.md`](BUILD_REQUIREMENTS.md)。

### License 说明

请通过 [caprisktech.com](https://caprisktech.com) 申请许可证。`dqlibc.lic` 可放在：

1. `~/.dqlib/dqlibc.lic`
2. 与 `libdqlibc.so` 相同的目录
3. `/etc/dqlib/dqlibc.lic`

插件在服务调用前校验许可证，并缓存结果 3600 秒。

### 常见问题

| 现象 | 原因 | 处理方式 |
| --- | --- | --- |
| `Invalid plugin file` | 使用了带 CMake 变量的源模板，或描述文件版本不匹配 | 使用本仓库发行包内的 `PluginCaplib.txt`，并确保版本匹配 |
| `GLIBCXX_* not found` | DolphinDB 自带的 `libstdc++.so.6` 过旧 | 使用匹配的运行环境；Docker 方案见 `docker/README.md` |
| `LICENSE_FILE_NOT_FOUND` | 未找到 `dqlibc.lic` | 将许可证放到上述三个位置之一 |
| 句柄类型错误 | 对象句柄的 protobuf 类型与参数要求不符 | 检查逐接口参数表中 `*Handle` 的来源和类型 |
| 函数抛出异常 | 服务失败或插件参数校验失败 | 查看异常消息；插件不会返回部分结果 |

### 缩写与术语

| 缩写 | 全称 | 中文含义 |
| --- | --- | --- |
| FI | Fixed Income | 固定收益 |
| IR | Interest Rate | 利率 |
| FX | Foreign Exchange | 外汇 |
| EQ | Equity | 权益 |
| CM | Commodity | 商品 |
| CR | Credit | 信用 |
| PM | Precious Metal | 贵金属 |
| CDS | Credit Default Swap | 信用违约互换 |
| NDF | Non-Deliverable Forward | 无本金交割远期外汇 |
| MTM | Mark to Market | 按市值计价 |
| VaR | Value at Risk | 风险价值 |
| ES | Expected Shortfall | 预期损失 |
