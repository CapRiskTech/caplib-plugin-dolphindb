# DolphinDB Caplib 插件使用说明

Caplib 是面向金融衍生品定价与风险分析的 DolphinDB 插件。插件通过 CapRiskTech 提供的底层计算库 `dqlibc`，覆盖固定收益、利率、外汇、权益、商品和信用等资产类别，提供曲线构建、市场数据组装、金融工具创建、定价、风险分析与情景分析能力。

## 功能说明

| 资产类别 | 主要能力 |
| --- | --- |
| 固定收益（Fixed Income，FI） | 债券定价、到期收益率与应计利息、久期、凸性等债券指标计算、债券收益率曲线与信用利差曲线构建 |
| 利率（Interest Rate，IR） | 单币种与跨币种曲线构建与定价、互换工具模板、利率腿/日程/IBOR 指数定义 |
| 外汇（Foreign Exchange，FX） | 即期、远期、掉期、NDF、外汇期权和波动率曲面 |
| 权益（Equity，EQ） | 股息曲线、波动率曲面及欧式、美式、亚式、障碍、雪球等期权定价 |
| 商品（Commodity，CM） | 商品曲线、市场数据、波动率曲面和期权定价 |
| 贵金属（Precious Metal，PM） | 贵金属收益率曲线、市场数据、波动率曲面和期权定价 |
| 信用（Credit，CR） | 信用曲线、信用违约互换（CDS）定价和信用风险设置 |
| 市场风险 | 历史模拟曲线/即期情景生成、VaR、期望损失（ES） |

## 第三方库说明

本插件依赖 CapRiskTech 提供的专有 `dqlibc` 库。`dqlibc` 负责底层金融计算、protobuf 数据处理和许可证校验；Caplib 插件负责 DolphinDB 数据类型转换、ObjectCache 对象缓存管理和接口注册。

使用前必须准备有效的 `dqlibc.lic`。许可证文件格式要求 `lic_ver = 200`，并应放在 `~/.dqlib/dqlibc.lic`、`/etc/dqlib/dqlibc.lic` 或 `libdqlibc.so` 所在目录。

## 版本与发行说明

当前市场版本：**`3.00.5.2`**（适配 DolphinDB Server `3.00.5`）。本插件为**开源 + 免费**（`openSource/isFree/isFreeForCommercial` 均 `true`，见 [License 说明](#license-说明)），随包附带通用的 `dqlibc.lic`。

### 3.00.5.2

- 输出句柄参数的错误信息统一使用 `handle`，184 个对外接口的位置参数和业务语义不变。
- 按第三轮 review 完善 103 个测试文件，补充日期、形状、边界和枚举覆盖，修正无效隔离、重复用例和恒真断言。
- 全文统一接口语法、逐参数说明和返回值格式，补充 ObjectCache 核心概念，清理内部日志式说明，并修正外汇与市场风险页面及文档链接。

### 3.00.5.1（市场首发）

- **新功能**
  - 实现并导出 `pluginInfo` 元数据接口（返回 `pluginName / openSource / repositoryUrl / isFree / isFreeForCommercial / pluginVersion / serverVersion / architecture / platform / feature` 字典），由 Server 在 `loadPlugin` 时自动注册，适配 DolphinDB 插件市场接入规范（本插件为开源 + 免费）。
- **功能优化**
  - 全部日志与异常消息统一加 `[PLUGIN::CAPLIB] ` 前缀，便于定位与运维排查。
  - 版本号命名改为跟随 Server 的 `3.00.5.X` 方案；后续补丁递增第五段（如 `3.00.5.1.1`）。
- **故障修复**
  - （本版无既有发行期缺陷修复项。）
- **兼容性**
  - 兼容 Server `3.00.5`（Linux x86-64 / ABI0），构建链为 GCC 8.4，最高要求 `GLIBCXX_3.4.23` / `CXXABI_1.3.11`。
  - 保持既有 184 个对外接口的签名与语义不变。

### 0.0.15（源码构建基线，已并入 3.00.5.1）

- **兼容性（破坏性）**
  - `createPricingSettings` 自 0.0.13 起仅接受 9 个必填参数 + 可选 *returnJson*；不含 *specificPricingRequests* 的旧形式不再接受。
  - 移除 `buildHistSimIrYieldCurve`、`buildHistSimCreditCurve` 两个市场风险接口（接口数 186 → 184）。
- **返回值变更**
  - `calcVaR` / `calcExpectedShortfall` 返回值由 DOUBLE 标量改为字典（`value_at_risk` / `expected_shortfall` 及对应 `_mirrored` 键）。
- **兼容性（非破坏）**
  - 波动率翼部行权价枚举拼写修正 `ABOSULTE_STRIKE` → `ABSOLUTE_STRIKE`（旧拼写仍被识别）。

> 更早版本（0.0.11 及以前）的变更记录见各对应 GitHub Release 发行说明。

## 安装插件

### 版本要求

| 组件 | 要求 |
| --- | --- |
| DolphinDB Server | 3.00.5 或更高版本；插件描述文件版本必须与 Server 版本一致 |
| 操作系统 | Linux x86-64 |
| C++ ABI | `_GLIBCXX_USE_CXX11_ABI=0`（ABI0） |
| License | 有效的 `dqlibc.lic` |

### 安装步骤

先执行以下脚本检查远程插件仓库中是否包含 Caplib：

```dolphindb
login("admin", "123456")
listRemotePlugins()
```

若返回结果中包含 `caplib`，使用插件市场安装并加载：

```dolphindb
installPlugin("caplib")
loadPlugin("caplib")
```

若远程仓库中没有 Caplib，使用预编译发行包。目录结构必须为：

```text
caplib/
├── libPluginCaplib.so
├── PluginCaplib.txt
├── libdqlibc.so
├── dqlibc.lic
└── data/
    └── calendars.bin
```

将上述 `caplib/` 目录置于 Server 的 `plugins` 目录（如 `/data/ddb/server/plugins/caplib/`）后加载插件：

```dolphindb
loadPlugin("caplib")
go
```

> 请使用发行包内已配置的 `PluginCaplib.txt`（源码构建时为 `build/PluginCaplib.txt`）；不要部署含 CMake 变量的模板。

加载成功后，可调用 `caplib::pluginInfo()` 核对插件元数据（版本、开源/免费标志、适配 Server、feature 标签等）：

```dolphindb
caplib::pluginInfo()
// 预期返回（字典）：
//   pluginName -> "caplib", openSource -> true, isFree -> true,
//   isFreeForCommercial -> true, pluginVersion -> "3.00.5.2",
//   serverVersion -> "3.00.5", architecture -> "x86",
//   platform -> "Linux", feature -> "ABI", repositoryUrl -> "..."
```

## 核心概念

插件对外函数统一使用 lowerCamelCase，例如 `caplib::calcYearFraction`。`PluginCaplib.txt` 第一列保留 PascalCase C++ 实现符号，第二列记录 lowerCamelCase 外部名称。


### ObjectCache 对象缓存

ObjectCache 是插件在 DolphinDB Server 进程内维护的对象缓存，用于保存曲线、模板、市场数据、金融工具和设置等 protobuf 对象。它不是 DolphinDB 数据库表，也不是持久化对象；Server 或插件进程重启后，缓存对象需要重新创建。

`create*` 和 `build*` 函数将对象写入缓存，并返回 STRING 类型的缓存键（文档统称“句柄”）。后续接口通过该键读取对象；键不存在或对象的 protobuf 类型与参数要求不匹配时抛出异常。相同键再次写入会替换对应缓存对象，因此连续调用应使用有区分度的键。

`returnJson=false` 时仅返回句柄；`returnJson=true` 时返回 `[handle, protobufJson]`，便于检查对象内容。`getObjectCacheJson` 也可按对象类型和句柄读取 JSON。

### 工厂函数与 ObjectCache

`create*` 和 `build*` 工厂函数创建曲线、报价、模板、设置、市场数据或金融工具，并将对象写入 ObjectCache。函数返回 STRING 句柄，后续构建与定价接口通过句柄引用对象。

### 句柄和 `returnJson`

大多数工厂与定价接口支持最后一个可选参数 *returnJson*：

- 省略或传入 `false`：只返回对象句柄。
- 传入 `true`：返回 `[handle, protobufJson]`。

### 定价接口的统一参数

`instrumentHandle` STRING 类型。金融工具句柄。

`asOfDate` DATE 类型。定价日。

`mktDataHandle` STRING 类型。市场数据句柄。

`pricingSettingsHandle` STRING 类型。定价设置句柄。

`riskSettingsHandle` STRING 类型。风险设置句柄。

`scnSettingsHandle` STRING 类型。情景设置句柄；不使用时传空字符串。

`mode` STRING 类型。定价模式；使用默认模式时传空字符串。

`returnJson` BOOL 类型，可选。是否同时返回 JSON，默认 `false`。

### 必填参数与可选参数

接口语法中的方括号表示可选参数，例如 `[, returnJson]`。未放在方括号中的参数均为必填参数。参数表同时给出数据类型、形状、可选值、默认行为和有效性约束。

### 日期术语

asOfDate DATE 类型。基准日或估值日，具体业务含义见各接口参数说明。

## 数据类型转换

| DolphinDB 类型 | 转换规则 |
| --- | --- |
| DATE | 转换为 `dqlibc` 使用的日期序号；日期向量使用 DATE 或接口明确允许的 INT |
| STRING | 枚举、币种、期限、对象名称、protobuf 字节串或 ObjectCache 句柄 |
| DOUBLE | 利率、价格、波动率、本金或风险扰动；除接口另有说明外必须为有限值 |
| BOOL | 功能开关或 `returnJson` 标志 |
| VECTOR / MATRIX | 元素类型、形状、排序和配对长度以参数表为准 |

参数校验、句柄类型、解析、序列化或底层服务失败时，插件抛出 DolphinDB `RuntimeException`，不会返回部分结果。

## 接口说明

> 以下示例均显式加载插件。若多个接口在同一会话中连续调用，只需执行一次 `loadPlugin`。示例中使用变量名时，变量类型与取值约束见对应参数表。

### 通用

#### calcYearFraction

语法

```dolphindb
caplib::calcYearFraction(startDate, endDate, dayCountConvention)
```

详情

通过 CAPLIB 日期服务应用所选计息惯例，计算 startDate 到 endDate 的应计年化比例。

参数

startDate DATE 类型。起始日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

endDate DATE 类型。结束日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

dayCountConvention STRING 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。

返回值

计算结果，DOUBLE 类型标量。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::calcYearFraction(2025.01.01, 2025.12.31, "ACTUAL_360")
```

#### createCalendar

语法

```dolphindb
caplib::createCalendar(calName[, holidays[, specialBusinessDays]])
```

详情

根据名称、假日和特殊工作日构造 Calendar，将其序列化为 CalendarList 静态数据并注册到 CAPLIB。

参数

calName STRING 类型。日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

holidays DATE 或 INT 向量 类型。节假日日期数组。**有效性:** 默认为 空（即不提供节假日）；显式提供时必须是非空且不含空值的 DATE/INT 向量。与特殊工作日向量的长度互相独立；包装器不检查排序或日期先后关系。

specialBusinessDays DATE 或 INT 向量 类型。特殊工作日日期数组。**有效性:** 默认为 空向量（即不提供特殊工作日）；非空时必须是不含空值的 DATE/INT 向量。包装器不检查排序或日期先后关系。

返回值

创建或注册成功时返回 `true`，BOOL 类型标量；失败时抛出异常，不返回 `false`。

**示例**

```dolphindb
loadPlugin("caplib")

holidays = [2025.01.01, 2025.01.29]
specialBusinessDays = [2025.01.25]
caplib::createCalendar("CAL_CFETS", holidays, specialBusinessDays)
```
#### getObjectCacheJson

语法

```dolphindb
caplib::getObjectCacheJson(protobufType, handle)
```

详情

按具体 protobuf 类和句柄从 ObjectCache 获取对象，序列化为 protobuf JSON，并一起返回句柄与 JSON 文本。

参数

protobufType STRING 类型。protobuf 类型标签。**有效性:** 可接受值：`IrYieldCurve`, `AssetYieldCurve`, `Curve`, `CreditCurve`, `DividendCurve`, `VolatilityCurve`, `VolatilitySmile`, `VolatilitySurface`, `OptionQuoteMatrix`, `VolatilitySurfaceDefinition`, `VolatilitySurfaceBuildSettings`, `PricingModelSettings`, `PdeSettings`, `MonteCarloSettings`, `PricingSettings`, `IrCurveRiskSettings`, `CreditCurveRiskSettings`, `DividendCurveRiskSettings`, `PriceRiskSettings`, `VolRiskSettings`, `PriceVolRiskSettings`, `ThetaRiskSettings`, `ScnSettings`, `ScnAnalysisSettings`, `EqMktDataSet`, `EqRiskSettings`, `PricingResults`, `FxSpotRate`, `EuropeanOption`, `AmericanOption`, `DigitalOption`, `AsianOption`, `OneTouchOption`, `DoubleTouchOption`, `SingleBarrierOption`, `DoubleBarrierOption`, `CollarOption`, `SingleSharkFinOption`, `DoubleSharkFinOption`, `RangeAccrualOption`, `AirbagOption`, `PingPongOption`, `PhoenixAutoCallableNote`, `SnowballAutoCallableNote`, `dqproto.IrYieldCurve`。区分大小写。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

返回值

两元素 STRING 向量 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::getObjectCacheJson("PricingResults", "EO_INST_results")
```

#### createDividendCurve

语法

```dolphindb
caplib::createDividendCurve(asOfDate, pillarDates, pillarValues, yieldStartDate, dividendType, dayCountConvention, interp, extrap, compounding, name, handle[, returnJson])
```

详情

创建并缓存股息或远期收益曲线。函数验证并转换字段，构造 `DividendCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

pillarDates DATE 向量 类型。曲线节点日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

pillarValues DOUBLE 向量 类型。曲线节点值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

yieldStartDate DATE 类型。日期或日期数组。**有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。

dividendType STRING 类型。股息曲线类型。**有效性:** 可接受值：`CONTINUOUS`, `DISCRETE`。区分大小写。

dayCountConvention STRING 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。

interp STRING 类型。插值方法。**有效性:** 可接受值：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。仅接受所示精确拼写。

extrap STRING 类型。外推方法。**有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。

compounding STRING 类型。复利约定。**有效性:** 可接受值：`CONTINUOUS_COMPOUNDING`, `DISCRETE_COMPOUNDING`, `SIMPLE_COMPOUNDING`。仅接受所示精确拼写。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 DividendCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
caplib::createDividendCurve(
    asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "DIVIDEND_CURVE_50ETF", "EQ_DIV_CURVE", false)
```

#### createVolatilityCurve

语法

```dolphindb
caplib::createVolatilityCurve(asOfDate, pillarDates, vols, dayCountConvention, interp, extrap, underlying, handle[, returnJson])
```

详情

创建并缓存一维波动率曲线。函数验证并转换字段，构造 `VolatilityCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

pillarDates DATE 向量 类型。曲线节点日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

vols DOUBLE 向量 类型。波动率节点值数组。**有效性:** 必须具有所列元素类型和形状；数值必须非负且有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

dayCountConvention STRING 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。

interp STRING 类型。插值方法。**有效性:** 可接受值：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。仅接受所示精确拼写。

extrap STRING 类型。外推方法。**有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolatilityCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2022.03.09
pillarDates = [2022.03.10, 2025.03.10]
caplib::createVolatilityCurve(
    asOfDate, pillarDates, [0.20, 0.21],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "AN_UNDERLYING", "AN_VOL_CURVE", false)
```

#### createVolatilitySurface

语法

```dolphindb
caplib::createVolatilitySurface(definitionHandle, asOfDate, volSmileHandles, termDates, underlying, handle[, returnJson])
```

详情

创建并缓存波动率曲面。函数验证并转换字段，构造 `VolatilitySurface` protobuf 并存入 ObjectCache，供后续分析使用。

参数

definitionHandle STRING 类型。波动率曲面定义 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

volSmileHandles STRING 向量 类型。波动率微笑对象 ObjectCache 句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

termDates DATE 向量 类型。报价期限对应的到期日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolatilitySurface 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2022.03.09
emptyD = array(DOUBLE, 0)
volSmile1d = caplib::createVolatilitySmile(
    "STRIKE_VOL_SMILE", asOfDate, [90.0, 100.0, 110.0], [0.22, 0.20, 0.21],
    "LINEAR_SMILE_METHOD", "FLAT_EXTRAP", 1.0/365.0, emptyD, emptyD,
    90.0, 110.0, "AN_VOL_SMILE_1D", false)
volSmile3y = caplib::createVolatilitySmile(
    "STRIKE_VOL_SMILE", asOfDate, [90.0, 100.0, 110.0], [0.23, 0.21, 0.22],
    "LINEAR_SMILE_METHOD", "FLAT_EXTRAP", 3.0, emptyD, emptyD,
    90.0, 110.0, "AN_VOL_SMILE_3Y", false)
volSurfaceDefinition = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "LINEAR_SMILE_METHOD", "FLAT_EXTRAP",
    "LINEAR_IN_VOLATILITY", "FLAT_IN_VOLATILITY", "ACT_365_FIXED",
    "LOG_NORMAL_VOL_TYPE", "ABSOLUTE_STRIKE", 90.0, 110.0,
    "AN_VOL_SURFACE_DEF", false)
caplib::createVolatilitySurface(
    volSurfaceDefinition, asOfDate, [volSmile1d, volSmile3y],
    [2022.03.10, 2025.03.10], "AN_UNDERLYING", "AN_VOL_SURFACE", false)
```

#### createOptionQuoteMatrix

语法

```dolphindb
caplib::createOptionQuoteMatrix(quoteValueType, quoteTermType, quoteStrikeType, exerciseType, optionUnderlyingType, asOfDate, terms, termDates, payoffTypes, values, strikes, assetName, handle[, returnJson])
```

详情

创建并缓存通用期权报价矩阵。函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

参数

quoteValueType STRING 类型。报价值类型，例如价格或波动率。**有效性:** 值必须是以下完整 protobuf 标签之一：`OQVT_INVALID`, `OQVT_VOLATILITY`, `OQVT_PRICE`。

quoteTermType STRING 类型。报价期限类型。**有效性:** 可接受值：`OQTT_INVALID`, `OQTT_ABSOLUTE_TERM`, `OQTT_RELATIVE_TERM`。不区分大小写。

quoteStrikeType STRING 类型。报价行权价类型。**有效性:** 可接受值：`OQST_INVALID`, `OQST_ABSOLUTE_STRIKE`, `OQST_RELATIVE_STRIKE`, `OQST_DELTA_STRIKE`。不区分大小写。

exerciseType STRING 类型。期权行权风格。**有效性:** 值必须是以下完整 protobuf 标签之一：`EUROPEAN`, `AMERICAN`, `BERMUDAN`。

optionUnderlyingType STRING 类型。期权标的类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`SPOT_UNDERLYING_TYPE`, `FUTURE_UNDERLYING_TYPE`。

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

terms STRING 向量 类型。报价期限数组。**有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。

termDates DATE 向量 类型。报价期限对应的到期日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

payoffTypes STRING 矩阵/向量 类型。与报价值对齐的收益类型矩阵或向量。**有效性:** 每个元素必须是以下完整 protobuf 标签之一：`CALL`, `PUT`, `STRADDLE`, `STRANGLE`, `RISK_REVERSAL`, `BUTTERFLY`, `ATM_STRADDLE`。

values DOUBLE 矩阵/向量 类型。报价值矩阵或向量。**有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

strikes DOUBLE 矩阵/向量 类型。行权价数组或矩阵。**有效性:** 必须有限；价格型标的通常要求非负，利率型标的可为负。包装器仅检查类型/形状。

assetName STRING 类型。资产或标的名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 OptionQuoteMatrix 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2022.03.09
quoteTermDates = [2022.06.09, 2022.09.09]
quotePayoffTypes = matrix(["CALL", "PUT"], ["CALL", "PUT"])
quoteValues = matrix([10.5, 8.5], [11.0, 9.0])
quoteStrikes = matrix([95.0, 95.0], [105.0, 105.0])
caplib::createOptionQuoteMatrix(
    "OQVT_PRICE", "OQTT_ABSOLUTE_TERM", "OQST_ABSOLUTE_STRIKE",
    "EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    [], quoteTermDates, quotePayoffTypes, quoteValues, quoteStrikes,
    "AN_UNDERLYING", "AN_OPTION_QUOTES", true)
```

#### createVolatilitySurfaceDefinition

语法

```dolphindb
caplib::createVolatilitySurfaceDefinition(volSmileType, smileMethod, smileExtrapMethod, timeInterpMethod, timeExtrapMethod, dayCountConvention, volType, wingStrikeType, lower, upper, handle[, returnJson])
```

详情

创建并缓存波动率曲面定义。函数验证并转换字段，构造 `VolatilitySurfaceDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

参数

volSmileType STRING 类型。波动率微笑类型。**有效性:** 可接受值：`STRIKE`, `STRIKE_VOL_SMILE`, `DELTA`, `DELTA_VOL_SMILE`, `LOG_STRIKE`, `LOG_STRIKE_VOL_SMILE`。仅接受所示精确拼写。

smileMethod STRING 类型。微笑构建或插值方法。**有效性:** 可接受值：`SVI`, `SVI_SMILE_METHOD`, `SABR`, `SABR_SMILE_METHOD`, `LINEAR`, `LINEAR_SMILE_METHOD`, `CUBIC_SPLINE`, `CUBIC_SPLINE_SMILE_METHOD`。仅接受所示精确拼写。

smileExtrapMethod STRING 类型。微笑外推方法。**有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。

timeInterpMethod STRING 类型。期限方向插值方法。**有效性:** 可接受值：`LINEAR_IN_VARIANCE`, `LINEAR_IN_VOLATILITY`, `LINEAR_IN_PARAM`。不区分大小写。

timeExtrapMethod STRING 类型。期限方向外推方法。**有效性:** 可接受值：`FLAT_IN_VOLATILITY`。不区分大小写。

dayCountConvention STRING 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。

volType STRING 类型。波动率类型。**有效性:** 识别值：`LOG_NORMAL_VOL_TYPE`, `NORMAL_VOL_TYPE`, `LOG_NORMAL`, `NORMAL`。不区分大小写。

wingStrikeType STRING 类型。翼部行权价类型。**有效性:** 识别值：`DELTA`, `RELATIVE_RATIO_STRIKE`, `RELATIVE_SPREAD_STRIKE`, `ABSOLUTE_STRIKE`。不区分大小写。

lower DOUBLE 类型。下界参数。**有效性:** 必须有限且严格小于 *upper*；包装器不检查此关系。

upper DOUBLE 类型。上界参数。**有效性:** 必须有限且严格大于 *lower*；包装器不检查此关系。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolatilitySurfaceDefinition 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-5, 1.0e-5, "EQ_VOL_DEF", true)
```

#### createVolSurfBuildSettings

语法

```dolphindb
caplib::createVolSurfBuildSettings(fixedParamIndex, fixedParamValue, handle[, returnJson])
```

详情

创建并缓存波动率曲面构建设置。函数验证并转换字段，构造 `VolatilitySurfaceBuildSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

fixedParamIndex INT 类型。需要固定的模型参数索引。**有效性:** 必须非负且小于对应数组长度；包装器仅检查 INT 类型。

fixedParamValue DOUBLE 类型。固定模型参数取值。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolatilitySurfaceBuildSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", true)
```

#### createPricingModelSettings

语法

```dolphindb
caplib::createPricingModelSettings(modelName, asset, calibrated, constantParams, handle[, returnJson])
```

详情

创建并缓存定价模型设置。函数验证并转换字段，构造 `PricingModelSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

modelName STRING 类型。定价模型名称。**有效性:** 可接受值：`BLACK_SCHOLES_MERTON`, `BLACK_MODEL`, `BACHELIER_MODEL`, `HESTON_STOCH_VOL_MODEL`, `SKEW_MODEL`。仅接受所示精确拼写。

asset STRING 类型。资产收益或资产返还金额。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

calibrated BOOL 类型。模型参数是否已校准。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

constantParams DOUBLE 向量 类型。模型常数参数数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingModelSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


modelParams = take(double, 0)
caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
```

#### createPdeSettings

语法

```dolphindb
caplib::createPdeSettings(tSize, xSize, xMin, xMax, xMinMaxType, ySize, yMin, yMax, yMinMaxType, zSize, zMin, zMax, zMinMaxType, xDensity, yDensity, zDensity, xGridType, yGridType, zGridType, xInterp, yInterp, zInterp, handle[, returnJson])
```

详情

创建并缓存 PDE 网格设置。函数验证并转换字段，构造 `PdeSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

tSize INT 类型。时间维网格点数量。**有效性:** 必须严格为正；包装器通常仅检查类型。

xSize INT 类型。X 维网格点数量。**有效性:** 必须严格为正；包装器通常仅检查类型。

xMin DOUBLE 类型。X 维网格下界。**有效性:** 必须有限且严格小于 *xMax*；包装器不检查此关系。

xMax DOUBLE 类型。X 维网格上界。**有效性:** 必须有限且严格大于 *xMin*；包装器不检查此关系。

xMinMaxType INT 类型。X 维边界解释方式。**有效性:** 可接受的整数代码：`0=按标准差倍数确定边界`, `1=绝对边界`.

ySize INT 类型。Y 维网格点数量。**有效性:** 必须严格为正；包装器通常仅检查类型。

yMin DOUBLE 类型。Y 维网格下界。**有效性:** 必须有限且严格小于 *yMax*；包装器不检查此关系。

yMax DOUBLE 类型。Y 维网格上界。**有效性:** 必须有限且严格大于 *yMin*；包装器不检查此关系。

yMinMaxType INT 类型。Y 维边界解释方式。**有效性:** 可接受的整数代码：`0=按标准差倍数确定边界`, `1=绝对边界`.

zSize INT 类型。Z 维网格点数量。**有效性:** 必须严格为正；包装器通常仅检查类型。

zMin DOUBLE 类型。Z 维网格下界。**有效性:** 必须有限且严格小于 *zMax*；包装器不检查此关系。

zMax DOUBLE 类型。Z 维网格上界。**有效性:** 必须有限且严格大于 *zMin*；包装器不检查此关系。

zMinMaxType INT 类型。Z 维边界解释方式。**有效性:** 可接受的整数代码：`0=按标准差倍数确定边界`, `1=绝对边界`.

xDensity DOUBLE 类型。X 维网格密度参数。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

yDensity DOUBLE 类型。Y 维网格密度参数。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

zDensity DOUBLE 类型。Z 维网格密度参数。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

xGridType INT 类型。X 维网格类型。**有效性:** 可接受的整数代码：`1=UNIFORM_GRID`, `2=ADAPTIVE_GRID`.

yGridType INT 类型。Y 维网格类型。**有效性:** 可接受的整数代码：`1=UNIFORM_GRID`, `2=ADAPTIVE_GRID`.

zGridType INT 类型。Z 维网格类型。**有效性:** 可接受的整数代码：`1=UNIFORM_GRID`, `2=ADAPTIVE_GRID`.

xInterp INT 类型。X 维插值方法。**有效性:** 可接受的整数代码：`1=LINEAR_INTERP`, `2=CUBIC_SPLINE_INTERP`, `3=LEFT_CONTINUOUS_FLAT_INTERP`, `4=SABR_INTERP`, `5=SVI_INTERP`, `6=LOG_MONEYNESS_CUBIC_SPLINE_INTERP`, `7=SABR_NORMAL_INTERP`, `8=QUADRATIC_POLYNOMIAL_INTERP`, `9=CUBIC_POLYNOMIAL_INTERP`, `10=CUBIC_HERMITE_SPLINE_INTERP`.

yInterp INT 类型。Y 维插值方法。**有效性:** 可接受的整数代码：`1=LINEAR_INTERP`, `2=CUBIC_SPLINE_INTERP`, `3=LEFT_CONTINUOUS_FLAT_INTERP`, `4=SABR_INTERP`, `5=SVI_INTERP`, `6=LOG_MONEYNESS_CUBIC_SPLINE_INTERP`, `7=SABR_NORMAL_INTERP`, `8=QUADRATIC_POLYNOMIAL_INTERP`, `9=CUBIC_POLYNOMIAL_INTERP`, `10=CUBIC_HERMITE_SPLINE_INTERP`.

zInterp INT 类型。Z 维插值方法。**有效性:** 可接受的整数代码：`1=LINEAR_INTERP`, `2=CUBIC_SPLINE_INTERP`, `3=LEFT_CONTINUOUS_FLAT_INTERP`, `4=SABR_INTERP`, `5=SVI_INTERP`, `6=LOG_MONEYNESS_CUBIC_SPLINE_INTERP`, `7=SABR_NORMAL_INTERP`, `8=QUADRATIC_POLYNOMIAL_INTERP`, `9=CUBIC_POLYNOMIAL_INTERP`, `10=CUBIC_HERMITE_SPLINE_INTERP`.

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PdeSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "CM_PDE_SETTINGS", false)
```

#### createMonteCarloSettings

语法

```dolphindb
caplib::createMonteCarloSettings(numSimulations, uniformNumberType, seed, wienerBuildMethod, gaussianMethod, useAntithetic, numSteps, handle[, returnJson])
```

详情

创建并缓存蒙特卡洛模拟设置。函数验证并转换字段，构造 `MonteCarloSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

numSimulations INT 类型。蒙特卡洛模拟路径数量。**有效性:** 包装器要求非空 INT 标量且严格为正。

uniformNumberType INT 类型。均匀随机数生成器类型。**有效性:** 可接受的整数代码：`0=SOBOL_NUMBER`, `1=MERSENNE_TWIST_19937_NUMBER`.

seed INT 类型。随机数种子。**有效性:** 应为非负整数；包装器接受任意 INT。

wienerBuildMethod INT 类型。维纳过程构建方法。**有效性:** 可接受的整数代码：`1=BROWNIAN_BRIDGE_METHOD`, `2=INCREMENTAL_METHOD`.

gaussianMethod INT 类型。高斯随机数生成方法。**有效性:** 可接受的整数代码：`1=INVERSE_CUMULATIVE_METHOD`, `2=BOX_MULLER_METHOD`, `3=CENTRAL_LIMIT_METHOD`.

useAntithetic BOOL 类型。是否使用反向变量。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

numSteps INT 类型。蒙特卡洛时间步数。**有效性:** 必须严格为正；包装器通常仅检查类型。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 MonteCarloSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 1, "CM_MC_SETTINGS", false)
```

#### createPricingSettings

语法

```dolphindb
caplib::createPricingSettings(currency, pricingMethod, incCurrent, cashFlows, specificPricingRequests, modelHandle, pdeHandle, mcHandle, handle[, returnJson])
```

详情

创建并缓存定价设置。函数验证并转换字段，构造 `PricingSettings` protobuf 并存入 ObjectCache，供后续分析使用。

创建并缓存定价设置对象。*specificPricingRequests* 对应 `PricingSettings.specific_pricing_requests`（repeated INT），服务端按 `BondSpecificPricingRequest` 枚举把对应指标填入定价结果的 `specific_pricing_results`：0=到期收益率（YIELD_TO_MATUIRTY_REQUEST）、1=全价（DIRTY_PRICE_REQUEST）、2=净价（CLEAN_PRICE_REQUEST）、3=应计利息（ACCRUED_INTEREST_REQUEST）、4=久期（SIMPLE_DURATION_REQUEST）、5=修正久期（MODIFIED_DURATION_REQUEST）、6=麦考利久期（MACAULAY_DURATION_REQUEST）、7=凸性（CONVEXITY_REQUEST）、8=基点价值（BASIS_POINT_VALUE_REQUEST）。主要用于债券类定价；空向量等价于不请求。**注意：请求列表不要包含 0（YTM 请求）**——服务端在请求含 0 时返回空 `specific_pricing_results`；不包含 0 时返回全量 9 项指标（YTM 值无需请求即出现在返回向量的首个元素）。

参数

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

pricingMethod STRING 类型。定价方法。**有效性:** 可接受值：`ANALYTICAL`, `ANALYTICAL_SMILE_ON`, `PDE`, `MONTE_CARLO`, `BINOMIAL_TREE`, `MOMENT_MATCHING`。仅接受所示精确拼写。

incCurrent BOOL 类型。估值输出中是否包含当前现金流。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

cashFlows BOOL 类型。定价结果中是否包含详细现金流输出。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

specificPricingRequests INT 向量 类型。必填。具体定价请求列表，取值为 BondSpecificPricingRequest 枚举：0=到期收益率，1=全价，2=净价，3=应计利息，4=久期，5=修正久期，6=麦考利久期，7=凸性，8=基点价值。服务端把对应指标填入定价结果的 `specific_pricing_results`。空向量等价于不请求。**有效性:** 必须是不含空值的 INT 向量，元素取值 0–8。**注意：** 请求列表不要包含 0（YTM 请求），否则服务端返回空结果；YTM 值无需请求即出现在返回向量首元素。

modelHandle STRING 类型。定价模型设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pdeHandle STRING 类型。PDE 设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

mcHandle STRING 类型。蒙特卡洛设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

currency = "CNY"
caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), "", "", "", "CNY_BSM_ANALYTICAL", false)
```

#### createDividendCurveRiskSettings

语法

```dolphindb
caplib::createDividendCurveRiskSettings(delta, gamma, shift, method, granularity, scaling, threading, handle[, returnJson])
```

详情

创建并缓存股息曲线风险设置。函数验证并转换字段，构造 `DividendCurveRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

delta BOOL 类型。是否计算 Delta 风险或 Delta 数值。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

gamma BOOL 类型。是否计算 Gamma 风险。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

shift DOUBLE 类型。风险或校准计算使用的扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

method INT 类型。计算、校准或有限差分方法选择器。**有效性:** 映射：`value =2` 为 ONE_SIDE_UP。

granularity INT 类型。风险桶或扰动粒度。**有效性:** 映射：`value =2` 为 TERM_STRIKE。

scaling DOUBLE 类型。风险扰动缩放因子。**有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。

threading INT 类型。线程模式选择器。**有效性:** 仅 `1` 选择多线程；其他整数均为单线程。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 DividendCurveRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createDividendCurveRiskSettings(1, 1, 1.0e-4,
    0, 0, 1.0e-4, 0, "DIV_RISK", false)
```

#### createPriceRiskSettings

语法

```dolphindb
caplib::createPriceRiskSettings(delta, gamma, curvature, shift, curvatureShift, method, scaling, threading, handle[, returnJson])
```

详情

创建并缓存标的价格风险设置。函数验证并转换字段，构造 `PriceRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

delta BOOL 类型。是否计算 Delta 风险或 Delta 数值。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

gamma BOOL 类型。是否计算 Gamma 风险。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

curvature BOOL 类型。是否计算曲率风险。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

shift DOUBLE 类型。风险或校准计算使用的扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

curvatureShift DOUBLE 类型。曲率风险使用的扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

method INT 类型。计算、校准或有限差分方法选择器。**有效性:** 映射：`value =2` 为 ONE_SIDE_UP。

scaling DOUBLE 类型。风险扰动缩放因子。**有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。

threading INT 类型。线程模式选择器。**有效性:** 仅 `1` 选择多线程；其他整数均为单线程。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PriceRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
```

#### createVolRiskSettings

语法

```dolphindb
caplib::createVolRiskSettings(vega, volga, shift, method, granularity, scaling, threading, handle[, returnJson])
```

详情

创建并缓存波动率风险设置。函数验证并转换字段，构造 `VolRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

vega BOOL 类型。是否计算 Vega 风险。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

volga BOOL 类型。是否计算 Volga 风险。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

shift DOUBLE 类型。风险或校准计算使用的扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

method INT 类型。计算、校准或有限差分方法选择器。**有效性:** 映射：`value =2` 为 ONE_SIDE_UP。

granularity INT 类型。风险桶或扰动粒度。**有效性:** 映射：`value =2` 为 TERM_STRIKE。

scaling DOUBLE 类型。风险扰动缩放因子。**有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。

threading INT 类型。线程模式选择器。**有效性:** 仅 `1` 选择多线程；其他整数均为单线程。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createVolRiskSettings(
    1, 1, 1.0e-2, 0, 0, 1.0e-2, 0, "FX_VOL_RISK", false)
```

#### createPriceVolRiskSettings

语法

```dolphindb
caplib::createPriceVolRiskSettings(vanna, priceShift, volShift, method, granularity, priceScaling, volScaling, threading, handle[, returnJson])
```

详情

创建并缓存价格-波动率交叉风险设置。函数验证并转换字段，构造 `PriceVolRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

vanna BOOL 类型。是否计算 Vanna 风险。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

priceShift DOUBLE 类型。价格风险扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

volShift DOUBLE 类型。波动率风险扰动大小。**有效性:** 必须非负且有限；包装器通常仅检查类型。

method INT 类型。计算、校准或有限差分方法选择器。**有效性:** 映射：`value =2` 为 ONE_SIDE_UP。

granularity INT 类型。风险桶或扰动粒度。**有效性:** 映射：`value =2` 为 TERM_STRIKE。

priceScaling DOUBLE 类型。价格风险缩放因子。**有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。

volScaling DOUBLE 类型。波动率风险缩放因子。**有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。

threading INT 类型。线程模式选择器。**有效性:** 仅 `1` 选择多线程；其他整数均为单线程。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PriceVolRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createPriceVolRiskSettings(
    1, 1.0e-2, 1.0e-2, 0, 0, 1.0e-2, 1.0e-2, 0, "FX_PRICE_VOL_RISK", false)
```

#### createThetaRiskSettings

语法

```dolphindb
caplib::createThetaRiskSettings(theta, shift, scaling, handle[, returnJson])
```

详情

创建并缓存 Theta 风险设置。函数验证并转换字段，构造 `ThetaRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

theta BOOL 类型。是否计算 Theta 风险。**有效性:** 必须是非空 BOOL 标量；兼容旧示例的 INT `0/1`。字符串、空值及其他整数会抛错。

shift INT 类型。风险或校准计算使用的扰动大小。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

scaling DOUBLE 类型。风险扰动缩放因子。**有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 ThetaRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createThetaRiskSettings(1, 1, 1.0 / 365.0, "CR_THETA_RISK", false)
```

#### createScnSettings

语法

```dolphindb
caplib::createScnSettings(min, max, size, scnGenType, handle[, returnJson])
```

详情

创建并缓存一维情景设置。函数验证并转换字段，构造 `ScnSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

min DOUBLE 类型。情景网格下界。**有效性:** 必须为有限、非空 DOUBLE 标量，且不得大于 *max*。建议使用严格递增的区间；包装器保留两端相等的兼容行为。

max DOUBLE 类型。情景网格上界。**有效性:** 必须为有限、非空 DOUBLE 标量，且不得小于 *min*。

size INT 类型。情景网格点数量。**有效性:** 必须严格为正；包装器通常仅检查类型。

scnGenType INT 类型。情景生成类型。**有效性:** 定义代码为 `0` 和 `1`；包装器字段为 int32，不拒绝其他整数。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 ScnSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createScnSettings(-0.20, 0.20, 11, 1, "FX_PRICE_SCN", false)
```

#### createScnAnalysisSettings

语法

```dolphindb
caplib::createScnAnalysisSettings(scnType, priceHandle, volHandle, threading, handle[, returnJson])
```

详情

创建并缓存情景分析设置。函数验证并转换字段，构造 `ScnAnalysisSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

scnType STRING 类型。情景分析类型。**有效性:** 可接受值：`NONE`, `NO_SCN_ANALYSIS`, `PRICE`, `PRICE_SCN_ANALYSIS`, `VOL`, `VOL_SCN_ANALYSIS`, `PRICE_VOL`, `PRICE_VOL_SCN_ANALYSIS`, `THETA`, `THETA_SCN_ANALYSIS`。仅接受所示精确拼写。

priceHandle STRING 类型。价格情景设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

volHandle STRING 类型。波动率设置或曲面 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

threading INT 类型。线程模式选择器。**有效性:** 仅 `1` 选择多线程；其他整数均为单线程。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 ScnAnalysisSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


priceScn = take(double, 0)
volScn = take(double, 0)
caplib::createScnAnalysisSettings(
    "PRICE_VOL_SCN_ANALYSIS", priceScn, volScn, 0, "FX_SCN_ANALYSIS", false)
```

#### createFlatDividendCurve

语法

```dolphindb
caplib::createFlatDividendCurve(asOfDate, dividend, curveName, handle[, returnJson])
```

详情

创建一条连续复利的平坦股息收益率曲线，将同一股息率用于整个期限范围。函数验证并转换字段，构造 `DividendCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

dividend DOUBLE 类型。操作使用的数值。**有效性:** 必须有限；还须满足业务正值与跨参数约束。

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 DividendCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
caplib::createFlatDividendCurve(
    asOfDate, 0.01, "AN_FLAT_DIVIDEND_CURVE", "AN_FLAT_DIVIDEND_CURVE", false)
```

#### createFlatVolCurve

语法

```dolphindb
caplib::createFlatVolCurve(asOfDate, volatility, underlying, handle[, returnJson])
```

详情

创建一条平坦的一维波动率曲线，其 1 日和 100 年支柱使用相同波动率。函数验证并转换字段，构造 `VolatilityCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

volatility DOUBLE 类型。操作使用的数值。**有效性:** 必须有限；还须满足业务正值与跨参数约束。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolatilityCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
caplib::createFlatVolCurve(asOfDate, 0.20, "AN_UNDERLYING", "AN_FLAT_VOL_CURVE", false)
```

#### createVolatilitySmile

语法

```dolphindb
caplib::createVolatilitySmile(volSmileType, asOfDate, strikes, vols, smileMethod, extrapMethod, term, modelParams, auxiliaryParams, lower, upper, handle[, returnJson])
```

详情

根据对齐的执行价与波动率创建波动率微笑，并设置微笑模型、外推方法、边界和校准参数。函数验证并转换字段，构造 `VolatilitySmile` protobuf 并存入 ObjectCache，供后续分析使用。

参数

volSmileType STRING 类型。波动率微笑类型。**有效性:** 可接受值：`STRIKE`, `STRIKE_VOL_SMILE`, `DELTA`, `DELTA_VOL_SMILE`, `LOG_STRIKE`, `LOG_STRIKE_VOL_SMILE`。仅接受所示精确拼写。

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

strikes DOUBLE 向量 类型。操作使用的数值向量。**有效性:** 所有值须有限且形状与配对参数一致。

vols DOUBLE 向量 类型。波动率节点值数组。**有效性:** 必须具有所列元素类型和形状；数值必须非负且有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

smileMethod STRING 类型。微笑构建或插值方法。**有效性:** 可接受值：`SVI`, `SVI_SMILE_METHOD`, `SABR`, `SABR_SMILE_METHOD`, `LINEAR`, `LINEAR_SMILE_METHOD`, `CUBIC_SPLINE`, `CUBIC_SPLINE_SMILE_METHOD`。仅接受所示精确拼写。

extrapMethod STRING 类型。外推方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`FLAT_EXTRAP`, `LINEAR_EXTRAP`, `NATURAL_EXTRAP`, `ADJ_FLAT_EXTRAP`。

term DOUBLE 类型。赋给微笑的年化期限。**有效性:** 业务有效值须严格为正且有限；包装器仅检查 DOUBLE 类型。

modelParams DOUBLE 向量 类型。操作使用的数值向量。**有效性:** 所有值须有限且形状与配对参数一致。

auxiliaryParams DOUBLE 向量 类型。操作使用的数值向量。**有效性:** 所有值须有限且形状与配对参数一致。

lower DOUBLE 类型。下界参数。**有效性:** 必须有限且严格小于 *upper*；包装器不检查此关系。

upper DOUBLE 类型。上界参数。**有效性:** 必须有限且严格大于 *lower*；包装器不检查此关系。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolatilitySmile 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
emptyDoubles = take(double, 0)
caplib::createVolatilitySmile(
    "STRIKE_VOL_SMILE", asOfDate, [90.0, 100.0, 110.0], [0.22, 0.20, 0.21],
    "LINEAR_SMILE_METHOD", "FLAT_EXTRAP", 1.0 / 365.0,
    emptyDoubles, emptyDoubles, 90.0, 110.0, "AN_VOL_SMILE_1D", false)
```

#### createFlatVolatilitySurface

语法

```dolphindb
caplib::createFlatVolatilitySurface(asOfDate, volatility, underlying, handle[, returnJson])
```

详情

为指定标的创建平坦波动率曲面，在所有到期日和执行价上返回同一波动率。函数验证并转换字段，构造 `VolatilitySurface` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

volatility DOUBLE 类型。操作使用的数值。**有效性:** 必须有限；还须满足业务正值与跨参数约束。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolatilitySurface 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
caplib::createFlatVolatilitySurface(
    asOfDate, 0.20, "AN_UNDERLYING", "AN_FLAT_VOL_SURFACE", true)
```

#### createProxyOptionQuoteMatrix

语法

```dolphindb
caplib::createProxyOptionQuoteMatrix(underlyingName, refVolSurfaceHandle, refUnderlyingPrice, underlyingPrice, handle[, returnJson])
```

详情

将缓存的参考波动率曲面从参考现货水平缩放到目标现货水平，为另一标的创建期权报价矩阵。函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

参数

underlyingName STRING 类型。操作使用的字符串。**有效性:** 除非明确标为可选，否则必须非空。

refVolSurfaceHandle STRING 类型。所引用具体类的 ObjectCache 句柄。**有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。

refUnderlyingPrice DOUBLE 类型。参考曲面对应的现货价格。**有效性:** 有效缩放要求严格为正且有限；包装器仅检查 DOUBLE 类型。

underlyingPrice DOUBLE 类型。当前标的价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 OptionQuoteMatrix 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

flatVolSurface = caplib::createFlatVolatilitySurface(2021.03.30, 0.20, "AN_UNDERLYING", "AN_FVS", false)
caplib::createProxyOptionQuoteMatrix(
    "AN_UNDERLYING", flatVolSurface, 100.0, 101.0, "AN_PROXY_OPTION_QUOTES", true)
```

#### createModelFreePricingSettings

语法

```dolphindb
caplib::createModelFreePricingSettings(currency, incCurrent, cashFlows, handle[, returnJson])
```

详情

创建分析法定价设置，内置 Black-Scholes-Merton、PDE 网格和 Sobol 蒙特卡洛默认值，无需独立设置句柄。函数验证并转换字段，构造 `PricingSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

incCurrent INT 类型。控制是否包含当日现金流的整数标志。**有效性:** 必须是 INT：`0` 为 false，任意非零值为 true。

cashFlows INT 类型。控制详细现金流输出的整数标志。**有效性:** 必须是 INT：`0` 为 false，任意非零值为 true。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createModelFreePricingSettings(
    "CNY", 1, 0, "AN_MODEL_FREE_PRICING_SETTINGS", false)
```

#### getVolatility

语法

```dolphindb
caplib::getVolatility(volSurfaceHandle, termDates, strikes)
```

详情

从缓存 VolatilitySurface 计算每个到期日与执行价组合的波动率，并保留服务矩阵。

参数

volSurfaceHandle STRING 类型。FxVolatilitySurface 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

termDates DATE 向量 类型。报价期限对应的到期日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

strikes DOUBLE 向量 类型。操作使用的数值向量。**有效性:** 所有值须有限且形状与配对参数一致。

返回值

DOUBLE 矩阵，对应到期日/执行价网格。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2022.03.09
flatVolSurface = caplib::createFlatVolatilitySurface(
    asOfDate, 0.20, "AN_UNDERLYING", "AN_FLAT_VOL_SURFACE", false)
caplib::getVolatility(flatVolSurface, [2023.03.09], [100.0])
```

#### impliedVolCalculator

语法

```dolphindb
caplib::impliedVolCalculator(asOfDate, underlyingPrice, discountCurveHandle, assetCurveHandle, pricingSettingsHandle, optionPrice, payoffType, exerciseType, expiryDate, strike)
```

详情

在所选收益与行权方式下，使用缓存贴现曲线、资产收益曲线和 PricingSettings 求解复现 optionPrice 的波动率。

参数

asOfDate DATE 类型。执行计算的日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

underlyingPrice DOUBLE 类型。当前标的价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

discountCurveHandle STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

assetCurveHandle STRING 类型。所引用具体类的 ObjectCache 句柄。**有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

optionPrice DOUBLE 类型。操作使用的数值。**有效性:** 必须有限；还须满足业务正值与跨参数约束。

payoffType STRING 类型。收益类型，例如 CALL 或 PUT。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

exerciseType STRING 类型。期权行权风格。**有效性:** 值必须是以下完整 protobuf 标签之一：`EUROPEAN`, `AMERICAN`, `BERMUDAN`。

expiryDate DATE 类型。该计算使用的日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

strike DOUBLE 类型。行权价。**有效性:** 利率行权价必须有限；允许负值、零或正值。包装器仅检查类型/形状。

返回值

计算结果，DOUBLE 类型标量。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2022.03.09
flatIrCurve = caplib::createFlatIrYieldCurve(asOfDate, "CNY", 0.02, "AN_FLAT_IR_CURVE", false)
flatDividendCurve = caplib::createFlatDividendCurve(
    asOfDate, 0.01, "AN_FLAT_DIV_CURVE", "AN_FLAT_DIV_CURVE", false)
bsmModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", "", 0, [0.0], "AN_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    "CNY", "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "",
    "AN_PRICING_SETTINGS", false)
caplib::impliedVolCalculator(
    asOfDate, 100.0, flatIrCurve, flatDividendCurve, pricingSettings,
    5.0, "CALL", "EUROPEAN", 2022.09.09, 100.0)
```

### 固定收益

#### buildBondYieldCurve

语法

```dolphindb
caplib::buildBondYieldCurve(asOfDate, buildSettingsHandle, curveName, parCurveHandle, dayCountConvention, compoundingType, frequency, buildingMethod, calcJacobian, forwardCurveHandle, handle[, returnJson])
```

详情

构建债券收益率曲线。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrYieldCurve`。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

buildSettingsHandle STRING 类型。构建设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

parCurveHandle STRING 类型。平价曲线输入对象 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

dayCountConvention STRING 类型。计息惯例。**有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。任何其他字符串均回退到函数指定的默认日计数。

compoundingType STRING 类型。复利类型。**有效性:** 识别值：`SIMPLE`, `SIMPLE_COMPOUNDING`, `COMPOUNDED`, `DISCRETE`, `DISCRETE_COMPOUNDING`, `CONTINUOUS`, `CONTINUOUS_COMPOUNDING`。不区分大小写。空值或其他字符串回退为 CONTINUOUS_COMPOUNDING。

frequency STRING 类型。频率。**有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。任何其他字符串均回退到函数指定的默认频率。

buildingMethod STRING 类型。曲线或曲面构建算法名称。**有效性:** 识别值：`BOOTSTRAP`, `BOOTSTRAPPING`, `BOOTSTRAPPING_METHOD`, `GLOBAL_OPTIMIZATION`, `GLOBAL_OPTIMIZATION_METHOD`, `HYBRID`, `HYBRID_METHOD`。不区分大小写。空值或其他字符串回退为 BOOTSTRAPPING_METHOD。

calcJacobian INT 类型。是否计算并返回校准雅可比信息。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

forwardCurveHandle STRING 类型。远期曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrYieldCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.07.22
currency = "CNY"
curveName = "cny_treas_std_cfets"
caplib::createCalendar("CAL_CFETS")
bondNames = [
    "CNY_TREAS_ZERO_1M", "CNY_TREAS_CPN_A_3M", "CNY_TREAS_CPN_A_6M",
    "CNY_TREAS_CPN_A_9M", "CNY_TREAS_CPN_A_1Y", "CNY_TREAS_CPN_A_2Y",
    "CNY_TREAS_CPN_A_3Y", "CNY_TREAS_CPN_A_5Y", "CNY_TREAS_CPN_SA_7Y",
    "CNY_TREAS_CPN_SA_10Y", "CNY_TREAS_CPN_SA_15Y", "CNY_TREAS_CPN_SA_20Y",
    "CNY_TREAS_CPN_SA_30Y"]
bondQuotes = [
    1.7112e-2, 1.8317e-2, 1.9413e-2, 1.9500e-2, 2.1563e-2,
    2.4985e-2, 2.5538e-2, 2.7550e-2, 2.9175e-2, 2.9263e-2,
    3.2984e-2, 3.3462e-2, 3.5023e-2]
parCurve = caplib::createBondParCurve(
    asOfDate, currency, bondNames, bondQuotes,
    "YIELD_TO_MATURITY", curveName, false)
buildSettings = caplib::createBondYieldCurveBuildSettings(
    curveName, "ZERO_RATE", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CNY_TREAS_STD_CFETS_BUILD_SETTINGS", false)
caplib::buildBondYieldCurve(
    asOfDate, buildSettings, curveName, parCurve,
    "ACT_365_FIXED", "CONTINUOUS_COMPOUNDING", "ANNUAL",
    "BOOTSTRAPPING_METHOD", 0, "", "CNY_TREAS_STD_CFETS", true)
```
#### calcYieldToMaturity

语法

```dolphindb
caplib::calcYieldToMaturity(asOfDate, compoundingType, bondHandle, forwardCurveHandle, price, priceType, frequency)
```

详情

根据价格和报价约定求解缓存 VanillaBond 的收益率；远期曲线句柄为空时使用平坦零曲线。

参数

asOfDate DATE 类型。执行计算的日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

compoundingType STRING 类型。复利类型。**有效性:** 识别值：`SIMPLE`, `SIMPLE_COMPOUNDING`, `COMPOUNDED`, `DISCRETE`, `DISCRETE_COMPOUNDING`, `CONTINUOUS`, `CONTINUOUS_COMPOUNDING`。不区分大小写。空值或其他字符串回退为 DISCRETE_COMPOUNDING。

bondHandle STRING 类型。债券对象 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

forwardCurveHandle STRING 类型。远期曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

price DOUBLE 类型。价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

priceType STRING 类型。价格类型。**有效性:** 识别值：`YIELD`, `YIELD_TO_MATURITY`, `YTM`, `CLEAN`, `CLEAN_PRICE`, `DIRTY`, `DIRTY_PRICE`。不区分大小写。空值或其他字符串回退为 CLEAN_PRICE。

frequency STRING 类型。频率。**有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。任何其他字符串均回退到函数指定的默认频率。

返回值

计算结果，DOUBLE 类型标量。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.07.22
currency = "CNY"
calCfets = "CAL_CFETS"
caplib::createCalendar(calCfets)
bondTemplate = caplib::createVanillaBondTemplate(
    "cny_treas_cpn_bond_200014", "FIXED_COUPON_BOND",
    2020.10.09, 1, 2020.10.10, "5Y",
    2.15e-2, currency, 100.0,
    "ACT_365_FIXED", calCfets, "ANNUAL",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "",
    "", "INVALID_FREQUENCY", "INVALID_BUSINESS_DAY_CONVENTION",
    "INVALID_DATE_GENERATION_MODE", -1,
    "0d", "", "INVALID_BUSINESS_DAY_CONVENTION", false,
    "CONST_NOTIONAL", 0.0, false)
vanillaBond = caplib::buildVanillaBond(
    1000000.0, bondTemplate, "", 2020.10.10, "FI_VANILLA_BOND", false)
// 远期曲线句柄传空字符串时按平坦零曲线处理
caplib::calcYieldToMaturity(
    asOfDate, "CONTINUOUS_COMPOUNDING", vanillaBond, "", 99.5,
    "CLEAN_PRICE", "ANNUAL")
```
#### calcFixedCpnBondParRate

语法

```dolphindb
caplib::calcFixedCpnBondParRate(asOfDate, bondHandle, discountCurveHandle, spreadCurveHandle)
```

详情

计算缓存固定利率债券（VanillaBond）的平价票面利率：以给定贴现曲线贴现（可叠加信用利差曲线），求得使债券按面值定价的票息率。*spreadCurveHandle* 传空字符串时按插件内部平坦零利差处理；传入其他类型曲线对象（如平坦信用曲线）会抛出异常。

参数

asOfDate DATE 类型。执行计算的日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

bondHandle STRING 类型。债券对象 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

discountCurveHandle STRING 类型。贴现曲线（IrYieldCurve） ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

spreadCurveHandle STRING 类型。信用利差曲线 ObjectCache 句柄。**有效性:** 传空字符串 `""` 时按内部平坦零利差处理；传非空值时必须是已存在的信用利差曲线 ObjectCache 键。

返回值

计算得到的平价利率（小数形式，如 0.0223），DOUBLE 类型标量。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.07.22
currency = "CNY"
calCfets = "CAL_CFETS"
caplib::createCalendar(calCfets)
bondTemplate = caplib::createVanillaBondTemplate(
    "cny_treas_cpn_bond_200014", "FIXED_COUPON_BOND",
    2020.10.09, 1, 2020.10.10, "5Y",
    2.15e-2, currency, 100.0,
    "ACT_365_FIXED", calCfets, "ANNUAL",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "",
    "", "INVALID_FREQUENCY", "INVALID_BUSINESS_DAY_CONVENTION",
    "INVALID_DATE_GENERATION_MODE", -1,
    "0d", "", "INVALID_BUSINESS_DAY_CONVENTION", false,
    "CONST_NOTIONAL", 0.0, false)
vanillaBond = caplib::buildVanillaBond(
    1000000.0, bondTemplate, "", 2020.10.10, "FI_VANILLA_BOND", false)
// 用平坦零曲线作贴现曲线；利差曲线传空字符串按内部平坦零利差处理
discountCurve = caplib::createFlatIrYieldCurve(asOfDate, "CNY", 0.025, "CNY_FLAT_IR", false)
caplib::calcFixedCpnBondParRate(asOfDate, vanillaBond, discountCurve, "")
```

#### priceVanillaBond

语法

```dolphindb
caplib::priceVanillaBond(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价普通债券。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.07.22
currency = "CNY"
calCfets = "CAL_CFETS"
caplib::createCalendar(calCfets)
bondTemplate = caplib::createVanillaBondTemplate(
    "cny_treas_cpn_bond_200014", "FIXED_COUPON_BOND",
    2020.10.09, 1, 2020.10.10, "5Y",
    2.15e-2, currency, 100.0,
    "ACT_365_FIXED", calCfets, "ANNUAL",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "",
    "", "INVALID_FREQUENCY", "INVALID_BUSINESS_DAY_CONVENTION",
    "INVALID_DATE_GENERATION_MODE", -1,
    "0d", "", "INVALID_BUSINESS_DAY_CONVENTION", false,
    "CONST_NOTIONAL", 0.0, false)
vanillaBond = caplib::buildVanillaBond(
    1000000.0, bondTemplate, "", 2020.10.10, "FI_VANILLA_BOND", false)

// Market data: flat discount curve + flat credit curve
discountCurve = caplib::createFlatIrYieldCurve(
    asOfDate, "CNY", 0.02, "FI_TREAS_CURVE", false)
creditCurve = caplib::createCreditCurve(
    asOfDate, [2022.02.21, 2027.02.21], [0.002, 0.003],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "FI_CREDIT_CURVE", "FI_CREDIT_CURVE", false)
fiMktData = caplib::createFiMktDataSet(
    asOfDate, discountCurve, creditCurve,
    discountCurve, discountCurve, discountCurve,
    "FI_MKT_NAME", "FI_MKT", false)

pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 1, 1, take(0, 0), "", "", "", "FI_PRICING", false)

irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 1, 1.0e-4, 5.0e-3, 0, 1, 1.0e-4, 0, "FI_IR_RISK", false)
csCurveRisk = caplib::createCreditCurveRiskSettings(
    1, 1, 1.0e-4, 0, 1, 1.0e-4, 0, "FI_CREDIT_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(1, 1, 1.0/365.0, "FI_THETA_RISK", false)
fiRisk = caplib::createFiRiskSettings(
    irCurveRisk, csCurveRisk, thetaRisk, "FI_RISK_NAME", "FI_RISK", false)

caplib::priceVanillaBond(
    vanillaBond, asOfDate, fiMktData, pricingSettings, fiRisk, "", "", true)
```

#### buildVanillaBond

语法

```dolphindb
caplib::buildVanillaBond(nominal, instTemplate, fixings, startDate, handle[, returnJson])
```

详情

构建普通债券工具。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `VanillaBond`。

参数

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限。

instTemplate STRING 类型。工具模板对象或模板句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

fixings STRING 类型。历史定盘值对象或数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

startDate DATE 类型。起始日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VanillaBond 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

currency = "CNY"
calCfets = "CAL_CFETS"
caplib::createCalendar(calCfets)
bondTemplate = caplib::createVanillaBondTemplate(
    "cny_treas_cpn_bond_200014", "FIXED_COUPON_BOND",
    2020.10.09, 1, 2020.10.10, "5Y",
    2.15e-2, currency, 100.0,
    "ACT_365_FIXED", calCfets, "ANNUAL",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "",
    "", "INVALID_FREQUENCY", "INVALID_BUSINESS_DAY_CONVENTION",
    "INVALID_DATE_GENERATION_MODE", -1,
    "0d", "", "INVALID_BUSINESS_DAY_CONVENTION", false,
    "CONST_NOTIONAL", 0.0, false)
caplib::buildVanillaBond(
    1000000.0, bondTemplate, "", 2020.10.10, "FI_VANILLA_BOND", false)
```

#### createBondParCurve

语法

```dolphindb
caplib::createBondParCurve(asOfDate, currency, instrumentNames, quotes, quoteType, curveName[, returnJson])
```

详情

创建并缓存债券平价曲线输入。函数验证并转换字段，构造 `BondParCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

instrumentNames STRING 向量 类型。市场工具名称数组。**有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

quotes DOUBLE 向量 类型。市场报价值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

quoteType STRING 类型。市场报价类型。**有效性:** 可接受值：`YIELD`, `YIELD_TO_MATURITY`, `YTM`, `CLEAN`, `CLEAN_PRICE`, `DIRTY`, `DIRTY_PRICE`。不区分大小写。

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 BondParCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.07.22
currency = "CNY"
bondNames = [
    "CNY_TREAS_ZERO_1M",
    "CNY_TREAS_CPN_A_3M",
    "CNY_TREAS_CPN_A_6M",
    "CNY_TREAS_CPN_A_9M",
    "CNY_TREAS_CPN_A_1Y",
    "CNY_TREAS_CPN_A_2Y",
    "CNY_TREAS_CPN_A_3Y",
    "CNY_TREAS_CPN_A_5Y",
    "CNY_TREAS_CPN_SA_7Y",
    "CNY_TREAS_CPN_SA_10Y",
    "CNY_TREAS_CPN_SA_15Y",
    "CNY_TREAS_CPN_SA_20Y",
    "CNY_TREAS_CPN_SA_30Y"]
bondQuotes = [
    1.7112e-2, 1.8317e-2, 1.9413e-2, 1.9500e-2, 2.1563e-2,
    2.4985e-2, 2.5538e-2, 2.7550e-2, 2.9175e-2, 2.9263e-2,
    3.2984e-2, 3.3462e-2, 3.5023e-2]
caplib::createBondParCurve(
    asOfDate, currency, bondNames, bondQuotes,
    "YIELD_TO_MATURITY", "cny_treas_std_cfets", true)
```

#### createFixedLegDefinition

语法

```dolphindb
caplib::createFixedLegDefinition(currency, calendar, freq, dayCountConvention, interestDayConvention, stubPolicy, brokenPeriodType, payDayOffset, payDayConvention, notionalExchange, handle[, returnJson])
```

详情

创建并缓存固定利率腿定义。函数验证并转换字段，构造 `InterestRateLegDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

参数

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

calendar STRING 或 STRING 向量 类型。业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

freq STRING 类型。支付或计息频率。**有效性:** 可接受值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

dayCountConvention STRING 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。其他字符串会回退到该函数的默认日计数，而不是报错。

interestDayConvention STRING 类型。计息日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

stubPolicy STRING 类型。短长首末期处理规则。**有效性:** 值必须是以下完整 protobuf 标签之一：`INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。

brokenPeriodType STRING 类型。不规则首末期处理类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`SHORT`, `LONG`。

payDayOffset INT 类型。付款日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

payDayConvention STRING 类型。付款日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

notionalExchange STRING 类型。是否交换名义本金。**有效性:** 值必须是以下完整 protobuf 标签之一：`INITIAL_EXCHANGE`, `INTERMEDIATE_EXCHANGE`, `INITIAL_INTERMEDIATE_EXCHANGE`, `FINAL_EXCHANGE`, `INITIAL_FINAL_EXCHANGE`, `INTERMEDIATE_FINAL_EXCHANGE`, `INITIAL_INTERMEDIATE_FINAL_EXCHANGE`。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestRateLegDefinition 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


calCfets = "CAL_CFETS"
currency = "CNY"
caplib::createFixedLegDefinition(
    currency, calCfets, "QUARTERLY", "ACT_365_FIXED",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "INVALID_NOTIONAL_EXCHANGE", "IR_FIXED_LEG", true)
```

#### createFloatingLegDefinition

语法

```dolphindb
caplib::createFloatingLegDefinition(currency, refIndex, calendar, fixingCalendars, freq, fixingFreq, dayCountConvention, paymentDiscountMethod, rateCalcMethod, spread, interestDayConvention, stubPolicy, brokenPeriodType, payDayOffset, payDayConvention, fixingDayConvention, fixingMode, fixingDayOffset[, notionalExchange], handle[, returnJson])
```

详情

创建并缓存浮动利率腿定义。函数验证并转换字段，构造 `InterestRateLegDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

参数

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

refIndex STRING 类型。参考利率指数名称或句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

calendar STRING 或 STRING 向量 类型。业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

fixingCalendars STRING 或 STRING 向量 类型。定盘日业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

freq STRING 类型。支付或计息频率。**有效性:** 可接受值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

fixingFreq STRING 类型。定盘频率。**有效性:** 可接受值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

dayCountConvention STRING 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。其他字符串会回退到该函数的默认日计数，而不是报错。

paymentDiscountMethod STRING 类型。付款金额贴现方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`NO_DISCOUNT`, `DISCOUNT_AT_FLOATING_RATE`。

rateCalcMethod STRING 类型。利率计算方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`STANDARD`, `COMPOUND_AVERAGE`, `ARITHMETIC_AVERAGE`。

spread BOOL 类型。利差。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

interestDayConvention STRING 类型。计息日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

stubPolicy STRING 类型。短长首末期处理规则。**有效性:** 值必须是以下完整 protobuf 标签之一：`INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。

brokenPeriodType STRING 类型。不规则首末期处理类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`SHORT`, `LONG`。

payDayOffset INT 类型。付款日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

payDayConvention STRING 类型。付款日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

fixingDayConvention STRING 类型。定盘日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

fixingMode STRING 类型。定盘值处理方式。**有效性:** 值必须是以下完整 protobuf 标签之一：`IN_ADVANCE`, `IN_ARREAR`。

fixingDayOffset INT 类型。定盘日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

notionalExchange STRING, optional 类型。是否交换名义本金。省略时默认为 `INVALID_NOTIONAL_EXCHANGE`（不交换名义本金）。**有效性:** 值必须是以下完整 protobuf 标签之一：`INITIAL_EXCHANGE`, `INTERMEDIATE_EXCHANGE`, `INITIAL_INTERMEDIATE_EXCHANGE`, `FINAL_EXCHANGE`, `INITIAL_FINAL_EXCHANGE`, `INTERMEDIATE_FINAL_EXCHANGE`, `INITIAL_INTERMEDIATE_FINAL_EXCHANGE`。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestRateLegDefinition 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

calCfets = "CAL_CFETS"
currency = "CNY"
caplib::createCalendar(calCfets)
iborIndex = caplib::createIborIndex(
    "CNY_SHIBOR_3M", "3M", currency, [calCfets], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)
caplib::createFloatingLegDefinition(
    currency, iborIndex, calCfets, [calCfets],
    "QUARTERLY", "QUARTERLY", "ACT_360",
    "NO_DISCOUNT", "STANDARD", false,
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "MODIFIED_PRECEDING",
    "IN_ADVANCE", -1, "INVALID_NOTIONAL_EXCHANGE", "IR_FLOATING_LEG", true)
```

#### createDepoTemplate

语法

```dolphindb
caplib::createDepoTemplate(instName, currency, calendar[, startDelay[, dayCountConvention[, interestDayConvention[, payDayOffset[, payDayConvention[, startConvention]]]]]][, returnJson])
```

详情

创建并缓存存款工具模板。函数验证并转换字段，构造 `InterestRateInstrumentTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

参数

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

calendar STRING 或 STRING 向量 类型。业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

startDelay INT, optional 类型。起息或交割延迟天数。**有效性:** 非负整数（天数）。

dayCountConvention STRING, optional 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。其他字符串会回退到该函数的默认日计数，而不是报错。

interestDayConvention STRING, optional 类型。计息日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

payDayOffset INT, optional 类型。付款日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

payDayConvention STRING, optional 类型。付款日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

startConvention STRING, optional 类型。工具起息约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`SPOTSTART`, `TODAYSTART`, `TOMORROWSTART`。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestRateInstrumentTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

calCfets = "CAL_CFETS"
caplib::createCalendar(calCfets)
currency = "CNY"
instName = "CNY_DEPO_1M"
caplib::createDepoTemplate(
    instName, currency, calCfets, 0, "ACT_360", "MODIFIED_FOLLOWING", 0, "FOLLOWING", "SPOTSTART", false)
```

#### createFraTemplate

语法

```dolphindb
caplib::createFraTemplate(instName, refIndex, currency, calendar, fixingCalendars, freq[, dayCountConvention[, paymentDiscountMethod[, interestDayConvention[, payDayOffset[, payDayConvention[, fixingDayConvention[, fixingDayOffset]]]]]]][, returnJson])
```

详情

创建并缓存远期利率协议模板。函数验证并转换字段，构造 `InterestRateInstrumentTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

参数

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

refIndex STRING 类型。参考利率指数名称或句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

calendar STRING 或 STRING 向量 类型。业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

fixingCalendars STRING 或 STRING 向量 类型。定盘日业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

freq STRING 类型。支付或计息频率。**有效性:** 可接受值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

dayCountConvention STRING, optional 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。其他字符串会回退到该函数的默认日计数，而不是报错。

paymentDiscountMethod STRING, optional 类型。付款金额贴现方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`NO_DISCOUNT`, `DISCOUNT_AT_FLOATING_RATE`。

interestDayConvention STRING, optional 类型。计息日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

payDayOffset INT, optional 类型。付款日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

payDayConvention STRING, optional 类型。付款日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

fixingDayConvention STRING, optional 类型。定盘日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

fixingDayOffset INT, optional 类型。定盘日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestRateInstrumentTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createCalendar("CAL_CFETS")
iborIndex = caplib::createIborIndex(
    "CNY_SHIBOR_3M", "3M", "CNY", ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)
caplib::createFraTemplate(
    "FRA_TEMPLATE", iborIndex, "CNY", "CAL_CFETS", ["CAL_CFETS"], "QUARTERLY",
    "ACT_360", "NO_DISCOUNT", "MODIFIED_FOLLOWING", 0,
    "MODIFIED_FOLLOWING", "MODIFIED_PRECEDING", -1, true)
```

#### createBondLegDefinition

语法

```dolphindb
caplib::createBondLegDefinition(bondType, settlementDays, currency, dayCountConvention, calendar, frequency, interestDayConvention, stubPolicy, brokenPeriodType, payDayOffset, payDayConvention, refIndex, fixingCalendars, fixingFreq, fixingDayConvention, fixingMode, fixingDayOffset, instName[, returnJson])
```

详情

创建并缓存债券现金流腿定义。函数验证并转换字段，构造 `InterestRateLegDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

参数

bondType STRING 类型。债券类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`FIXED_COUPON_BOND`, `FLOATING_COUPON_BOND`, `ZERO_COUPON_BOND`。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

dayCountConvention STRING 类型。计息惯例。**有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。任何其他字符串均回退到函数指定的默认日计数。

calendar STRING 类型。业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

frequency STRING 类型。频率。**有效性:** 值必须是以下完整 protobuf 标签之一：`ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。

interestDayConvention STRING 类型。计息日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

stubPolicy STRING 类型。短长首末期处理规则。**有效性:** 值必须是以下完整 protobuf 标签之一：`INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。

brokenPeriodType STRING 类型。不规则首末期处理类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`SHORT`, `LONG`。

payDayOffset INT 类型。付款日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

payDayConvention STRING 类型。付款日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

refIndex STRING 类型。参考利率指数名称或句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

fixingCalendars STRING 类型。定盘日业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

fixingFreq STRING 类型。定盘频率。**有效性:** 值必须是以下完整 protobuf 标签之一：`ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。

fixingDayConvention STRING 类型。定盘日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

fixingMode STRING 类型。定盘值处理方式。**有效性:** 值必须是以下完整 protobuf 标签之一：`IN_ADVANCE`, `IN_ARREAR`。

fixingDayOffset INT 类型。定盘日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestRateLegDefinition 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
caplib::createBondLegDefinition(
    "FIXED_COUPON_BOND", 1, currency, "ACT_365_FIXED", "CAL_CFETS",
    "ANNUAL", "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "", "", "ANNUAL",
    "MODIFIED_FOLLOWING", "IN_ADVANCE", -1, "FI_BOND_LEG", false)
```

#### createVanillaBondTemplate

语法

```dolphindb
caplib::createVanillaBondTemplate(instName, vanillaBondType, issueDate, settlementDays, startDate, maturity, rate, currency, issuePrice, dayCountConvention, calendar, frequency, interestDayConvention, stubPolicy, brokenPeriodType, payDayOffset, payDayConvention, refIndex, fixingCalendars, fixingFreq, fixingDayConvention, fixingMode, fixingDayOffset, exCouponPeriod, exCouponCalendar, exCouponDayConvention, exCouponEndOfMonth[, notionalType[, recoveryRate]][, returnJson])
```

详情

创建并缓存普通债券模板。函数验证并转换字段，构造 `VanillaBondTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

参数

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

vanillaBondType STRING 类型。普通债券类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`FIXED_COUPON_BOND`, `FLOATING_COUPON_BOND`, `ZERO_COUPON_BOND`。

issueDate DATE 类型。发行日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

startDate DATE 类型。起始日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

maturity STRING 类型。到期期限或到期日。**有效性:** 值必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。

rate DOUBLE 类型。利率或票息率。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

issuePrice DOUBLE 类型。发行价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

dayCountConvention STRING 类型。计息惯例。**有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。任何其他字符串均回退到函数指定的默认日计数。

calendar STRING 类型。业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

frequency STRING 类型。频率。**有效性:** 值必须是以下完整 protobuf 标签之一：`ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。

interestDayConvention STRING 类型。计息日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

stubPolicy STRING 类型。短长首末期处理规则。**有效性:** 值必须是以下完整 protobuf 标签之一：`INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。

brokenPeriodType STRING 类型。不规则首末期处理类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`SHORT`, `LONG`。

payDayOffset INT 类型。付款日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

payDayConvention STRING 类型。付款日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

refIndex STRING 类型。参考利率指数名称或句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

fixingCalendars STRING 或 STRING 向量 类型。定盘日业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

fixingFreq STRING 类型。定盘频率。**有效性:** 值必须是以下完整 protobuf 标签之一：`ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。

fixingDayConvention STRING 类型。定盘日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

fixingMode STRING 类型。定盘值处理方式。**有效性:** 值必须是以下完整 protobuf 标签之一：`IN_ADVANCE`, `IN_ARREAR`。

fixingDayOffset INT 类型。定盘日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

exCouponPeriod STRING 类型。除息期长度。**有效性:** INT 输入按天计，无需单位；STRING 输入为带可选正负号的整数和可选单位 `Y/M/W/D`（或完整英文单位），省略单位时按天计，负号会被保留。

exCouponCalendar STRING 类型。除息日业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

exCouponDayConvention STRING 类型。除息日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

exCouponEndOfMonth BOOL 类型。除息期是否使用月末规则。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

notionalType STRING, optional 类型。名义本金类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`CONST_NOTIONAL`, `AMORTISING_NOTIONAL`, `ACCRETING_NOTIONAL`。

recoveryRate DOUBLE, optional 类型。回收率。**有效性:** 必须有限且业务有效范围为 `[0,1]`；包装器仅检查类型。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VanillaBondTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createVanillaBondTemplate(
    "CNY_TREAS_CPN_BOND", "FIXED_COUPON_BOND",
    2020.07.22, 1, 2020.07.22, "5Y",
    0.03, "CNY", 100.0,
    "ACT_365_FIXED", "CAL_CFETS", "ANNUAL",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "",
    "", "INVALID_FREQUENCY", "INVALID_BUSINESS_DAY_CONVENTION",
    "INVALID_DATE_GENERATION_MODE", -1,
    "0d", "", "INVALID_BUSINESS_DAY_CONVENTION", false,
    "CONST_NOTIONAL", 0.0, false)
```

#### createBondYieldCurveBuildSettings

语法

```dolphindb
caplib::createBondYieldCurveBuildSettings(curveName, curveType, interpMethod, extrapMethod, handle[, returnJson])
```

详情

创建并缓存债券收益率曲线构建设置。函数验证并转换字段，构造 `BondYieldCurveBuildSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

curveType STRING 类型。曲线值类型，例如零利率、贴现因子或利差。**有效性:** 值必须是以下完整 protobuf 标签之一：`ZERO_RATE`, `LOG_DISCOUNT`, `FORWARD_RATE`。

interpMethod STRING 类型。插值方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `SABR_INTERP`, `SVI_INTERP`, `LOG_MONEYNESS_CUBIC_SPLINE_INTERP`, `SABR_NORMAL_INTERP`, `QUADRATIC_POLYNOMIAL_INTERP`, `CUBIC_POLYNOMIAL_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。

extrapMethod STRING 类型。外推方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`FLAT_EXTRAP`, `LINEAR_EXTRAP`, `NATURAL_EXTRAP`, `ADJ_FLAT_EXTRAP`。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 BondYieldCurveBuildSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


cnyTreasStdCfetsName = "CAL_CFETS"

cnyTreasStdCfets = "CAL_CFETS"
caplib::createBondYieldCurveBuildSettings(
    cnyTreasStdCfetsName, "ZERO_RATE", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CNY_TREAS_STD_CFETS_BUILD_SETTINGS", true)

```

#### createFiMktDataSet

语法

```dolphindb
caplib::createFiMktDataSet(asOfDate, discountCurve, creditCurve, underlyingDiscountCurve, underlyingIncomeCurve, underlyingForwardCurve, name, handle[, returnJson])
```

详情

创建并缓存固定收益市场数据集。函数验证并转换字段，构造 `FiMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

discountCurve STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

creditCurve STRING 类型。信用曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

underlyingDiscountCurve STRING 类型。标的贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

underlyingIncomeCurve STRING 类型。标的收益曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

underlyingForwardCurve STRING 类型。标的远期曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FiMktDataSet 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.07.22
discountCurve = caplib::createFlatIrYieldCurve(
    asOfDate, "CNY", 0.02, "FI_TREAS_CURVE", false)
creditCurve = caplib::createCreditCurve(
    asOfDate, [2022.02.21, 2027.02.21], [0.002, 0.003],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "FI_CREDIT_CURVE", "FI_CREDIT_CURVE", false)
caplib::createFiMktDataSet(
    asOfDate, discountCurve, creditCurve,
    discountCurve, discountCurve, discountCurve,
    "FI_MKT_NAME", "FI_MKT", true)
```

#### createBondMktDataSet

语法

```dolphindb
caplib::createBondMktDataSet(asOfDate, discountCurve, creditCurve, forwardCurve, name, handle[, returnJson])
```

详情

创建并缓存债券市场数据集。函数验证并转换字段，构造 `FiMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

discountCurve STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

creditCurve STRING 类型。信用曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

forwardCurve STRING 类型。远期曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FiMktDataSet 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.07.22
currency = "CNY"
discountCurve = caplib::createFlatIrYieldCurve(asOfDate, "CNY", 0.02, "CNY_DISCOUNT", false)
creditCurve = caplib::createCreditCurve(
    asOfDate, [2022.02.21, 2027.02.21], [0.002, 0.003],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "FI_CREDIT_CURVE", "FI_CREDIT_CURVE", false)
caplib::createBondMktDataSet(
    asOfDate, discountCurve, creditCurve, discountCurve,
    "FI_BOND_MKT_NAME", "FI_BOND_MKT", true)
```

#### createFiRiskSettings

语法

```dolphindb
caplib::createFiRiskSettings(irCurveSettings, csCurveSettings, thetaSettings, name, handle[, returnJson])
```

详情

创建并缓存固定收益风险设置。函数验证并转换字段，构造 `FiRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

irCurveSettings STRING 类型。利率曲线风险设置 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

csCurveSettings STRING 类型。信用利差曲线风险设置 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

thetaSettings STRING 类型。设置对象的缓存句柄或配置值。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FiRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 1, 1.0e-4, 5.0e-3, 0, 1, 1.0e-4, 0, "FI_IR_RISK", false)
csCurveRisk = caplib::createCreditCurveRiskSettings(
    1, 1, 1.0e-4, 0, 1, 1.0e-4, 0, "FI_CREDIT_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(1, 1, 1.0/365.0, "FI_THETA_RISK", false)
caplib::createFiRiskSettings(
    irCurveRisk, csCurveRisk, thetaRisk, "FI_RISK_NAME", "FI_RISK", true)
```

#### createVanillaBondRiskSettings

语法

```dolphindb
caplib::createVanillaBondRiskSettings(dv01, cs01, theta, name, handle[, returnJson])
```

详情

创建并缓存普通债券风险设置。函数验证并转换字段，构造 `FiRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

dv01 STRING 类型。是否计算 DV01 利率风险。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

cs01 STRING 类型。是否计算 CS01 信用利差风险。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

theta BOOL 类型。是否计算 Theta 风险。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FiRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createVanillaBondRiskSettings(
    "", "", 1, "FI_VANILLA_BOND_RISK_NAME", "FI_VANILLA_BOND_RISK", true)
```

#### createAssetYieldCurve

语法

```dolphindb
caplib::createAssetYieldCurve(asOfDate, pillarDates, pillarValues, interp, extrap, dayCountConvention, compounding, pillarNames, curveName, handle[, returnJson])
```

详情

根据对齐的日期与命名支柱以及所选插值、外推、日计数和复利方式创建资产收益率曲线。函数验证并转换字段，构造 `AssetYieldCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

pillarDates DATE 向量 类型。曲线节点日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

pillarValues DOUBLE 向量 类型。曲线节点值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

interp STRING 类型。插值方法。**有效性:** 可接受值：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。仅接受所示精确拼写。

extrap STRING 类型。外推方法。**有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。

dayCountConvention STRING 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。

compounding STRING 类型。复利约定。**有效性:** 可接受值：`CONTINUOUS_COMPOUNDING`, `DISCRETE_COMPOUNDING`, `SIMPLE_COMPOUNDING`。仅接受所示精确拼写。

pillarNames STRING 向量 类型。操作使用的字符串向量。**有效性:** 元素不得为空且长度须与配对参数一致。

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 AssetYieldCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.07.22
pillarDates = [2021.07.26, 2022.07.22]
pillarValues = [0.02, 0.025]
caplib::createAssetYieldCurve(
    asOfDate, pillarDates, pillarValues,
    "LINEAR_INTERP", "FLAT_EXTRAP", "ACT_365_FIXED",
    "CONTINUOUS_COMPOUNDING", ["1D", "3Y"],
    "AN_ASSET_YIELD_CURVE", "AN_ASSET_YIELD_CURVE", false)
```

### 利率
#### buildIrSingleCurrencyCurve

语法

```dolphindb
caplib::buildIrSingleCurrencyCurve(asOfDate, targetCurveNames, buildSettingsHandles, parCurveHandles, dayCountConvention, compoundingType, frequency, otherCurveHandles, buildingMethod, calcJacobian, shift, finiteDifferenceMethod, threadingMode, targetCurveHandles, outputHandle[, returnJson])
```

详情

构建单币种利率曲线组。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrSingleCurrencyCurveBuildingOutput`。
> **用法说明：** *targetCurveHandles* 为每个目标曲线提供输出句柄——构建完成后每条曲线以 `IrYieldCurve` 对象存入 ObjectCache，可直接传给 `getZeroRate`、`getDiscountFactor`、`getFwdRate` 等单曲线访问器使用；*outputHandle* 指向构建输出容器本身。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

targetCurveNames STRING 向量 类型。待构建目标曲线名称数组。**有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

buildSettingsHandles STRING 向量 类型。曲线构建设置 ObjectCache 句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

parCurveHandles STRING 向量 类型。平价曲线输入对象 ObjectCache 句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

dayCountConvention STRING 类型。计息惯例。**有效性:** 值必须是以下完整 protobuf 标签之一：`ACT_360`, `ACTUAL_360`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `ACT_ACT_ISMA`, `ACTUAL_ACTUAL_ISMA`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `THIRTY_360`, `BOND_BASIS`, `THIRTY_E_360`, `EUROBOND_BASIS`, `THIRTY_E_360_ISDA`, `ONE_ONE`, `THIRTY_U_360`, `THIRTY_U_360_EOM`, `THIRTY_360_PSA`, `THIRTY_E_360_PLUS`, `THIRTY_360_IT`, `ACT_ACT_AFB`, `ACTUAL_ACTUAL_AFB`, `ACT_364`, `ACTUAL_364`, `ACT_365_25`, `ACTUAL_365_25`, `ACT_365_ACT`, `ACTUAL_365_ACTUAL`, `ACT_365_L`, `ACTUAL_365_LONG`, `ACT_365_NL`, `ACTUAL_365_NO_LEAP`, `ACT_ACT_YEAR`, `ACTUAL_ACTUAL_YEAR`, `BUSINESS_252`。

compoundingType STRING 类型。复利类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`CONTINUOUS_COMPOUNDING`, `DISCRETE_COMPOUNDING`, `SIMPLE_COMPOUNDING`。

frequency STRING 类型。频率。**有效性:** 值必须是以下完整 protobuf 标签之一：`ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。

otherCurveHandles STRING 向量 类型。构建所需的其他曲线 ObjectCache 句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

buildingMethod STRING 类型。曲线或曲面构建算法名称。**有效性:** 值必须是以下完整 protobuf 标签之一：`BOOTSTRAPPING_METHOD`, `GLOBAL_OPTIMIZATION_METHOD`, `HYBRID_METHOD`。

calcJacobian BOOL 类型。是否计算并返回校准雅可比信息。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

shift DOUBLE 类型。风险或校准计算使用的扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

finiteDifferenceMethod STRING 类型。有限差分方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`CENTRAL_DIFFERENCE_METHOD`, `ONE_SIDE_DOWN_METHOD`, `ONE_SIDE_UP_METHOD`。

threadingMode STRING 类型。线程模式。**有效性:** 值必须是以下完整 protobuf 标签之一：`SINGLE_THREADING_MODE`, `MULTI_THREADING_MODE`。

targetCurveHandles STRING 向量 类型。构建输出的目标曲线句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

outputHandle STRING 类型。构建输出对象的缓存句柄。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrSingleCurrencyCurveBuildingOutput 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2022.03.09
curveName = "CNY_SHIBOR_3M"
caplib::createCalendar("CAL_CFETS")

iborIndex = caplib::createIborIndex(
    "CNY_SHIBOR_3M", "3M", "CNY", ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)
fixedLeg = caplib::createFixedLegDefinition(
    "CNY", "CAL_CFETS", "QUARTERLY", "ACT_365_FIXED",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "INVALID_NOTIONAL_EXCHANGE", "IR_FIXED_LEG", false)
floatingLeg = caplib::createFloatingLegDefinition(
    "CNY", iborIndex, "CAL_CFETS", ["CAL_CFETS"],
    "QUARTERLY", "QUARTERLY", "ACT_360",
    "NO_DISCOUNT", "STANDARD", false,
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "MODIFIED_PRECEDING",
    "IN_ADVANCE", -1, "INVALID_NOTIONAL_EXCHANGE", "IR_FLOATING_LEG", false)
caplib::createIrVanillaSwapTemplate(curveName, 1, fixedLeg, floatingLeg, "SPOTSTART", false)

parCurve = caplib::createIrParRateCurve(asOfDate, "CNY", curveName,
    [curveName, curveName, curveName],
    ["IR_VANILLA_SWAP", "IR_VANILLA_SWAP", "IR_VANILLA_SWAP"],
    ["6M", "1Y", "3Y"], [100, 100, 100], [2.3, 2.4, 2.6], "IR_PAR_CURVE", false)
buildSettings = caplib::createIrYieldCurveBuildSettings(curveName, 0,
    ["CNY"], [curveName], [curveName], [curveName], "IR_BUILD_SETTINGS", false)
caplib::buildIrSingleCurrencyCurve(asOfDate,
    [curveName], [buildSettings], [parCurve],
    "ACT_365_FIXED", "CONTINUOUS_COMPOUNDING", "ANNUAL", [],
    "BOOTSTRAPPING_METHOD", 0, 1.0e-4,
    "CENTRAL_DIFFERENCE_METHOD", "SINGLE_THREADING_MODE",
    ["IR_BUILT_CURVE"], "IR_SINGLE_CCY_BUILD_OUTPUT", true)
```
#### priceIrVanillaInstrument

语法

```dolphindb
caplib::priceIrVanillaInstrument(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

执行定价并返回定价结果。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency and the CNY calendar used by schedules
caplib::createCalendar("CAL_CFETS")
asOfDate = 2022.03.09
currency = "CNY"
curveName = "CNY_SHIBOR_3M"

// CNY discount curve and the 3M SHIBOR index
irCurve = caplib::createIrYieldCurve(
    asOfDate, [2022.03.10, 2025.03.10], [0.02, 0.025],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, curveName, "IR_CURVE", false)
iborIndex = caplib::createIborIndex(
    curveName, "3M", currency, ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)

// Fixed and floating leg definitions assembled into a vanilla swap template
fixedLeg = caplib::createFixedLegDefinition(
    currency, "CAL_CFETS", "QUARTERLY", "ACT_365_FIXED",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "INVALID_NOTIONAL_EXCHANGE", "IR_FIXED_LEG", false)
floatingLeg = caplib::createFloatingLegDefinition(
    currency, iborIndex[0], "CAL_CFETS", ["CAL_CFETS"],
    "QUARTERLY", "QUARTERLY", "ACT_360",
    "NO_DISCOUNT", "STANDARD", false,
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "MODIFIED_PRECEDING",
    "IN_ADVANCE", -1, "INVALID_NOTIONAL_EXCHANGE", "IR_FLOATING_LEG", false)
swapTemplate = caplib::createIrVanillaSwapTemplate(
    curveName, 1, fixedLeg[0], floatingLeg[0], "SPOTSTART", false)

// Pay-fixed 1Y swap on 1,000,000 CNY notional
swap = caplib::buildIrVanillaInstrument(
    "PAY", 0.05, 0.0, 2022.03.07, 2023.03.07,
    swapTemplate[0], 1000000.0, "", "IR_SWAP", false)

// Analytical pricing settings and IR risk settings
pricingModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", "", 0, [0.0], "IR_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 1, 1, take(0, 0), pricingModel, "", "", "IR_PRICING", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 1, 1.0e-4, 5.0e-3, 0, 1, 1.0e-4, 0, "IR_CURVE_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(
    1, 1, 1.0 / 365.0, "IR_THETA_RISK", false)
riskSettings = caplib::createIrRiskSettings(irCurveRisk, thetaRisk, "IR_RISK", false)

// Market data set with the curve as both discount and forward curve
mktData = caplib::createIrMktDataSet(
    asOfDate, irCurve, [iborIndex[0]], [irCurve], "IR_MKT", false)

result = caplib::priceIrVanillaInstrument(
    swap, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```
#### buildIrVanillaInstrument

语法

```dolphindb
caplib::buildIrVanillaInstrument(payReceive, cpnRate, spread, startDate, maturityDate, instTemplate, nominal, legFixings, handle[, returnJson])
```

详情

构建标准利率工具。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrVanillaInstrument`。

参数

payReceive STRING 类型。支付或收取方向。**有效性:** 值必须是以下完整 protobuf 标签之一：`PAY`, `PAYER`, `RECEIVE`, `RECEIVER`。

cpnRate DOUBLE 类型。票息率。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

spread DOUBLE 类型。利差。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

startDate DATE 类型。起始日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

maturityDate DATE 类型。到期日。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

instTemplate STRING 类型。工具模板对象或模板句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

legFixings STRING 类型。各现金流腿使用的定盘值对象或数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrVanillaInstrument 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Register the CNY calendar used by schedules and the index
caplib::createCalendar("CAL_CFETS")
currency = "CNY"
curveName = "CNY_SHIBOR_3M"

// 3M SHIBOR index plus fixed and floating leg definitions
iborIndex = caplib::createIborIndex(
    curveName, "3M", currency, ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)
fixedLeg = caplib::createFixedLegDefinition(
    currency, "CAL_CFETS", "QUARTERLY", "ACT_365_FIXED",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "INVALID_NOTIONAL_EXCHANGE", "IR_FIXED_LEG", false)
floatingLeg = caplib::createFloatingLegDefinition(
    currency, iborIndex[0], "CAL_CFETS", ["CAL_CFETS"],
    "QUARTERLY", "QUARTERLY", "ACT_360",
    "NO_DISCOUNT", "STANDARD", false,
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "MODIFIED_PRECEDING",
    "IN_ADVANCE", -1, "INVALID_NOTIONAL_EXCHANGE", "IR_FLOATING_LEG", false)

// Assemble the legs into a vanilla swap template
swapTemplate = caplib::createIrVanillaSwapTemplate(
    curveName, 1, fixedLeg[0], floatingLeg[0], "SPOTSTART", false)

// Build a pay-fixed 1Y swap on 1,000,000 CNY notional
swap = caplib::buildIrVanillaInstrument(
    "PAY", 0.05, 0.0, 2022.03.07, 2023.03.07,
    swapTemplate[0], 1000000.0, "", "IR_SWAP", false)
```
#### getDiscountFactor

语法

```dolphindb
caplib::getDiscountFactor(irCurveHandle, dates)
```

详情

根据缓存 IrYieldCurve 计算给定日期的贴现因子或多个日期的贴现因子。单日传单元素 DATE 向量，多日传更长向量；输出保持输入顺序。

参数

irCurveHandle STRING 类型。所引用具体类的 ObjectCache 句柄。**有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。

dates DATE 向量 类型。请求曲线值的日期；结果第 i 个元素对应 dates[i]。**有效性:** 必须是无空值 DATE 向量。单日使用单元素向量，多日使用更长向量；不接受 DATE 标量。

返回值

对应向量，DOUBLE 类型向量，元素顺序与输入一致。

**示例**

```dolphindb
loadPlugin("caplib")

irAsOfDate = 2022.03.09
irCurrency = "CNY"
irCurve = caplib::createIrYieldCurve(
    irAsOfDate, [2022.03.10, 2025.03.10], [0.02, 0.025],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", irCurrency, "CNY_SHIBOR_3M", "IR_CHAIN_CURVE", false)
caplib::getDiscountFactor(irCurve, [2025.03.10])
```

#### getZeroRate

语法

```dolphindb
caplib::getZeroRate(irCurveHandle, dates)
```

详情

根据缓存 IrYieldCurve 为每个输入日期计算零利率；输出保持输入顺序。

参数

irCurveHandle STRING 类型。所引用具体类的 ObjectCache 句柄。**有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。

dates DATE 向量 类型。请求曲线值的日期；结果第 i 个元素对应 dates[i]。**有效性:** 必须是无空值 DATE 向量。单日使用单元素向量，多日使用更长向量；不接受 DATE 标量。

返回值

对应向量，DOUBLE 类型向量，元素顺序与输入一致。

**示例**

```dolphindb
loadPlugin("caplib")

irAsOfDate = 2022.03.09
irCurrency = "CNY"
irCurve = caplib::createIrYieldCurve(
    irAsOfDate, [2022.03.10, 2025.03.10], [0.02, 0.025],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", irCurrency, "CNY_SHIBOR_3M", "IR_CHAIN_CURVE", false)
caplib::getZeroRate(irCurve, [2025.03.10])
```

#### getFwdRate

语法

```dolphindb
caplib::getFwdRate(irCurveHandle, dates, tenor)
```

详情

计算从每个输入日期开始、对应给定年化期限的远期利率；输出保持日期顺序。

参数

irCurveHandle STRING 类型。所引用具体类的 ObjectCache 句柄。**有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。

dates DATE 向量 类型。请求曲线值的日期；结果第 i 个元素对应 dates[i]。**有效性:** 必须是无空值 DATE 向量。单日使用单元素向量，多日使用更长向量；不接受 DATE 标量。

tenor DOUBLE 类型。以年化比例表示的远期间隔。**有效性:** 业务有效值须严格为正且有限；包装器仅检查 DOUBLE 类型。

返回值

对应向量，DOUBLE 类型向量，元素顺序与输入一致。

**示例**

```dolphindb
loadPlugin("caplib")

irAsOfDate = 2022.03.09
irCurrency = "CNY"
irCurve = caplib::createIrYieldCurve(
    irAsOfDate, [2022.03.10, 2025.03.10], [0.02, 0.025],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", irCurrency, "CNY_SHIBOR_3M", "IR_CHAIN_CURVE", false)
caplib::getFwdRate(irCurve, [2025.03.10], 0.25)
```

#### createIrYieldCurve

语法

```dolphindb
caplib::createIrYieldCurve(asOfDate, pillarDates, pillarValues, curveType, dayCountConvention, interp, extrap, compounding, currency, name, handle[, returnJson])
```

详情

创建并缓存利率收益率曲线。函数验证并转换字段，构造 `IrYieldCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

pillarDates DATE 向量 类型。曲线节点日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

pillarValues DOUBLE 向量 类型。曲线节点值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

curveType STRING 类型。曲线值类型，例如零利率、贴现因子或利差。**有效性:** 可接受值：`ZERO_RATE`, `LOG_DISCOUNT`, `FORWARD_RATE`。仅接受所示精确拼写。

dayCountConvention STRING 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。

interp STRING 类型。插值方法。**有效性:** 可接受值：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。仅接受所示精确拼写。

extrap STRING 类型。外推方法。**有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。

compounding STRING 类型。复利约定。**有效性:** 可接受值：`CONTINUOUS_COMPOUNDING`, `DISCRETE_COMPOUNDING`, `SIMPLE_COMPOUNDING`。仅接受所示精确拼写。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrYieldCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
caplib::createIrYieldCurve(
    asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CNY", "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
```

#### createIrCurveRiskSettings

语法

```dolphindb
caplib::createIrCurveRiskSettings(delta, gamma, curvature, shift, curvatureShift, method, granularity, scaling, threading, handle[, returnJson])
```

详情

创建并缓存利率曲线风险设置。函数验证并转换字段，构造 `IrCurveRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

delta BOOL 类型。是否计算 Delta 风险或 Delta 数值。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

gamma BOOL 类型。是否计算 Gamma 风险。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

curvature BOOL 类型。是否计算曲率风险。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

shift DOUBLE 类型。风险或校准计算使用的扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

curvatureShift DOUBLE 类型。曲率风险使用的扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

method INT 类型。计算、校准或有限差分方法选择器。**有效性:** 映射：`value =2` 为 ONE_SIDE_UP。

granularity INT 类型。风险桶或扰动粒度。**有效性:** 映射：`value =2` 为 TERM_STRIKE。

scaling DOUBLE 类型。风险扰动缩放因子。**有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。

threading INT 类型。线程模式选择器。**有效性:** 仅 `1` 选择多线程；其他整数均为单线程。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrCurveRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createIrCurveRiskSettings(
    1, 0, 0, 1.0e-4, 5.0e-1, 0, 1, 1.0e-4, 0, "CR_IR_RISK", false)
```
#### createIrParRateCurve

语法

```dolphindb
caplib::createIrParRateCurve(asOfDate, currency, curveName, instNames, instTypes, instTerms, factors, quotes, handle[, returnJson])
```

详情

创建并缓存利率平价利率曲线输入。函数验证并转换字段，构造 `IrParRateCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

instNames STRING 向量 类型。与工具类型、期限和报价对齐的工具名称。**有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

instTypes STRING 向量 类型。构建曲线使用的工具类型数组。**有效性:** 每个元素必须是以下完整 protobuf 标签之一：`DEPOSIT`, `FORWARD_RATE_AGREEMENT`, `IR_VANILLA_SWAP`, `OVERNIGHT_INDEX_SWAP`, `CROSS_CURRENCY_SWAP`, `MTM_CROSS_CURRENCY_SWAP`, `STD_CROSS_CURRENCY_SWAP`, `IR_BOND`, `NON_DELIVERABLE_SWAP`, `IR_EUROPEAN_SWAPTION`, `IR_CAP_FLOOR`, `IR_FUTURE`, `IR_FUTURE_IMM`, `IR_FUTURE_ASX`, `IR_VANILLA_BOND`, `IMM_FORWARD_RATE_AGREEMENT`, `IR_BOND_OPTION`, `IR_RANGEACCRUAL_SWAP`, `IR_STRUCTURED_SWAP`, `FX_SPOT`, `FX_FORWARD`, `FX_NON_DELIVERABLE_FORWARD`, `FX_SWAP`, `FX_SWAP_ON`, `FX_SWAP_TN`, `FX_EUROPEAN_OPTION`, `FX_TIME_OPTION`, `FX_DIGITAL_OPTION`, `FX_QUANTO_OPTION`, `FX_TOUCH_OPTION`, `FX_BARRIER_OPTION`, `FX_VANILLA_STRATEGY`, `FX_TOUCH_QUANTO_OPTION`, `FX_DIGITAL_QUANTO_OPTION`, `EQ_INDEX_FUTURE`, `EQ_EUROPEAN_OPTION`, `EQ_AMERICAN_OPTION`, `EQ_SPOT`, `EQ_VANILLA_OPTION`, `EQ_DIGITAL_OPTION`, `EQ_BARRIER_OPTION`, `EQ_RANGE_ACCRUAL_OPTION`, `EQ_TOUCH_OPTION`, `EQ_QUANTO_OPTION`, `CM_SPOT`, `CM_FUTURE`, `CM_EUROPEAN_OPTION`, `CM_AMERICAN_OPTION`, `CM_VANILLA_OPTION`, `CM_ASIAN_OPTION`, `CM_DIGITAL_OPTION`, `CM_SWAP`, `CM_DIGITAL_ASIAN_OPTION`, `PM_SPOT`, `PM_SWAP`, `CREDIT_DEFAULT_SWAP`, `SPOT`, `FUTURE`, `FORWARD`, `SWAP`, `EUROPEAN_OPTION`, `AMERICAN_OPTION`。

instTerms STRING 向量 类型。与工具名称对齐的工具期限。**有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。

factors DOUBLE 向量 类型。与工具或报价对齐的缩放因子。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

quotes DOUBLE 向量 类型。市场报价值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrParRateCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2020.02.21
currency = "CNY"
curveName = "TREAS"
caplib::createCalendar("CAL_CFETS")
iborIndex = caplib::createIborIndex(
    "CNY_SHIBOR_3M", "3M", currency, ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)
caplib::createIrParRateCurve(
    asOfDate, currency, curveName,
    [iborIndex, curveName, curveName],
    ["DEPOSIT", "IR_VANILLA_SWAP", "IR_VANILLA_SWAP"],
    ["3M", "6M", "1Y"],
    [100.0, 100.0, 100.0],
    [0.023, 0.024, 0.026],
    "IR_PAR_CURVE", true)
```

#### createIrYieldCurveBuildSettings

语法

```dolphindb
caplib::createIrYieldCurveBuildSettings(curveName, useOnTnFxSwap, discountCurrencyNames, discountCurveNames, forwardIndexNames, forwardCurveNames, handle[, returnJson])
```

详情

创建并缓存利率收益率曲线构建设置。函数验证并转换字段，构造 `IrYieldCurveBuildSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

useOnTnFxSwap BOOL 类型。是否使用 ON/TN 外汇掉期工具构建曲线。**有效性:** 必须是非空 BOOL 标量；兼容旧示例的 INT `0/1`。字符串、空值及其他整数会抛错。

discountCurrencyNames STRING 向量 类型。币种代码。**有效性:** 必须具有所列元素类型和形状；元素不得为空；除明确说明外包装器不强制非空。

discountCurveNames STRING 向量 类型。贴现曲线名称数组。**有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

forwardIndexNames STRING 向量 类型。远期指数名称数组。**有效性:** 必须具有所列元素类型和形状；元素不得为空；除明确说明外包装器不强制非空。

forwardCurveNames STRING 向量 类型。远期曲线名称数组。**有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrYieldCurveBuildSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
curveName = "CNY_SHIBOR_3M"
caplib::createIrYieldCurveBuildSettings(
    curveName, 0, [currency], [curveName], [curveName], [curveName], "IR_BUILD_SETTINGS", true)
```

#### buildIrCrossCurrencyCurve

语法

```dolphindb
caplib::buildIrCrossCurrencyCurve(asOfDate, targetCurveNames, buildSettingsHandles, parCurveHandles, dayCountConvention, compoundingType, frequency, otherCurveHandles, fxSpotHandle, buildingMethod, calcJacobian, shift, finiteDifferenceMethod, threadingMode, targetCurveHandles, outputHandle[, returnJson])
```

详情

构建跨币种利率曲线组。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrCrossCurrencyCurveBuildingOutput`。
> **用法说明：** *targetCurveHandles* 为每个目标曲线提供输出句柄——构建完成后每条曲线以 `IrYieldCurve` 对象存入 ObjectCache，可直接传给 `getZeroRate`、`getDiscountFactor`、`getFwdRate` 等单曲线访问器使用；*outputHandle* 指向构建输出容器本身。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

targetCurveNames STRING 向量 类型。待构建目标曲线名称数组。**有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

buildSettingsHandles STRING 向量 类型。曲线构建设置 ObjectCache 句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

parCurveHandles STRING 向量 类型。平价曲线输入对象 ObjectCache 句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

dayCountConvention STRING 类型。计息惯例。**有效性:** 值必须是以下完整 protobuf 标签之一：`ACT_360`, `ACTUAL_360`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `ACT_ACT_ISMA`, `ACTUAL_ACTUAL_ISMA`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `THIRTY_360`, `BOND_BASIS`, `THIRTY_E_360`, `EUROBOND_BASIS`, `THIRTY_E_360_ISDA`, `ONE_ONE`, `THIRTY_U_360`, `THIRTY_U_360_EOM`, `THIRTY_360_PSA`, `THIRTY_E_360_PLUS`, `THIRTY_360_IT`, `ACT_ACT_AFB`, `ACTUAL_ACTUAL_AFB`, `ACT_364`, `ACTUAL_364`, `ACT_365_25`, `ACTUAL_365_25`, `ACT_365_ACT`, `ACTUAL_365_ACTUAL`, `ACT_365_L`, `ACTUAL_365_LONG`, `ACT_365_NL`, `ACTUAL_365_NO_LEAP`, `ACT_ACT_YEAR`, `ACTUAL_ACTUAL_YEAR`, `BUSINESS_252`。

compoundingType STRING 类型。复利类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`CONTINUOUS_COMPOUNDING`, `DISCRETE_COMPOUNDING`, `SIMPLE_COMPOUNDING`。

frequency STRING 类型。频率。**有效性:** 值必须是以下完整 protobuf 标签之一：`ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。

otherCurveHandles STRING 向量 类型。构建所需的其他曲线 ObjectCache 句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

fxSpotHandle STRING 类型。外汇即期汇率 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

buildingMethod STRING 类型。曲线或曲面构建算法名称。**有效性:** 值必须是以下完整 protobuf 标签之一：`BOOTSTRAPPING_METHOD`, `GLOBAL_OPTIMIZATION_METHOD`, `HYBRID_METHOD`。

calcJacobian BOOL 类型。是否计算并返回校准雅可比信息。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

shift DOUBLE 类型。风险或校准计算使用的扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

finiteDifferenceMethod STRING 类型。有限差分方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`CENTRAL_DIFFERENCE_METHOD`, `ONE_SIDE_DOWN_METHOD`, `ONE_SIDE_UP_METHOD`。

threadingMode STRING 类型。线程模式。**有效性:** 值必须是以下完整 protobuf 标签之一：`SINGLE_THREADING_MODE`, `MULTI_THREADING_MODE`。

targetCurveHandles STRING 向量 类型。构建输出的目标曲线句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

outputHandle STRING 类型。构建输出对象的缓存句柄。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrCrossCurrencyCurveBuildingOutput 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, CNY calendar and the domestic CNY curve
caplib::createCalendar("CAL_CFETS")
asOfDate = 2022.03.09
currency = "CNY"
curveName = "CNY_SHIBOR_3M"
irCurve = caplib::createIrYieldCurve(
    asOfDate, [2022.03.10, 2025.03.10], [0.02, 0.025],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, curveName, "IR_CURVE", false)

// USDCNY FX-swap par curve (points in pips, factor 10000) for the USD leg
parCurve = caplib::createIrParRateCurve(
    asOfDate, "USD", "USD_USDCNY_FX",
    take("USDCNY", 11), take("FX_SWAP", 11),
    ["ON", "TN", "1W", "1M", "2M", "3M", "6M", "9M", "12M", "2Y", "3Y"],
    take(10000, 11),
    [2.01, 3.91, 5.93, 22.5, 44.25, 63.25, 130.75, 194.75, 268.25, 1017.0, 2075.0],
    "USD_FX_PAR", false)

// Build settings: discount off the USD par curve and the CNY curve
buildSettings = caplib::createIrYieldCurveBuildSettings(
    "USD_USDCNY_FX", true, ["USD", "CNY"], ["USD_USDCNY_FX", curveName],
    [], [], "XCCY_BUILD_SETTINGS", false)

// Static-data templates and the USDCNY spot rate the build resolves
caplib::createFxSpotTemplate(
    "USDCNY_SPOT_TPL", "USDCNY", "FOLLOWING", ["CAL_CFETS"], "2d", false)
caplib::createFxSwapTemplate(
    "USDCNY_SWP_TPL", "SPOTSTART", "USDCNY", ["CAL_CFETS"],
    "FOLLOWING", "FOLLOWING", "-2d", "PRECEDING", false)
fxSpot = caplib::createFxSpotRate(
    6.6916, "CNY", "USD", asOfDate, asOfDate, "XCCY_FXSPOT", false)

// Bootstrap the USD_USDCNY_FX target curve from the FX-swap par curve
result = caplib::buildIrCrossCurrencyCurve(
    asOfDate, ["USD_USDCNY_FX"], [buildSettings], [parCurve],
    "ACT_365_FIXED", "CONTINUOUS_COMPOUNDING", "ANNUAL", [irCurve], fxSpot,
    "BOOTSTRAPPING_METHOD", false, 1.0e-4, "CENTRAL_DIFFERENCE_METHOD",
    "SINGLE_THREADING_MODE", ["XCCY_CURVE"], "XCCY_OUT", true)
```
#### createIrMktDataSet

语法

```dolphindb
caplib::createIrMktDataSet(asOfDate, discountCurveHandle, underlyingInterestRates, forwardCurveHandles, handle[, returnJson])
```

详情

创建并缓存利率市场数据集。函数验证并转换字段，构造 `IrMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

discountCurveHandle STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

underlyingInterestRates STRING 向量 类型。标的利率指数名称数组。**有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

forwardCurveHandles STRING 向量 类型。远期曲线 ObjectCache 句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrMktDataSet 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Register the CNY calendar and build the discount curve and index
caplib::createCalendar("CAL_CFETS")
asOfDate = 2022.03.09
currency = "CNY"
curveName = "CNY_SHIBOR_3M"
irCurve = caplib::createIrYieldCurve(
    asOfDate, [2022.03.10, 2025.03.10], [0.02, 0.025],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, curveName, "IR_CURVE", false)
iborIndex = caplib::createIborIndex(
    curveName, "3M", currency, ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)

// Market data set: irCurve discounts, iborIndex forward-set off the same curve
mktData = caplib::createIrMktDataSet(
    asOfDate, irCurve, [iborIndex[0]], [irCurve], "IR_MKT", false)
```

#### createIrCrossCcyMktDataSet

语法

```dolphindb
caplib::createIrCrossCcyMktDataSet(asOfDate, baseDiscountCurveHandle, underlyingInterestRates, forwardCurveHandles, crossCcyDiscountCurveHandle, fxSpotHandle, handle[, returnJson])
```

详情

创建并缓存跨币种利率市场数据集。函数验证并转换字段，构造 `IrCrossCcyMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

baseDiscountCurveHandle STRING 类型。基准币种贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

underlyingInterestRates STRING 向量 类型。标的利率指数名称数组。**有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

forwardCurveHandles STRING 向量 类型。远期曲线 ObjectCache 句柄数组。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

crossCcyDiscountCurveHandle STRING 类型。跨币种贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

fxSpotHandle STRING 类型。外汇即期汇率 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrCrossCcyMktDataSet 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Register the CNY calendar and build both currency curves and the index
caplib::createCalendar("CAL_CFETS")
asOfDate = 2022.03.09
currency = "CNY"
curveName = "CNY_SHIBOR_3M"
irCurve = caplib::createIrYieldCurve(
    asOfDate, [2022.03.10, 2025.03.10], [0.02, 0.025],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, curveName, "IR_CURVE", false)
iborIndex = caplib::createIborIndex(
    curveName, "3M", currency, ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)
usdCurve = caplib::createIrYieldCurve(
    asOfDate, [2022.03.10, 2025.03.10], [0.03, 0.035],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_SOFR", "USD_CURVE", false)

// USDCNY spot rate for the cross-currency leg
fxSpot = caplib::createFxSpotRate(
    6.9, "USD", "CNY", asOfDate, 2022.03.16, "FX_SPOT", false)

// CNY base discount curve + forward curve, USD cross-currency discount curve
mktData = caplib::createIrCrossCcyMktDataSet(
    asOfDate, irCurve, [iborIndex[0]], [irCurve], usdCurve, fxSpot,
    "IR_XCCY_MKT", false)
```

#### createIrRiskSettings

语法

```dolphindb
caplib::createIrRiskSettings(irCurveRiskSettingsHandle, thetaRiskSettingsHandle, handle[, returnJson])
```

详情

创建并缓存利率风险设置。函数验证并转换字段，构造 `IrRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

irCurveRiskSettingsHandle STRING 类型。利率曲线风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

thetaRiskSettingsHandle STRING 类型。Theta 风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// IR curve risk (delta/gamma with 1bp shift) and theta risk (1-day decay)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 1, 1.0e-4, 5.0e-3, 0, 1, 1.0e-4, 0, "IR_CURVE_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(
    1, 1, 1.0 / 365.0, "IR_THETA_RISK", false)

riskSettings = caplib::createIrRiskSettings(irCurveRisk, thetaRisk, "IR_RISK", false)
```

#### createXccyIrRiskSettings

语法

```dolphindb
caplib::createXccyIrRiskSettings(irCurveRiskSettingsHandle, fxRiskSettingsHandle, thetaRiskSettingsHandle, handle[, returnJson])
```

详情

创建并缓存跨币种利率风险设置。函数验证并转换字段，构造 `XccyIrRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

irCurveRiskSettingsHandle STRING 类型。利率曲线风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

fxRiskSettingsHandle STRING 类型。外汇风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

thetaRiskSettingsHandle STRING 类型。Theta 风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 XccyIrRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// IR curve risk, FX price risk and theta risk for the cross-currency setting
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 1, 1.0e-4, 5.0e-3, 0, 1, 1.0e-4, 0, "IR_CURVE_RISK", false)
fxRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0, 0, "IR_PRICE_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(
    1, 1, 1.0 / 365.0, "IR_THETA_RISK", false)

riskSettings = caplib::createXccyIrRiskSettings(
    irCurveRisk, fxRisk, thetaRisk, "IR_XCCY_RISK", false)
```

#### priceIrCrossCurrencySwap

语法

```dolphindb
caplib::priceIrCrossCurrencySwap(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

执行定价并返回定价结果。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, CNY calendar and the domestic CNY curve and index
caplib::createCalendar("CAL_CFETS")
asOfDate = 2022.03.09
currency = "CNY"
curveName = "CNY_SHIBOR_3M"
irCurve = caplib::createIrYieldCurve(
    asOfDate, [2022.03.10, 2025.03.10], [0.02, 0.025],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, curveName, "IR_CURVE", false)
iborIndex = caplib::createIborIndex(
    curveName, "3M", currency, ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)

// Fixed legs in both currencies assembled into a cross-currency swap template
cnyFixedLeg = caplib::createFixedLegDefinition(
    currency, "CAL_CFETS", "QUARTERLY", "ACT_365_FIXED",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "INVALID_NOTIONAL_EXCHANGE", "XCCY_CNY_LEG", false)
usdFixedLeg = caplib::createFixedLegDefinition(
    "USD", "CAL_CFETS", "QUARTERLY", "ACT_365_FIXED",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "INVALID_NOTIONAL_EXCHANGE", "XCCY_USD_LEG", false)
swapTemplate = caplib::createIrVanillaInstrumentTemplate(
    "CROSS_CURRENCY_SWAP", "XCCY_SWAP_TPL", "SPOTSTART", 1,
    [cnyFixedLeg[0], usdFixedLeg[0]], "XCCY_SWAP_TPL", false)

// Pay-CNY 1Y cross-currency swap on 1,000,000 CNY notional
xccySwap = caplib::buildIrVanillaInstrument(
    "PAY", 0.05, 0.0, 2022.03.07, 2023.03.07,
    swapTemplate[0], 1000000.0, "", "XCCY_SWAP", false)

// USDCNY spot rate, USD discount curve and cross-currency market data set
fxSpot = caplib::createFxSpotRate(
    6.6916, "CNY", "USD", asOfDate, asOfDate, "XCCY_FXSPOT", false)
usdCurve = caplib::createIrYieldCurve(
    asOfDate, [2022.03.10, 2025.03.10], [0.03, 0.035],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_SOFR", "USD_CURVE", false)
mktData = caplib::createIrCrossCcyMktDataSet(
    asOfDate, irCurve, [iborIndex[0]], [irCurve], usdCurve, fxSpot,
    "XCCY_MKT", false)

// Analytical pricing settings and cross-currency IR risk settings
pricingModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", "", 0, [0.0], "XCCY_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 1, 1, take(0, 0), pricingModel, "", "", "XCCY_PRICING", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 1, 1.0e-4, 5.0e-3, 0, 1, 1.0e-4, 0, "XCCY_CURVE_RISK", false)
fxRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0, 0, "XCCY_PRICE_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(
    1, 1, 1.0 / 365.0, "XCCY_THETA_RISK", false)
riskSettings = caplib::createXccyIrRiskSettings(
    irCurveRisk, fxRisk, thetaRisk, "XCCY_RISK", false)

result = caplib::priceIrCrossCurrencySwap(
    xccySwap, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```
#### createInterestCalcScheduleDefinition

语法

```dolphindb
caplib::createInterestCalcScheduleDefinition(calendars, frequency, interestDayConvention, stubPolicy, brokenPeriodType, dateRollConvention, handle[, returnJson])
```

详情

创建并缓存计息日程定义。函数验证并转换字段，构造 `InterestCaculationScheduleDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

参数

calendars STRING 类型。日期调整使用的业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

frequency STRING 类型。频率。**有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。任何其他字符串均回退到函数指定的默认频率。

interestDayConvention STRING 类型。计息日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

stubPolicy STRING 类型。短长首末期处理规则。**有效性:** 值必须是以下完整 protobuf 标签之一：`INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。

brokenPeriodType STRING 类型。不规则首末期处理类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`SHORT`, `LONG`。

dateRollConvention STRING 类型。日期或日期数组。**有效性:** 值必须是以下完整 protobuf 标签之一：`EOM`, `FRN`, `IMM`, `IMM_CAD`, `IMM_AUD`, `IMM_NZD`, `SFE`, `NONE`, `TBILL`。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestCaculationScheduleDefinition 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createInterestCalcScheduleDefinition(
    "CAL_CFETS", "QUARTERLY", "MODIFIED_FOLLOWING", "INITIAL", "LONG", "NONE", "IR_FIXED_CALC", false)
```

#### createInterestPaymentScheduleDefinition

语法

```dolphindb
caplib::createInterestPaymentScheduleDefinition(calendars, frequency, payDayMode, payDayOffset, payDayConvention, handle[, returnJson])
```

详情

创建并缓存付息日程定义。函数验证并转换字段，构造 `InterestPaymentScheduleDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

参数

calendars STRING 类型。日期调整使用的业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

frequency STRING 类型。频率。**有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。任何其他字符串均回退到函数指定的默认频率。

payDayMode STRING 类型。付款日生成模式。**有效性:** 值必须是以下完整 protobuf 标签之一：`IN_ADVANCE`, `IN_ARREAR`。

payDayOffset INT 类型。付款日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

payDayConvention STRING 类型。付款日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestPaymentScheduleDefinition 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createInterestPaymentScheduleDefinition(
    "CAL_CFETS", "QUARTERLY", "IN_ARREAR", 0, "MODIFIED_FOLLOWING", "IR_FIXED_PAY", false)
```

#### createInterestRateFixingScheduleDefinition

语法

```dolphindb
caplib::createInterestRateFixingScheduleDefinition(calendars, frequency, frequencyRatio, fixingDayMode, fixingDayOffset, fixingDayConvention, handle[, returnJson])
```

详情

创建并缓存利率定盘日程定义。函数验证并转换字段，构造 `InterestRateFixingScheduleDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

参数

calendars STRING 类型。日期调整使用的业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

frequency STRING 类型。频率。**有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。任何其他字符串均回退到函数指定的默认频率。

frequencyRatio INT 类型。频率换算比例。**有效性:** 必须严格为正；包装器通常仅检查类型。

fixingDayMode STRING 类型。定盘日生成模式。**有效性:** 值必须是以下完整 protobuf 标签之一：`IN_ADVANCE`, `IN_ARREAR`。

fixingDayOffset INT 类型。定盘日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

fixingDayConvention STRING 类型。定盘日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestRateFixingScheduleDefinition 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createInterestRateFixingScheduleDefinition(
    "CAL_CFETS", "QUARTERLY", 1, "IN_ADVANCE", -1, "MODIFIED_PRECEDING", "IR_FLOAT_FIX", false)
```

#### createIborIndex

语法

```dolphindb
caplib::createIborIndex(indexName, indexTenor, indexCcy, calendarList, startDelay[, dayCountConvention[, interestDayConvention[, dateRollConvention[, iborType]]]][, returnJson])
```

详情

创建并缓存 IBOR 指数定义。函数验证并转换字段，构造 `IborIndex` protobuf 并存入 ObjectCache，供后续分析使用。

参数

indexName STRING 类型。利率指数名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

indexTenor STRING 类型。利率指数期限。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

indexCcy STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

calendarList STRING 或 STRING 向量 类型。业务日历名称列表。**有效性:** 每个名称必须是已注册的非空日历标识。

startDelay INT 类型。起息或交割延迟天数。**有效性:** 非负整数（天数）。

dayCountConvention STRING, optional 类型。计息惯例。**有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。任何其他字符串均回退到函数指定的默认日计数。

interestDayConvention STRING, optional 类型。计息日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

dateRollConvention STRING, optional 类型。日期或日期数组。**有效性:** 值必须是以下完整 protobuf 标签之一：`EOM`, `FRN`, `IMM`, `IMM_CAD`, `IMM_AUD`, `IMM_NZD`, `SFE`, `NONE`, `TBILL`。

iborType STRING, optional 类型。IBOR 指数类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`STANDARD_IBOR_INDEX`, `OVERNIGHT_INDEX`。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IborIndex 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Register the business calendar referenced by the index
caplib::createCalendar("CAL_CFETS")

// 3M SHIBOR index: ACT_360 day count, modified-following adjustment
iborIndex = caplib::createIborIndex(
    "CNY_SHIBOR_3M", "3M", "CNY", ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)
```

#### createIrLegDefinition

语法

```dolphindb
caplib::createIrLegDefinition(legType, currency, dayCountConvention, refIndex, paymentDiscountMethod, rateCalcMethod, notionalExchange, spread, fxConvert, fxReset, calendar, freq, interestDayConvention, stubPolicy, brokenPeriodType, payDayOffset, payDayConvention, fixingCalendars, fixingFreq, fixingDayConvention, fixingMode, fixingDayOffset, handle[, returnJson])
```

详情

创建并缓存利率现金流腿定义。函数验证并转换字段，构造 `InterestRateLegDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

参数

legType STRING 类型。现金流腿类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`FIXED_LEG`, `FLOATING_LEG`, `FRA_LEG`, `STRUCTURED_LEG`。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

dayCountConvention STRING 类型。计息惯例。**有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。任何其他字符串均回退到函数指定的默认日计数。

refIndex STRING 类型。参考利率指数名称或句柄。**有效性:** 固定腿传空字符串即可；浮动腿/FRA 腿须为可解析的参考指数。包装器不验证业务标识的字符集或成员资格。

paymentDiscountMethod STRING 类型。支付现金流贴现方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`NO_DISCOUNT`, `DISCOUNT_AT_FLOATING_RATE`。

rateCalcMethod STRING 类型。利率计算方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`STANDARD`, `COMPOUND_AVERAGE`, `ARITHMETIC_AVERAGE`。

notionalExchange STRING 类型。是否交换名义本金。**有效性:** 值必须是以下完整 protobuf 标签之一：`INITIAL_EXCHANGE`, `INTERMEDIATE_EXCHANGE`, `INITIAL_INTERMEDIATE_EXCHANGE`, `FINAL_EXCHANGE`, `INITIAL_FINAL_EXCHANGE`, `INTERMEDIATE_FINAL_EXCHANGE`, `INITIAL_INTERMEDIATE_FINAL_EXCHANGE`。

spread BOOL 类型。是否将输入利率作为利差处理。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

fxConvert BOOL 类型。是否进行外汇折算。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

fxReset BOOL 类型。是否使用外汇重置。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

calendar STRING 或 STRING 向量 类型。业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

freq STRING 类型。支付或计息频率。**有效性:** 可接受值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

interestDayConvention STRING 类型。计息日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

stubPolicy STRING 类型。短长首末期处理规则。**有效性:** 值必须是以下完整 protobuf 标签之一：`INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。

brokenPeriodType STRING 类型。不规则首末期处理类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`SHORT`, `LONG`。

payDayOffset INT 类型。付款日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

payDayConvention STRING 类型。付款日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

fixingCalendars STRING 或 STRING 向量 类型。定盘日业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

fixingFreq STRING 类型。定盘频率。**有效性:** 可接受值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

fixingDayConvention STRING 类型。定盘日调整约定。**有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。其他字符串会回退到该函数的默认/无效哨兵。

fixingMode STRING 类型。定盘值处理方式。**有效性:** 值必须是以下完整 protobuf 标签之一：`IN_ADVANCE`, `IN_ARREAR`。

fixingDayOffset INT 类型。定盘日偏移天数。**有效性:** 必须是 INT；除非另有说明，可为负、零或正。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestRateLegDefinition 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createIrLegDefinition(
    "FIXED_LEG", "CNY", "ACT_365_FIXED", "",
    "NO_DISCOUNT", "STANDARD", "INITIAL_EXCHANGE",
    false, false, false, "CAL_CFETS", "QUARTERLY",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG", 0, "MODIFIED_FOLLOWING",
    "CAL_CFETS", "QUARTERLY", "MODIFIED_PRECEDING", "IN_ADVANCE", 0,
    "TF_IR_LEG", true)
```

#### createIrVanillaInstrumentTemplate

语法

```dolphindb
caplib::createIrVanillaInstrumentTemplate(instType, instName, startConvention, startDelay, legDefinitions, handle[, returnJson])
```

详情
> **服务端支持范围（实测）：** 下列 25 个类型会被静态数据服务拒收（`not find value`），不能用于本接口：FX_TIME_OPTION、FX_DIGITAL_OPTION、FX_QUANTO_OPTION、FX_TOUCH_OPTION、FX_BARRIER_OPTION、FX_VANILLA_STRATEGY、FX_TOUCH_QUANTO_OPTION、FX_DIGITAL_QUANTO_OPTION（FX 期权族）；EQ_EUROPEAN_OPTION、EQ_AMERICAN_OPTION、EQ_SPOT、EQ_VANILLA_OPTION、EQ_DIGITAL_OPTION、EQ_BARRIER_OPTION、EQ_RANGE_ACCRUAL_OPTION、EQ_TOUCH_OPTION、EQ_QUANTO_OPTION（权益）；CM_EUROPEAN_OPTION、CM_AMERICAN_OPTION、CM_VANILLA_OPTION、CM_ASIAN_OPTION、CM_DIGITAL_OPTION、CM_DIGITAL_ASIAN_OPTION（商品期权）；PM_SPOT、PM_SWAP（贵金属）。其余 IR 域类型（DEPOSIT、FRA、IR_VANILLA_SWAP、IR_CAP_FLOOR、IR_BOND、IR_FUTURE*、IR_EUROPEAN_SWAPTION 等）与 FX 即期/远期/掉期/NDF 均可注册。

创建并缓存标准利率工具模板。函数验证并转换字段，构造 `InterestRateInstrumentTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

参数

instType STRING 类型。工具类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`DEPOSIT`, `FORWARD_RATE_AGREEMENT`, `IR_VANILLA_SWAP`, `OVERNIGHT_INDEX_SWAP`, `CROSS_CURRENCY_SWAP`, `MTM_CROSS_CURRENCY_SWAP`, `STD_CROSS_CURRENCY_SWAP`, `IR_BOND`, `NON_DELIVERABLE_SWAP`, `IR_EUROPEAN_SWAPTION`, `IR_CAP_FLOOR`, `IR_FUTURE`, `IR_FUTURE_IMM`, `IR_FUTURE_ASX`, `IR_VANILLA_BOND`, `IMM_FORWARD_RATE_AGREEMENT`, `IR_BOND_OPTION`, `IR_RANGEACCRUAL_SWAP`, `IR_STRUCTURED_SWAP`, `FX_SPOT`, `FX_FORWARD`, `FX_NON_DELIVERABLE_FORWARD`, `FX_SWAP`, `FX_SWAP_ON`, `FX_SWAP_TN`, `FX_EUROPEAN_OPTION`, `EQ_INDEX_FUTURE`, `CM_SPOT`, `CM_FUTURE`, `CM_SWAP`, `CREDIT_DEFAULT_SWAP`, `SPOT`, `FUTURE`, `FORWARD`, `SWAP`, `EUROPEAN_OPTION`, `AMERICAN_OPTION`。

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

startConvention STRING 类型。工具起息约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`SPOTSTART`, `TODAYSTART`, `TOMORROWSTART`。

startDelay INT 类型。起息或交割延迟天数。**有效性:** 非负整数（天数）。

legDefinitions STRING 向量 类型。现金流腿定义对象或句柄数组。**有效性:** 必须具有所列元素类型和形状；元素不得为空；除明确说明外包装器不强制非空。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestRateInstrumentTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Register the CNY calendar and the 3M SHIBOR index
caplib::createCalendar("CAL_CFETS")
currency = "CNY"
curveName = "CNY_SHIBOR_3M"
iborIndex = caplib::createIborIndex(
    curveName, "3M", currency, ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)

// Fixed and floating leg definitions
fixedLeg = caplib::createFixedLegDefinition(
    currency, "CAL_CFETS", "QUARTERLY", "ACT_365_FIXED",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "INVALID_NOTIONAL_EXCHANGE", "IR_FIXED_LEG", false)
floatingLeg = caplib::createFloatingLegDefinition(
    currency, iborIndex[0], "CAL_CFETS", ["CAL_CFETS"],
    "QUARTERLY", "QUARTERLY", "ACT_360",
    "NO_DISCOUNT", "STANDARD", false,
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "MODIFIED_PRECEDING",
    "IN_ADVANCE", -1, "INVALID_NOTIONAL_EXCHANGE", "IR_FLOATING_LEG", false)

// Vanilla swap template holding both legs
swapTemplate = caplib::createIrVanillaInstrumentTemplate(
    "IR_VANILLA_SWAP", "CNY_SWAP_TPL", "SPOTSTART", 1,
    [fixedLeg[0], floatingLeg[0]], "CNY_SWAP_TPL", false)
```

#### createIrVanillaSwapTemplate

语法

```dolphindb
caplib::createIrVanillaSwapTemplate(instName, startDelay INT or, leg1Definition, leg2Definition, startConvention[, returnJson])
```

详情

创建并缓存标准利率互换模板。函数验证并转换字段，构造 `InterestRateInstrumentTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

参数

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

startDelay INT 或 STRING 类型。起息或交割延迟天数。**有效性:** INT 输入按天计，无需单位；STRING 输入为带可选正负号的整数和可选单位 `Y/M/W/D`（或完整英文单位），省略单位时按天计，负号会被保留。

leg1Definition STRING 类型。第一条现金流腿定义对象或句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

leg2Definition STRING 类型。第二条现金流腿定义对象或句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

startConvention STRING 类型。工具起息约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`SPOTSTART`, `TODAYSTART`, `TOMORROWSTART`。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 InterestRateInstrumentTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createCalendar("CAL_CFETS")
currency = "CNY"
curveName = "CNY_SWAP_TPL"
iborIndex = caplib::createIborIndex(
    "CNY_SHIBOR_3M", "3M", currency, ["CAL_CFETS"], 1,
    "ACT_360", "MODIFIED_FOLLOWING",
    "INVALID_DATE_ROLL_CONVENTION", "STANDARD_IBOR_INDEX", false)
fixedLeg = caplib::createFixedLegDefinition(
    currency, "CAL_CFETS", "QUARTERLY", "ACT_365_FIXED",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "INVALID_NOTIONAL_EXCHANGE", "IR_FIXED_LEG", false)
floatingLeg = caplib::createFloatingLegDefinition(
    currency, iborIndex, "CAL_CFETS", ["CAL_CFETS"],
    "QUARTERLY", "QUARTERLY", "ACT_360",
    "NO_DISCOUNT", "STANDARD", false,
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "MODIFIED_PRECEDING",
    "IN_ADVANCE", -1, "INVALID_NOTIONAL_EXCHANGE", "IR_FLOATING_LEG", false)
caplib::createIrVanillaSwapTemplate(
    curveName, 1, fixedLeg, floatingLeg, "SPOTSTART", true)
```

#### createFlatIrYieldCurve

语法

```dolphindb
caplib::createFlatIrYieldCurve(asOfDate, currency, rate, handle[, returnJson])
```

详情

创建零利率 IR 曲线，在整个期限范围应用同一连续复利年利率。函数验证并转换字段，构造 `IrYieldCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

rate DOUBLE 类型。利率或票息率。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 IrYieldCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
caplib::createFlatIrYieldCurve(asOfDate, "CNY", 0.02, "AN_FLAT_IR_CURVE", false)
```

### 外汇
#### calcFxAtmStrike

语法

```dolphindb
caplib::calcFxAtmStrike(atmType, expiryDate, volSurfaceHandle, fxSpotRateHandle, domesticDiscountCurveHandle, foreignDiscountCurveHandle)
```

详情

根据缓存 FX 波动率曲面、现货报价和两条贴现曲线计算到期日 atmType 执行价。

参数

atmType STRING 类型。ATM 行权价约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`ATM_FORWARD`, `ATM_DNS_PIPS`, `ATM_DNS_PERCENTAGE`, `ATM_SPOT`。

expiryDate DATE 类型。该计算使用的日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

volSurfaceHandle STRING 类型。FxVolatilitySurface 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

fxSpotRateHandle STRING 类型。FxSpotRate 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

domesticDiscountCurveHandle STRING 类型。domestic IrYieldCurve 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

foreignDiscountCurveHandle STRING 类型。foreign IrYieldCurve 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

返回值

计算结果，DOUBLE 类型标量。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.03.30
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// Smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
builtVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)

caplib::calcFxAtmStrike(
    "ATM_DNS_PIPS", 2021.09.26, builtVolSurface, eurusdSpotRate, usdCurve, eurCurve)
```

#### calcFxDeltaToStrike

语法

```dolphindb
caplib::calcFxDeltaToStrike(deltaType, delta, expiryDate, volSurfaceHandle, fxSpotRateHandle, domesticDiscountCurveHandle, foreignDiscountCurveHandle)
```

详情

反解所选 FX Delta 约定得到执行价；负 Delta 选择 PUT，非负 Delta 选择 CALL。

参数

deltaType STRING 类型。外汇 Delta 约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。

delta DOUBLE 类型。带符号的期权 Delta；负值选择 PUT，非负值选择 CALL。**有效性:** 必须为有限数，业务有效范围为 `(-1,0) ∪ (0,1)`；包装器仅检查 DOUBLE 类型。

expiryDate DATE 类型。该计算使用的日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

volSurfaceHandle STRING 类型。FxVolatilitySurface 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

fxSpotRateHandle STRING 类型。FxSpotRate 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

domesticDiscountCurveHandle STRING 类型。domestic IrYieldCurve 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

foreignDiscountCurveHandle STRING 类型。foreign IrYieldCurve 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

返回值

计算结果，DOUBLE 类型标量。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.03.30
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// Smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
builtVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)

caplib::calcFxDeltaToStrike(
    "PIPS_SPOT_DELTA", 0.25, 2021.09.26, builtVolSurface, eurusdSpotRate, usdCurve, eurCurve)
```

#### createFxOptionQuoteMatrix

语法

```dolphindb
caplib::createFxOptionQuoteMatrix(leftCcy, rightCcy, asOfDate, terms, quoteNames, quotes, handle[, returnJson])
```

详情

创建并缓存外汇期权报价矩阵。函数验证并转换字段，构造 `FxOptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

参数

leftCcy STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

rightCcy STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

terms STRING 向量 类型。报价期限数组。**有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。

quoteNames STRING 向量 类型。报价名称或微笑报价标签。**有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

quotes DOUBLE 矩阵 类型。市场报价值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxOptionQuoteMatrix 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// EURUSD smile quotes (ATM and 25-delta risk reversal / butterfly)
asOfDate = 2021.03.30
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, ["1W", "1M", "3M"], ["ATM", "D25_RR", "D25_BF"],
    matrix([0.05515, 0.06115, 0.06135], [-0.00290, -0.00248, -0.00180], [0.00135, 0.00147, 0.00205]),
    "EURUSD_OPTION_QUOTES", true)
```

#### createFlatFxVolatilitySurface

语法

```dolphindb
caplib::createFlatFxVolatilitySurface(asOfDate, currencyPair, vol, handle[, returnJson])
```

详情

创建并缓存平坦外汇波动率曲面。函数验证并转换字段，构造 `FxVolatilitySurface` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

currencyPair STRING 类型。货币对标识，通常为基准币种/目标币种格式。**有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。

vol DOUBLE 类型。波动率数值。**有效性:** 必须非负且有限；包装器通常仅检查类型。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxVolatilitySurface 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
caplib::createFlatFxVolatilitySurface(
    asOfDate, "USDCNH", 0.0, "USDCNH_FLAT_FX_VOL_SURF", true)
```

#### createFxVolatilitySurface

语法

```dolphindb
caplib::createFxVolatilitySurface(asOfDate, leftCcy, rightCcy, termDates, strikes, volatilities, definitionHandle, marketConventionsHandle, handle[, returnJson])
```

详情

创建并缓存外汇波动率曲面。函数验证并转换字段，构造 `FxVolatilitySurface` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

leftCcy STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

rightCcy STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

termDates DATE 向量 类型。报价期限对应的到期日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

strikes DOUBLE 矩阵/向量 类型。行权价数组或矩阵。**有效性:** 必须有限；价格型标的通常要求非负，利率型标的可为负。包装器仅检查类型/形状。

volatilities DOUBLE 矩阵/向量 类型。波动率数组或矩阵。**有效性:** 必须具有所列元素类型和形状；数值必须非负且有限；除明确说明外包装器不强制非空。

definitionHandle STRING 类型。波动率曲面定义 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

marketConventionsHandle STRING 类型。市场惯例 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxVolatilitySurface 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Volatility surface definition and FX market conventions
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "LINEAR_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "ABSOLUTE_STRIKE",
    1.0e-4, 1.0e4, "FX_LINEAR_VOL_SURF_DEF", false)
fxMktConventions = caplib::createFxMktConventions(
    "EURUSD", "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)

// Three-strike flat smile for a single term date
asOfDate = 2021.03.30
eurusdSpot = 1.1761
termDates = [2021.06.30]
strikes = [1.00, eurusdSpot, 1.35]
volatilities = [0.06, 0.06, 0.06]
fxVolSurface = caplib::createFxVolatilitySurface(
    asOfDate, "EUR", "USD", termDates, strikes, volatilities,
    volDef, fxMktConventions, "EURUSD_VOL_SURF", true)
```

#### buildFxVolatilitySurface

语法

```dolphindb
caplib::buildFxVolatilitySurface(asOfDate, leftCcy, rightCcy, marketConventionsHandle, quoteMatrixHandle, spotRate, spotRefDate, spotDate, domesticDiscountCurveHandle, foreignDiscountCurveHandle, definitionHandle, buildSettingsHandle, handle[, returnJson])
```

详情

构建外汇波动率曲面。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `FxVolatilitySurface`。

参数

asOfDate DATE 类型。该计算使用的日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

leftCcy STRING 类型。货币对的左侧币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

rightCcy STRING 类型。货币对的右侧币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

marketConventionsHandle STRING 类型。FxMarketConventions 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

quoteMatrixHandle STRING 类型。FxOptionQuoteMatrix 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

spotRate DOUBLE 类型。外汇即期汇率。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

spotRefDate DATE 类型。该计算使用的日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

spotDate DATE 类型。该计算使用的日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

domesticDiscountCurveHandle STRING 类型。domestic IrYieldCurve 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

foreignDiscountCurveHandle STRING 类型。foreign IrYieldCurve 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

definitionHandle STRING 类型。VolatilitySurfaceDefinition 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

buildSettingsHandle STRING 类型。VolatilitySurfaceBuildSettings 的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。所构建曲面的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。是否同时返回 JSON 的标志。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxVolatilitySurface 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date and spot rate
asOfDate = 2021.03.30
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)

// FX market conventions and SVI smile definition
fxMktConventions = caplib::createFxMktConventions(
    "EURUSD", "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)

// Six-tenor EURUSD option quote matrix (ATM + 25/10-delta RR and BF)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)

// Build the smile surface from the quote matrix
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", true)
```

#### priceFxForward

语法

```dolphindb
caplib::priceFxForward(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇远期工具。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)
flatVolSurface = caplib::createFlatFxVolatilitySurface(
    asOfDate, "EURUSD", 0.0, "EURUSD_FLAT_FX_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, flatVolSurface, "", "EURUSD_MKT", false)

// Analytical pricing settings and FX risk settings
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), "", "", "", "FX_CASH_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
volRisk = caplib::createVolRiskSettings(
    1, 1, 1.0e-2, 0, 0, 1.0e-2, 0, "FX_VOL_RISK", false)
priceVolRisk = caplib::createPriceVolRiskSettings(
    1, 1.0e-2, 1.0e-2, 0, 0, 1.0e-2, 1.0e-2, 0, "FX_PRICE_VOL_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(1, 1, 1.0 / 365.0, "FX_THETA_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, volRisk, priceVolRisk, thetaRisk, "", "FX_RISK", false)

// Forward: buy EUR 1,000,000 against USD at 1.1761
forwardInst = caplib::createFxForward(
    "EUR", 1000000.0, "USD", 1176100.0, 2021.07.01, 2021.06.30, "FX_FWD", false)
result = caplib::priceFxForward(
    forwardInst, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxSwap

语法

```dolphindb
caplib::priceFxSwap(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇掉期工具。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)
flatVolSurface = caplib::createFlatFxVolatilitySurface(
    asOfDate, "EURUSD", 0.0, "EURUSD_FLAT_FX_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, flatVolSurface, "", "EURUSD_MKT", false)

// Analytical pricing settings and FX risk settings
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), "", "", "", "FX_CASH_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
volRisk = caplib::createVolRiskSettings(
    1, 1, 1.0e-2, 0, 0, 1.0e-2, 0, "FX_VOL_RISK", false)
priceVolRisk = caplib::createPriceVolRiskSettings(
    1, 1.0e-2, 1.0e-2, 0, 0, 1.0e-2, 1.0e-2, 0, "FX_PRICE_VOL_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(1, 1, 1.0 / 365.0, "FX_THETA_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, volRisk, priceVolRisk, thetaRisk, "", "FX_RISK", false)

// Swap: near leg buy EUR / sell USD at spot, far leg reversed in 3 months
swapInst = caplib::createFxSwap(
    "EUR", 1000000.0, "USD", 1176100.0, 2021.04.01, 2021.03.31,
    "USD", 1000000.0, "EUR", 1176100.0, 2021.07.01, 2021.06.30, "FX_SWAP_INST", false)
result = caplib::priceFxSwap(
    swapInst, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxNonDeliverableForward

语法

```dolphindb
caplib::priceFxNonDeliverableForward(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇无本金交割远期工具。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
usdcnhSpot = 6.7

// CNH (domestic) and USD (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
cnhCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.01, 2021.09.30, 2022.03.31, 2023.03.31, 2026.03.31, 2031.03.31],
    [0.01825, 0.02770, 0.02958, 0.03150, 0.03497, 0.03814],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CNH", "CNH_USDCNH_FX", "CNH_USDCNH_FX", false)
usdcnhSpotRate = caplib::createFxSpotRate(
    usdcnhSpot, "USD", "CNH", asOfDate, 2021.04.01, "USDCNH_SPOT_RATE", false)
flatVolSurface = caplib::createFlatFxVolatilitySurface(
    asOfDate, "USDCNH", 0.0, "USDCNH_FLAT_FX_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, cnhCurve, usdCurve, usdcnhSpotRate, flatVolSurface, "", "USDCNH_MKT", false)

// Analytical pricing settings and FX risk settings
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), "", "", "", "FX_CASH_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
volRisk = caplib::createVolRiskSettings(
    1, 1, 1.0e-2, 0, 0, 1.0e-2, 0, "FX_VOL_RISK", false)
priceVolRisk = caplib::createPriceVolRiskSettings(
    1, 1.0e-2, 1.0e-2, 0, 0, 1.0e-2, 1.0e-2, 0, "FX_PRICE_VOL_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(1, 1, 1.0 / 365.0, "FX_THETA_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, volRisk, priceVolRisk, thetaRisk, "", "FX_RISK", false)

// NDF: buy USD 10,000 against CNH, cash-settled in USD
ndfInst = caplib::createFxNonDeliverableForward(
    "USD", 10000.0, "CNH", 66916.0, "USD", 2021.07.01, 2021.06.30, "FX_NDF_INST", false)
result = caplib::priceFxNonDeliverableForward(
    ndfInst, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```
#### priceFxEuropeanOption

语法

```dolphindb
caplib::priceFxEuropeanOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇欧式期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM analytical pricing settings and FX risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "FX_BSM_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// European call on EURUSD spot
europeanOption = caplib::createEuropeanOption("CALL", eurusdSpot, 2021.09.26, 2021.09.27,
    1000000.0, currency, "SPOT", currency, underlying, "FX_EUROPEAN", false)
result = caplib::priceFxEuropeanOption(
    europeanOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxAmericanOption

语法

```dolphindb
caplib::priceFxAmericanOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇美式期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM analytical pricing settings and FX risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "FX_BSM_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// American call on EURUSD spot
americanOption = caplib::createAmericanOption("CALL", eurusdSpot, 2021.09.26, 2021.09.27,
    1, 1000000.0, currency, "SPOT", currency, underlying, "FX_AMERICAN", false)
result = caplib::priceFxAmericanOption(
    americanOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxAsianOption

语法

```dolphindb
caplib::priceFxAsianOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇亚式期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM analytical pricing settings and FX risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "FX_BSM_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Discrete daily observation schedule
dailyObsDates = 2021.03.31..2021.09.26
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))

// Arithmetic-average Asian call with fixed strike
asianOption = caplib::createAsianOption("CALL", eurusdSpot, 2021.09.26, 2021.09.27,
    "FIXED_STRIKE", "ARITHMETIC_AVERAGE_METHOD", "DISCRETE_OBSERVATION_TYPE",
    1000000.0, currency, "SPOT", currency, underlying, "FX_ASIAN",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceFxAsianOption(
    asianOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxDigitalOption

语法

```dolphindb
caplib::priceFxDigitalOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇数字期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM analytical pricing settings and FX risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "FX_BSM_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Cash-or-nothing digital call
digitalOption = caplib::createDigitalOption("CALL", eurusdSpot, 2021.09.26, 2021.09.27,
    0.0, 1.0, 1000000.0, currency, "SPOT", currency, underlying, "FX_DIGITAL", false)
result = caplib::priceFxDigitalOption(
    digitalOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxOneTouchOption

语法

```dolphindb
caplib::priceFxOneTouchOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇单触碰期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM analytical pricing settings and FX risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "FX_BSM_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// One-touch knock-in paying at maturity, barrier 5% above spot
oneTouchOption = caplib::createOneTouchOption(2021.09.26, 2021.09.27, "UP_IN",
    eurusdSpot*1.05, "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    1.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying, "FX_ONE_TOUCH", false)
result = caplib::priceFxOneTouchOption(
    oneTouchOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxDoubleTouchOption

语法

```dolphindb
caplib::priceFxDoubleTouchOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇双触碰期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM analytical pricing settings and FX risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "FX_BSM_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Double-touch with barriers 5% below and above spot
doubleTouchOption = caplib::createDoubleTouchOption(2021.09.26, 2021.09.27,
    "DOWN_IN", eurusdSpot*0.95, "UP_IN", eurusdSpot*1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    1.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying, "FX_DOUBLE_TOUCH", false)
result = caplib::priceFxDoubleTouchOption(
    doubleTouchOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxSingleBarrierOption

语法

```dolphindb
caplib::priceFxSingleBarrierOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇单障碍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM analytical pricing settings and FX risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "FX_BSM_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Up-and-in single-barrier call, barrier 5% above spot
singleBarrierOption = caplib::createSingleBarrierOption("CALL", eurusdSpot, 2021.09.26,
    2021.09.27, "UP_IN", eurusdSpot*1.05, "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying, "FX_BARRIER", false)
result = caplib::priceFxSingleBarrierOption(
    singleBarrierOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxDoubleBarrierOption

语法

```dolphindb
caplib::priceFxDoubleBarrierOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇双障碍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM analytical pricing settings and FX risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "FX_BSM_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Double-barrier call with barriers 5% below and above spot
doubleBarrierOption = caplib::createDoubleBarrierOption("CALL", eurusdSpot, 2021.09.26,
    2021.09.27, "DOWN_IN", eurusdSpot*0.95, "UP_IN", eurusdSpot*1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 0.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying,
    "FX_DOUBLE_BARRIER", false)
result = caplib::priceFxDoubleBarrierOption(
    doubleBarrierOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxSingleSharkFinOption

语法

```dolphindb
caplib::priceFxSingleSharkFinOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇单鲨鱼鳍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM PDE pricing settings and FX risk settings
modelParams = [0.0]
pdeSettings = caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "FX_PDE_SETTINGS", false)
bsmPdeModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 1, modelParams, "FX_BSM_PDE_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "PDE", 0, 0, take(0, 0), bsmPdeModel, pdeSettings, "", "FX_BSM_PDE", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Discrete daily observation schedule
dailyObsDates = 2021.03.31..2021.09.26
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))

// Up-and-out single shark-fin call, barrier 5% above spot
singleSharkFinOption = caplib::createSingleSharkFinOption("CALL", eurusdSpot,
    2021.09.26, 2021.09.27, 1.0, "RELATIVE_PERFORM_TYPE", "UP_OUT", eurusdSpot*1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying, "FX_SHARKFIN",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceFxSingleSharkFinOption(
    singleSharkFinOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxDoubleSharkFinOption

语法

```dolphindb
caplib::priceFxDoubleSharkFinOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇双鲨鱼鳍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM PDE pricing settings and FX risk settings
modelParams = [0.0]
pdeSettings = caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "FX_PDE_SETTINGS", false)
bsmPdeModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 1, modelParams, "FX_BSM_PDE_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "PDE", 0, 0, take(0, 0), bsmPdeModel, pdeSettings, "", "FX_BSM_PDE", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Discrete daily observation schedule
dailyObsDates = 2021.03.31..2021.09.26
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))

// Double shark-fin with barriers 5% below and above spot
doubleSharkFinOption = caplib::createDoubleSharkFinOption(eurusdSpot, eurusdSpot,
    2021.09.26, 2021.09.27, 1.0, 1.0, "ABSOLUTE_PERFORM_TYPE",
    eurusdSpot*0.95, eurusdSpot*1.05, "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 0.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying,
    "FX_DOUBLE_SHARKFIN", dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceFxDoubleSharkFinOption(
    doubleSharkFinOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxPingPongOption

语法

```dolphindb
caplib::priceFxPingPongOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇乒乓期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM Monte Carlo pricing settings and FX risk settings
modelParams = [0.0]
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 365, "FX_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MC_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "FX_BSM_MC", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Discrete daily observation schedule
dailyObsDates = 2021.03.31..2021.09.26
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))

// Ping-pong with barriers 5% below and above spot
pingPongOption = caplib::createPingPongOption(2021.09.26, 2021.09.27,
    "DOWN_IN", eurusdSpot*0.95, "UP_IN", eurusdSpot*1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.015, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying, "FX_PING_PONG",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceFxPingPongOption(
    pingPongOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxAirbagOption

语法

```dolphindb
caplib::priceFxAirbagOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇安全气囊期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM PDE pricing settings and FX risk settings
modelParams = [0.0]
pdeSettings = caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "FX_PDE_SETTINGS", false)
bsmPdeModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 1, modelParams, "FX_BSM_PDE_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "PDE", 0, 0, take(0, 0), bsmPdeModel, pdeSettings, "", "FX_BSM_PDE", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Discrete daily observation schedule
dailyObsDates = 2021.03.31..2021.09.26
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))

// Airbag call with knock-in barrier 20% below spot
airbagOption = caplib::createAirbagOption("CALL", 2021.09.26, 2021.09.27,
    eurusdSpot, eurusdSpot*1.05, 1.0, 1.0, eurusdSpot, "DOWN_IN", eurusdSpot*0.8,
    "DISCRETE_OBSERVATION_TYPE", 1000000.0, currency, "SPOT", currency, underlying,
    "FX_AIRBAG", dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceFxAirbagOption(
    airbagOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxRangeAccrualOption

语法

```dolphindb
caplib::priceFxRangeAccrualOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇区间累计期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM analytical pricing settings and FX risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "FX_BSM_ANALYTICAL", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Discrete daily observation schedule
dailyObsDates = 2021.03.31..2021.09.26
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))

// Range accrual paying 1% per day inside the range
rangeAccrualOption = caplib::createRangeAccrualOption(2021.09.26, 2021.09.27,
    0.0, 0.01, eurusdSpot*0.95, eurusdSpot*1.05, 1000000.0, currency, "SPOT",
    currency, underlying, "FX_RANGE_ACCRUAL",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceFxRangeAccrualOption(
    rangeAccrualOption, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxPhoenixAutoCallableNote

语法

```dolphindb
caplib::priceFxPhoenixAutoCallableNote(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇凤凰自动赎回票据。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM Monte Carlo pricing settings and FX risk settings
modelParams = [0.0]
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 365, "FX_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MC_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "FX_BSM_MC", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Semi-annual coupon observation and daily monitoring schedules
couponObsDates = [2021.06.30, 2021.09.26]
couponObsValues = take(0.0, size(couponObsDates))
couponObsWeights = take(1.0, size(couponObsDates))
dailyObsDates = 2021.03.31..2021.09.26
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))

// Phoenix auto-callable note, 12% coupon, ±10% barriers, 0.85-strike short put
phoenixNote = caplib::createPhoenixAutoCallableNote("CALL", eurusdSpot, 0.12,
    "ACT_365_FIXED", 2021.04.01, couponObsDates, "UP_OUT", eurusdSpot*1.1,
    "DOWN_IN", eurusdSpot*0.9, "SELL", "PUT", eurusdSpot*0.85, 2021.09.26, 2021.09.27,
    1, 1000000.0, currency, "SPOT", currency, underlying, "FX_PHOENIX",
    couponObsDates, couponObsValues, couponObsWeights,
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceFxPhoenixAutoCallableNote(
    phoenixNote, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### priceFxSnowballAutoCallableNote

语法

```dolphindb
caplib::priceFxSnowballAutoCallableNote(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价外汇雪球自动赎回票据。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, currency pair and spot rate
asOfDate = 2021.03.30
currency = "USD"
underlying = "EURUSD"
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// BSM Monte Carlo pricing settings and FX risk settings
modelParams = [0.0]
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 365, "FX_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", underlying, 0, modelParams, "FX_BSM_MC_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "FX_BSM_MC", false)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, "", "", "", "", "FX_OPTION_RISK", false)

// Build the smile surface from a six-tenor option quote matrix
fxMktConventions = caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-4, 1.0e-4, "FX_VOL_SURF_DEF", false)
quoteTerms = ["ON", "1W", "1M", "3M", "6M", "1Y"]
quoteNames = ["ATM", "D25_RR", "D25_BF", "D10_RR", "D10_BF"]
quoteValues = matrix(
    [0.06035, 0.05515, 0.06115, 0.06135, 0.06250, 0.06330],
    [-0.00310, -0.00290, -0.00248, -0.00180, -0.00135, -0.00100],
    [0.00115, 0.00135, 0.00147, 0.00205, 0.00250, 0.00325],
    [-0.00565, -0.00520, -0.00450, -0.00330, -0.00240, -0.00185],
    [0.00310, 0.00385, 0.00450, 0.00625, 0.00815, 0.01120])
optionQuotes = caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, quoteTerms, quoteNames, quoteValues,
    "EURUSD_OPTION_QUOTES", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "FX_VOL_BUILD_SETTINGS", false)
fxVolSurface = caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions, optionQuotes,
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volDef, volBuildSettings, "EURUSD_BUILT_VOL_SURF", false)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, fxVolSurface, "", "EURUSD_MKT", false)

// Semi-annual coupon observation and daily monitoring schedules
couponObsDates = [2021.06.30, 2021.09.26]
couponObsValues = take(0.0, size(couponObsDates))
couponObsWeights = take(1.0, size(couponObsDates))
dailyObsDates = 2021.03.31..2021.09.26
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))

// Snowball auto-callable note, 12% coupon, +5%/-20% barriers, short ATM put
snowballNote = caplib::createSnowballAutoCallableNote(0.12, 2021.03.31, couponObsDates,
    "ACT_365_FIXED", "UP_OUT", eurusdSpot*1.05, "DOWN_IN", eurusdSpot*0.8,
    "SELL", "PUT", eurusdSpot, 1.0, eurusdSpot, 2021.09.26, 2021.09.27,
    1, 1000000.0, currency, "SPOT", currency, underlying, "FX_SNOWBALL",
    couponObsDates, couponObsValues, couponObsWeights,
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceFxSnowballAutoCallableNote(
    snowballNote, asOfDate, mktData, pricingSettings, riskSettings, "", "", true)
```

#### createFxSpotTemplate

语法

```dolphindb
caplib::createFxSpotTemplate(instName, currencyPair, spotDayConvention, calendars, spotDelay[, handle][, returnJson])
```

详情

创建并缓存外汇即期模板。函数验证并转换字段，构造 `FxSpotTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

参数

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

currencyPair STRING 类型。货币对标识，通常为基准币种/目标币种格式。**有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。

spotDayConvention STRING 类型。即期日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

calendars STRING 或 STRING 向量 类型。日期调整使用的业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

spotDelay STRING 或 INT 类型。即期结算延迟。**有效性:** INT 输入按天计，无需单位；STRING 输入为带可选正负号的整数和可选单位 `Y/M/W/D`（或完整英文单位），省略单位时按天计，负号会被保留。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键；本接口 handle 为可选，省略时自动生成句柄键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxSpotTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Register the business calendars used for spot date adjustment
caplib::createCalendar("CAL_EUTA")
caplib::createCalendar("CAL_GBLO")

// EURUSD spot template with a 2-business-day spot delay
spotTemplate = caplib::createFxSpotTemplate(
    "EURUSD_SPOT_TPL", "EURUSD", "FOLLOWING", ["CAL_EUTA", "CAL_GBLO"], "2d", false)
```

#### createFxSpotRate

语法

```dolphindb
caplib::createFxSpotRate(value, baseCurrency, targetCurrency, refDate, spotDate, handle[, returnJson])
```

详情

创建并缓存外汇即期汇率，构造 `FxSpotRate` 对象并写入 ObjectCache，供后续定价与风险分析使用。

参数

value DOUBLE 类型。报价、利率或即期汇率数值。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

baseCurrency STRING 类型。外汇货币对中的基准币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

targetCurrency STRING 类型。外汇货币对中的目标币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

refDate DATE 类型。参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

spotDate DATE 类型。即期结算日。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxSpotRate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// EURUSD spot quote as of 2021.03.30, spot settlement on 2021.04.01
asOfDate = 2021.03.30
eurusdSpot = 1.1761
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)
```

#### createFxForwardTemplate

语法

```dolphindb
caplib::createFxForwardTemplate(instName, fixingOffset, currencyPair, deliveryDayConvention, fixingDayConvention, calendars[, returnJson])
```

详情

创建并缓存外汇远期模板，构造 `FxForwardTemplate` 对象并写入 ObjectCache。`instName` 同时用作缓存句柄，本接口没有独立的 handle 参数。

参数

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

fixingOffset STRING 或 INT 类型。定盘偏移期限。**有效性:** INT 输入按天计，无需单位；STRING 输入为带可选正负号的整数和可选单位 `Y/M/W/D`（或完整英文单位），省略单位时按天计，负号会被保留。

currencyPair STRING 类型。货币对标识，通常为基准币种/目标币种格式。**有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。

deliveryDayConvention STRING 类型。交割日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

fixingDayConvention STRING 类型。定盘日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

calendars STRING 或 STRING 向量 类型。日期调整使用的业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxForwardTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Register the business calendars used for date adjustment
caplib::createCalendar("CAL_EUTA")
caplib::createCalendar("CAL_GBLO")

// EURUSD forward template: fixing 2 business days before delivery
forwardTemplate = caplib::createFxForwardTemplate(
    "EURUSD_FWD_TPL", "-2d", "EURUSD", "FOLLOWING", "PRECEDING",
    ["CAL_EUTA", "CAL_GBLO"], false)
```

#### createFxSwapTemplate

语法

```dolphindb
caplib::createFxSwapTemplate(instName, startConvention, currencyPair, calendars, startDayConvention, endDayConvention, fixingOffset, fixingDayConvention[, returnJson])
```

详情

创建并缓存外汇掉期模板，构造 `FxSwapTemplate` 对象并写入 ObjectCache，供后续构建外汇掉期使用。

参数

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

startConvention STRING 类型。工具起息约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`SPOTSTART`, `TODAYSTART`, `TOMORROWSTART`。

currencyPair STRING 类型。货币对标识，通常为基准币种/目标币种格式。**有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。

calendars STRING 或 STRING 向量 类型。日期调整使用的业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

startDayConvention STRING 类型。起始日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

endDayConvention STRING 类型。结束日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

fixingOffset STRING 或 INT 类型。定盘偏移期限。**有效性:** INT 输入按天计，无需单位；STRING 输入为带可选正负号的整数和可选单位 `Y/M/W/D`（或完整英文单位），省略单位时按天计，负号会被保留。

fixingDayConvention STRING 类型。定盘日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxSwapTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Register the business calendars used for date adjustment
caplib::createCalendar("CAL_EUTA")
caplib::createCalendar("CAL_GBLO")

// EURUSD swap template: spot-starting legs, fixing 2 business days before settlement
swapTemplate = caplib::createFxSwapTemplate(
    "EURUSD_SWP_TPL", "SPOTSTART", "EURUSD", ["CAL_EUTA", "CAL_GBLO"],
    "FOLLOWING", "FOLLOWING", "-2d", "PRECEDING", false)
```

#### createFxNdfTemplate

语法

```dolphindb
caplib::createFxNdfTemplate(instName, fixingOffset, currencyPair, deliveryDayConvention, fixingDayConvention, calendars, settlementCurrency[, returnJson])
```

详情

创建并缓存外汇无本金交割远期模板。函数验证并转换字段，构造 `FxNdfTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

参数

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

fixingOffset STRING 或 INT 类型。定盘偏移期限。**有效性:** INT 输入按天计，无需单位；STRING 输入为带可选正负号的整数和可选单位 `Y/M/W/D`（或完整英文单位），省略单位时按天计，负号会被保留。

currencyPair STRING 类型。货币对标识，通常为基准币种/目标币种格式。**有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。

deliveryDayConvention STRING 类型。交割日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

fixingDayConvention STRING 类型。定盘日调整约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。

calendars STRING 或 STRING 向量 类型。日期调整使用的业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

settlementCurrency STRING 类型。结算币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxNdfTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Register the business calendars used for date adjustment
caplib::createCalendar("CAL_HKHK")
caplib::createCalendar("CAL_GBLO")

// USDCNH NDF template: fixing 2 business days before delivery, settled in USD
ndfTemplate = caplib::createFxNdfTemplate(
    "USDCNH_NDF_TPL", "-2d", "USDCNH", "FOLLOWING", "PRECEDING",
    ["CAL_HKHK", "CAL_GBLO"], "USD", false)
```

#### createFxForward

语法

```dolphindb
caplib::createFxForward(buyCurrency, buyAmount, sellCurrency, sellAmount, deliveryDate, expiryDate, handle[, returnJson])
```

详情

创建并缓存外汇远期工具。函数验证并转换字段，构造 `FxForward` protobuf 并存入 ObjectCache，供后续分析使用。

参数

buyCurrency STRING 类型。买入币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

buyAmount DOUBLE 类型。买入金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

sellCurrency STRING 类型。卖出币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

sellAmount DOUBLE 类型。卖出金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

deliveryDate DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

expiryDate DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxForward 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createFxForward(
    "EUR", 1000000.0, "USD", 1176100.0,
    2021.07.01, 2021.06.30, "FX_FWD", false)
```

#### createFxSwap

语法

```dolphindb
caplib::createFxSwap(nearBuyCurrency, nearBuyAmount, nearSellCurrency, nearSellAmount, nearDeliveryDate, nearExpiryDate, farBuyCurrency, farBuyAmount, farSellCurrency, farSellAmount, farDeliveryDate, farExpiryDate, handle[, returnJson])
```

详情

创建并缓存外汇掉期工具。函数验证并转换字段，构造 `FxSwap` protobuf 并存入 ObjectCache，供后续分析使用。

参数

nearBuyCurrency STRING 类型。近端买入币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

nearBuyAmount DOUBLE 类型。近端买入金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

nearSellCurrency STRING 类型。近端卖出币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

nearSellAmount DOUBLE 类型。近端卖出金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

nearDeliveryDate DATE 类型。日期或日期数组。**有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。

nearExpiryDate DATE 类型。日期或日期数组。**有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。

farBuyCurrency STRING 类型。远端买入币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

farBuyAmount DOUBLE 类型。远端买入金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

farSellCurrency STRING 类型。远端卖出币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

farSellAmount DOUBLE 类型。远端卖出金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

farDeliveryDate DATE 类型。日期或日期数组。**有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。

farExpiryDate DATE 类型。日期或日期数组。**有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxSwap 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createFxSwap(
    "EUR", 1000000.0, "USD", 1176100.0, 2021.04.01, 2021.03.31,
    "USD", 1000000.0, "EUR", 1176100.0, 2021.07.01, 2021.06.30,
    "FX_SWAP_INST", false)
```

#### createFxNonDeliverableForward

语法

```dolphindb
caplib::createFxNonDeliverableForward(buyCurrency, buyAmount, sellCurrency, sellAmount, settlementCurrency, deliveryDate, expiryDate, handle[, returnJson])
```

详情

创建并缓存外汇无本金交割远期工具。函数验证并转换字段，构造 `FxNonDeliverableForward` protobuf 并存入 ObjectCache，供后续分析使用。

参数

buyCurrency STRING 类型。买入币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

buyAmount DOUBLE 类型。买入金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

sellCurrency STRING 类型。卖出币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

sellAmount DOUBLE 类型。卖出金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

settlementCurrency STRING 类型。结算币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

deliveryDate DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

expiryDate DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxNonDeliverableForward 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createFxNonDeliverableForward(
    "USD", 10000.0, "CNH", 66916.0, "USD",
    2021.07.01, 2021.06.30, "FX_NDF_INST", false)
```

#### createFxMktConventions

语法

```dolphindb
caplib::createFxMktConventions(ccyPair, atmType, shortDeltaType, longDeltaType, deltaCutoff, riskReversal, smileQuoteType, handle[, returnJson])
```

详情

创建并缓存外汇市场惯例。函数验证并转换字段，构造 `FxMarketConventions` protobuf 并存入 ObjectCache，供后续分析使用。

参数

ccyPair STRING 类型。货币对标识。**有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。

atmType STRING 类型。ATM 报价类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`ATM_FORWARD`, `ATM_DNS_PIPS`, `ATM_DNS_PERCENTAGE`, `ATM_SPOT`。

shortDeltaType STRING 类型。短期限 Delta 报价类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。

longDeltaType STRING 类型。长期限 Delta 报价类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。

deltaCutoff STRING 类型。Delta 报价切换阈值。**有效性:** 值必须是以下完整 protobuf 标签之一：`PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。

riskReversal STRING 类型。设置对象的缓存句柄或配置值。**有效性:** 值必须是以下完整 protobuf 标签之一：`RR_CALL_PUT`, `RR_PUT_CALL`。

smileQuoteType STRING 类型。波动率微笑报价类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`BUTTERFLY_QUOTE`, `MARKET_STRANGLE_QUOTE`, `WINGS_RATIO_BF_QUOTE`。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxMarketConventions 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


underlying = "EURUSD"
caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", true)
```

#### createFxMktDataSet

语法

```dolphindb
caplib::createFxMktDataSet(asOfDate, domDiscountCurve, forDiscountCurve, spot, volSurface, name, handle[, returnJson])
```

详情

创建并缓存外汇市场数据集。函数验证并转换字段，构造 `FxMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

domDiscountCurve STRING 类型。本币贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

forDiscountCurve STRING 类型。外币贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

spot STRING 类型。当前现货价格。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

volSurface STRING 类型。波动率曲面 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxMktDataSet 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date and spot rate
asOfDate = 2021.03.30
eurusdSpot = 1.1761

// USD (domestic) and EUR (foreign) discount curves
usdCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [0.00016, 0.00028, 0.00042, 0.00108, 0.00798, 0.01624],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO", false)
eurCurve = caplib::createIrYieldCurve(asOfDate,
    [2021.04.06, 2021.09.30, 2022.03.30, 2023.03.30, 2026.03.30, 2031.03.31],
    [-0.00814, -0.00759, -0.00814, -0.00801, -0.0068, -0.00355],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EUR", "EUR_EURUSD_FX", "EUR_EURUSD_FX", false)
eurusdSpotRate = caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", false)

// Flat volatility surface as a minimal vol source
flatVolSurface = caplib::createFlatFxVolatilitySurface(
    asOfDate, "USDCNH", 0.0, "USDCNH_FLAT_FX_VOL_SURF", false)

// EURUSD market data set (domestic USD, foreign EUR)
mktData = caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate, flatVolSurface, "", "EURUSD_MKT", true)
```

#### createFxRiskSettings

语法

```dolphindb
caplib::createFxRiskSettings(irCurveSettings, priceSettings, volSettings, priceVolSettings, thetaSettings, name, handle[, returnJson])
```

详情

创建并缓存外汇风险设置。函数验证并转换字段，构造 `FxRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

irCurveSettings STRING 类型。利率曲线风险设置 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

priceSettings STRING 类型。价格风险设置 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

volSettings STRING 类型。波动率风险设置 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

priceVolSettings STRING 类型。价格-波动率联合风险设置 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

thetaSettings STRING 类型。设置对象的缓存句柄或配置值。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 FxRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Component risk settings (curve, price, vol, price-vol, theta)
irCurveRisk = caplib::createIrCurveRiskSettings(
    1, 1, 0, 1.0e-4, 5.0e-1, 0, 0, 1.0e-4, 0, "FX_IR_CURVE_RISK", false)
priceRisk = caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
volRisk = caplib::createVolRiskSettings(
    1, 1, 1.0e-2, 0, 0, 1.0e-2, 0, "FX_VOL_RISK", false)
priceVolRisk = caplib::createPriceVolRiskSettings(
    1, 1.0e-2, 1.0e-2, 0, 0, 1.0e-2, 1.0e-2, 0, "FX_PRICE_VOL_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(1, 1, 1.0 / 365.0, "FX_THETA_RISK", false)

// FX risk settings bundle
riskSettings = caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, volRisk, priceVolRisk, thetaRisk, "", "FX_RISK", false)
```

### 权益

#### buildEqIndexDividendCurve

语法

```dolphindb
caplib::buildEqIndexDividendCurve(asOfDate, termDates, futurePrices, optionPrices TABLE, spot, discountCurveHandle, handle[, returnJson])
```

详情

构建股指股息收益率曲线。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `DividendCurve`。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

termDates DATE 向量 类型。报价期限对应的到期日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

futurePrices DOUBLE 向量 类型。期货价格数组。**有效性:** 所有元素必须有限并与配对日期等长；通常应为正，但可出现负价格的市场由下游业务规则决定。

optionPrices TABLE 类型。期权价格矩阵或表。**有效性:** 所有元素必须非负且有限，并与配对行权价/期限参数形状一致；包装器主要检查类型/形状。

spot DOUBLE 类型。当前现货价格。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

discountCurveHandle STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 DividendCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2020.02.21
underlyingPrice = 2.958

// CNY discount curve for the index
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CNY", "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)

// Option quotes used to back out implied dividends (no index futures)
quoteTermDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
idxOptionPrices = table(
    [quoteTermDates[0], quoteTermDates[0], quoteTermDates[1], quoteTermDates[1]] as expiry,
    [2.9, 2.9, 2.9, 2.9] as strike,
    ["CALL", "PUT", "CALL", "PUT"] as optionType,
    [0.02, 0.02, 0.03, 0.03] as price)

result = caplib::buildEqIndexDividendCurve(asOfDate, quoteTermDates, array(DOUBLE, 0),
    idxOptionPrices, underlyingPrice, irCurve, "EQ_IDX_DIV_CURVE", true)
```

#### buildEqVolatilitySurface

语法

```dolphindb
caplib::buildEqVolatilitySurface(asOfDate, underlying, definitionHandle, quoteMatrixHandle, underlyingPrices, discountCurveHandle, dividendCurveHandle, buildSettingsHandle, pricingSettingsHandle, handle[, returnJson])
```

详情

构建权益波动率曲面。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `VolatilitySurface`。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

definitionHandle STRING 类型。波动率曲面定义 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

quoteMatrixHandle STRING 类型。期权报价矩阵 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

underlyingPrices DOUBLE 向量 类型。与报价期限或校准行对齐的标的价格数组。**有效性:** 所有元素必须有限并与配对日期等长；通常应为正，但可出现负价格的市场由下游业务规则决定。

discountCurveHandle STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

dividendCurveHandle STRING 类型。股息曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

buildSettingsHandle STRING 类型。构建设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolatilitySurface 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CNY", "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical pricing settings for the calibration step
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings("CNY", "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)

result = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURFACE", true)
```

#### createEqOptionQuoteMatrix

语法

```dolphindb
caplib::createEqOptionQuoteMatrix(exerciseType, underlyingType, asOfDate, termDates, payoffTypes, optionPrices, optionStrikes, underlying, handle[, returnJson])
```

详情

创建并缓存权益期权报价矩阵。函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

参数

exerciseType STRING 类型。期权行权风格。**有效性:** 值必须是以下完整 protobuf 标签之一：`EUROPEAN`, `AMERICAN`, `BERMUDAN`。

underlyingType STRING 类型。标的类型枚举。**有效性:** 值必须是以下完整 protobuf 标签之一：`SPOT_UNDERLYING_TYPE`, `FUTURE_UNDERLYING_TYPE`。

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

termDates DATE 向量 类型。报价期限对应的到期日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

payoffTypes STRING 矩阵/向量 类型。与报价值对齐的收益类型矩阵或向量。**有效性:** 每个元素必须是以下完整 protobuf 标签之一：`CALL`, `PUT`, `STRADDLE`, `STRANGLE`, `RISK_REVERSAL`, `BUTTERFLY`, `ATM_STRADDLE`。

optionPrices DOUBLE 矩阵/向量 类型。期权价格矩阵或表。**有效性:** 所有元素必须非负且有限，并与配对行权价/期限参数形状一致；包装器主要检查类型/形状。

optionStrikes DOUBLE 矩阵/向量 类型。期权行权价矩阵或向量。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 OptionQuoteMatrix 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
underlying = "EURUSD"
caplib::createEqOptionQuoteMatrix(
    "EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [
        ["PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "CALL", "CALL", "CALL", "CALL", "CALL"],
        ["PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "CALL", "CALL", "CALL", "CALL", "CALL"],
        ["PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "CALL", "CALL", "CALL", "CALL", "CALL"],
        ["PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "PUT", "CALL", "CALL", "CALL", "CALL", "CALL"]
    ],
    [
        [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
        [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
        [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
        [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]
    ],
    [
        [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
        [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
        [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
        [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]
    ],
    underlying, "EQ_OPTION_QUOTES", true)
```

#### priceEqEuropeanOption

语法

```dolphindb
caplib::priceEqEuropeanOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益欧式期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical pricing settings and EQ risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// European call on the 50ETF spot
europeanOption = caplib::createEuropeanOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    1000000.0, currency, "SPOT", currency, underlying, "EQ_EUROPEAN", false)
result = caplib::priceEqEuropeanOption(europeanOption, asOfDate, mktData,
    bsmAnalyticalSettings, riskSettings, "", "", true)
```

#### createEqMktDataSet

语法

```dolphindb
caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice, dcHandle, divHandle, volHandle, quantoDcHandle, quantoFxVolHandle, quantoCorrelation, handle[, returnJson])
```

详情

创建并缓存权益市场数据集。函数验证并转换字段，构造 `EqMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

underlyingPrice DOUBLE 类型。当前标的价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

dcHandle STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

divHandle STRING 类型。股息曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

volHandle STRING 类型。波动率设置或曲面 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

quantoDcHandle STRING 类型。Quanto 贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

quantoFxVolHandle STRING 类型。Quanto 外汇波动率曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

quantoCorrelation DOUBLE 类型。Quanto 调整相关系数。**有效性:** 必须有限且业务有效范围为 `[-1,1]`；包装器仅检查类型。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 EqMktDataSet 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CNY", "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical pricing settings for the surface build
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings("CNY", "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
result = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", true)
```

#### createEqRiskSettings

语法

```dolphindb
caplib::createEqRiskSettings(irDelta, priceDelta, volVega, theta, handle[, returnJson])
```

详情

创建并缓存权益风险设置。函数验证并转换字段，构造 `EqRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

irDelta INT 类型。是否计算利率 Delta 风险。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

priceDelta INT 类型。是否计算标的价格 Delta 风险。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

volVega INT 类型。是否计算波动率 Vega 风险。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

theta INT 类型。是否计算 Theta 风险。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 EqRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createEqRiskSettings(1, 1, 1, 1, "EQ_RISK", true)
```

#### createEuropeanOption

语法

```dolphindb
caplib::createEuropeanOption(payoffType, strike, expiry, delivery, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle[, returnJson])
```

详情

创建并缓存欧式期权。函数验证并转换字段，构造 `EuropeanOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

payoffType STRING 类型。收益类型，例如 CALL 或 PUT。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

strike DOUBLE 类型。行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 EuropeanOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createEuropeanOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    1000000.0, currency, "SPOT", currency, underlying, "EQ_EO", false)
```

#### createAmericanOption

语法

```dolphindb
caplib::createAmericanOption(payoffType, strike, expiry, delivery, settlementDays, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle[, returnJson])
```

详情

创建并缓存美式期权。函数验证并转换字段，构造 `AmericanOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

payoffType STRING 类型。收益类型，例如 CALL 或 PUT。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

strike DOUBLE 类型。行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 AmericanOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createAmericanOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20, 1,
    1000000.0, currency, "FUTURE", currency, underlying, "CM_AM_INST", false)
```

#### createDigitalOption

语法

```dolphindb
caplib::createDigitalOption(payoffType, strike, expiry, delivery, cash, asset, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle[, returnJson])
```

详情

创建并缓存数字期权。函数验证并转换字段，构造 `DigitalOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

payoffType STRING 类型。收益类型，例如 CALL 或 PUT。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

strike DOUBLE 类型。行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

cash DOUBLE 类型。现金收益或现金返还金额。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

asset DOUBLE 类型。资产收益或资产返还金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 DigitalOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createDigitalOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    0.0, 1.0, 1000000.0, currency, "FUTURE", currency, underlying, "CM_DG_INST", false)
```

#### createAsianOption

语法

```dolphindb
caplib::createAsianOption(payoffType, strike, expiry, delivery, strikeType, avgMethod, obsType, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, fixingDates, fixingValues, fixingWeights[, returnJson])
```

详情

创建并缓存亚式期权。函数验证并转换字段，构造 `AsianOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

payoffType STRING 类型。收益类型，例如 CALL 或 PUT。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

strike DOUBLE 类型。行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

strikeType STRING 类型。行权价类型。**有效性:** 可接受值：`FIXED`, `FIXED_STRIKE`, `FLOATING`, `FLOATING_STRIKE`。仅接受所示精确拼写。

avgMethod STRING 类型。平均价格或平均观察值计算方法。**有效性:** 可接受值：``, `ARITHMETIC`, `ARITHMETIC_AVERAGE_METHOD`, `GEOMETRIC`, `GEOMETRIC_AVERAGE_METHOD`。仅接受所示精确拼写。

obsType STRING 类型。观察方式。**有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

fixingDates DATE 向量 类型。观察或定盘日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

fixingValues DOUBLE 向量 类型。与观察日期对齐的定盘值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

fixingWeights DOUBLE 向量 类型。观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 AsianOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
dailyObsDates = [2020.02.21]
dailyObsValues = [0.0]
dailyObsWeights = [1.0]
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createAsianOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    "FIXED_STRIKE", "ARITHMETIC_AVERAGE_METHOD", "DISCRETE_OBSERVATION_TYPE",
    1000000.0, currency, "SPOT", currency, underlying, "EQ_ASIAN",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createOneTouchOption

语法

```dolphindb
caplib::createOneTouchOption(expiry, delivery, barrierType, barrierValue, barrierObsType, paymentType, cash, asset, settlementDays, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, fixingDates, fixingValues, fixingWeights[, returnJson])
```

详情

创建并缓存单触碰期权。函数验证并转换字段，构造 `OneTouchOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

barrierType STRING 类型。障碍方向或类型枚举。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

barrierValue DOUBLE 类型。障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

barrierObsType STRING 类型。障碍观察约定。**有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。

paymentType STRING 类型。返还或障碍支付时点类型。**有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。

cash DOUBLE 类型。现金收益或现金返还金额。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

asset DOUBLE 类型。资产收益或资产返还金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

fixingDates DATE 向量 类型。观察或定盘日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

fixingValues DOUBLE 向量 类型。与观察日期对齐的定盘值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

fixingWeights DOUBLE 向量 类型。观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 OneTouchOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createOneTouchOption(
    2020.08.19, 2020.08.20, "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    1.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_OT_INST", false)
```

#### createDoubleTouchOption

语法

```dolphindb
caplib::createDoubleTouchOption(expiry, delivery, lowerBarrierType, lowerBarrierValue, upperBarrierType, upperBarrierValue, barrierObsType, paymentType, cash, asset, settlementDays, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, fixingDates, fixingValues, fixingWeights[, returnJson])
```

详情

创建并缓存双触碰期权。函数验证并转换字段，构造 `DoubleTouchOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

lowerBarrierType STRING 类型。下障碍类型。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

lowerBarrierValue DOUBLE 类型。下障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

upperBarrierType STRING 类型。上障碍类型。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

upperBarrierValue DOUBLE 类型。上障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

barrierObsType STRING 类型。障碍观察约定。**有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。

paymentType STRING 类型。返还或障碍支付时点类型。**有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。

cash DOUBLE 类型。现金收益或现金返还金额。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

asset DOUBLE 类型。资产收益或资产返还金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

fixingDates DATE 向量 类型。观察或定盘日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

fixingValues DOUBLE 向量 类型。与观察日期对齐的定盘值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

fixingWeights DOUBLE 向量 类型。观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 DoubleTouchOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createDoubleTouchOption(
    2020.08.19, 2020.08.20, "DOWN_IN", underlyingPrice * 0.95,
    "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    1.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_DT_INST", false)
```

#### createSingleBarrierOption

语法

```dolphindb
caplib::createSingleBarrierOption(payoffType, strike, expiry, delivery, barrierType, barrierValue, barrierObsType, paymentType, cashRebate, assetRebate, settlementDays, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, fixingDates, fixingValues, fixingWeights[, returnJson])
```

详情

创建并缓存单障碍期权。函数验证并转换字段，构造 `SingleBarrierOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

payoffType STRING 类型。收益类型，例如 CALL 或 PUT。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

strike DOUBLE 类型。行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

barrierType STRING 类型。障碍方向或类型枚举。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

barrierValue DOUBLE 类型。障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

barrierObsType STRING 类型。障碍观察约定。**有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。

paymentType STRING 类型。返还或障碍支付时点类型。**有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。

cashRebate DOUBLE 类型。现金返还金额。**有效性:** 必须非负且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

assetRebate DOUBLE 类型。资产返还金额。**有效性:** 必须非负且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

fixingDates DATE 向量 类型。观察或定盘日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

fixingValues DOUBLE 向量 类型。与观察日期对齐的定盘值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

fixingWeights DOUBLE 向量 类型。观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 SingleBarrierOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createSingleBarrierOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_SB_INST", false)
```

#### createDoubleBarrierOption

语法

```dolphindb
caplib::createDoubleBarrierOption(payoffType, strike, expiry, delivery, lowerBarrierType, lowerBarrierValue, upperBarrierType, upperBarrierValue, barrierObsType, paymentType, lowerCashRebate, lowerAssetRebate, upperCashRebate, upperAssetRebate, settlementDays, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, fixingDates, fixingValues, fixingWeights[, returnJson])
```

详情

创建并缓存双障碍期权。函数验证并转换字段，构造 `DoubleBarrierOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

payoffType STRING 类型。收益类型，例如 CALL 或 PUT。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

strike DOUBLE 类型。行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

lowerBarrierType STRING 类型。下障碍类型。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

lowerBarrierValue DOUBLE 类型。下障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

upperBarrierType STRING 类型。上障碍类型。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

upperBarrierValue DOUBLE 类型。上障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

barrierObsType STRING 类型。障碍观察约定。**有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。

paymentType STRING 类型。返还或障碍支付时点类型。**有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。

lowerCashRebate DOUBLE 类型。下障碍现金返还金额。**有效性:** 必须非负且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

lowerAssetRebate DOUBLE 类型。下障碍资产返还金额。**有效性:** 必须非负且有限；包装器通常仅检查类型。

upperCashRebate DOUBLE 类型。上障碍现金返还金额。**有效性:** 必须非负且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

upperAssetRebate DOUBLE 类型。上障碍资产返还金额。**有效性:** 必须非负且有限；包装器通常仅检查类型。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

fixingDates DATE 向量 类型。观察或定盘日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

fixingValues DOUBLE 向量 类型。与观察日期对齐的定盘值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

fixingWeights DOUBLE 向量 类型。观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 DoubleBarrierOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createDoubleBarrierOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    "DOWN_IN", underlyingPrice * 0.95, "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 0.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_DB_INST", false)
```

#### createCollarOption

语法

```dolphindb
caplib::createCollarOption(payoffType, lowerGearing, upperGearing, lowerStrike, upperStrike, expiry, delivery, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle[, returnJson])
```

详情

创建并缓存领口期权。函数验证并转换字段，构造 `CollarOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

payoffType STRING 类型。收益类型，例如 CALL 或 PUT。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

lowerGearing DOUBLE 类型。下行收益杠杆。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

upperGearing DOUBLE 类型。上行收益杠杆。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

lowerStrike DOUBLE 类型。下行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

upperStrike DOUBLE 类型。上行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CollarOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

underlying = "50ETF.SSE"
underlyingPrice = 2.958
result = caplib::createCollarOption("CALL", 0.9, 1.1, underlyingPrice * 0.9, underlyingPrice * 1.1,
    2020.08.19, 2020.08.20, 1000000.0, "CNY", "SPOT", "CNY", underlying, "EQ_COLLAR", false)
```

#### createSingleSharkFinOption

语法

```dolphindb
caplib::createSingleSharkFinOption(payoffType, strike, expiry, delivery, gearing, performanceType, barrierType, barrierValue, barrierObsType, paymentType, cashRebate, assetRebate, settlementDays, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, fixingDates, fixingValues, fixingWeights[, returnJson])
```

详情

创建并缓存单鲨鱼鳍期权。函数验证并转换字段，构造 `SingleSharkFinOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

payoffType STRING 类型。收益类型，例如 CALL 或 PUT。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

strike DOUBLE 类型。行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

gearing DOUBLE 类型。收益杠杆。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

performanceType STRING 类型。收益表现计算类型。**有效性:** 可接受值：``, `RELATIVE`, `RELATIVE_PERFORM_TYPE`, `ABSOLUTE`, `ABSOLUTE_PERFORM_TYPE`。仅接受所示精确拼写。

barrierType STRING 类型。障碍方向或类型枚举。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

barrierValue DOUBLE 类型。障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

barrierObsType STRING 类型。障碍观察约定。**有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。

paymentType STRING 类型。返还或障碍支付时点类型。**有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。

cashRebate DOUBLE 类型。现金返还金额。**有效性:** 必须非负且有限；包装器通常仅检查类型。

assetRebate DOUBLE 类型。资产返还金额。**有效性:** 必须非负且有限；包装器通常仅检查类型。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

fixingDates DATE 向量 类型。观察或定盘日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

fixingValues DOUBLE 向量 类型。与观察日期对齐的定盘值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

fixingWeights DOUBLE 向量 类型。观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 SingleSharkFinOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
dailyObsDates = [2020.02.21]
dailyObsValues = [0.0]
dailyObsWeights = [1.0]
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createSingleSharkFinOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20, 1.0,
    "RELATIVE_PERFORM_TYPE", "UP_OUT", underlyingPrice * 1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_SF_INST",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createDoubleSharkFinOption

语法

```dolphindb
caplib::createDoubleSharkFinOption(lowerStrike, upperStrike, expiry, delivery, lowerParticipation, upperParticipation, performanceType, lowerBarrier, upperBarrier, barrierObsType, paymentType, lowerCashRebate, lowerAssetRebate, upperCashRebate, upperAssetRebate, settlementDays, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, fixingDates, fixingValues, fixingWeights[, returnJson])
```

详情

创建并缓存双鲨鱼鳍期权。函数验证并转换字段，构造 `DoubleSharkFinOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

lowerStrike DOUBLE 类型。下行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

upperStrike DOUBLE 类型。上行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

lowerParticipation DOUBLE 类型。下行参与率。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

upperParticipation DOUBLE 类型。上行参与率。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

performanceType STRING 类型。收益表现计算类型。**有效性:** 可接受值：``, `RELATIVE`, `RELATIVE_PERFORM_TYPE`, `ABSOLUTE`, `ABSOLUTE_PERFORM_TYPE`。仅接受所示精确拼写。

lowerBarrier DOUBLE 类型。下障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

upperBarrier DOUBLE 类型。上障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

barrierObsType STRING 类型。障碍观察约定。**有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。

paymentType STRING 类型。返还或障碍支付时点类型。**有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。

lowerCashRebate DOUBLE 类型。下障碍现金返还金额。**有效性:** 必须非负且有限；包装器通常仅检查类型。

lowerAssetRebate DOUBLE 类型。下障碍资产返还金额。**有效性:** 必须非负且有限；包装器通常仅检查类型。

upperCashRebate DOUBLE 类型。上障碍现金返还金额。**有效性:** 必须非负且有限；包装器通常仅检查类型。

upperAssetRebate DOUBLE 类型。上障碍资产返还金额。**有效性:** 必须非负且有限；包装器通常仅检查类型。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

fixingDates DATE 向量 类型。观察或定盘日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

fixingValues DOUBLE 向量 类型。与观察日期对齐的定盘值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

fixingWeights DOUBLE 向量 类型。观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 DoubleSharkFinOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
dailyObsDates = [2020.02.21]
dailyObsValues = [0.0]
dailyObsWeights = [1.0]
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createDoubleSharkFinOption(
    underlyingPrice, underlyingPrice, 2020.08.19, 2020.08.20, 1.0, 1.0,
    "ABSOLUTE_PERFORM_TYPE", underlyingPrice * 0.95, underlyingPrice * 1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 0.0, 0.0, 1, 1000000.0,
    currency, "FUTURE", currency, underlying, "CM_DS_INST",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createRangeAccrualOption

语法

```dolphindb
caplib::createRangeAccrualOption(expiry, delivery, asset, cash, lowerBarrier, upperBarrier, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, fixingDates, fixingValues, fixingWeights[, returnJson])
```

详情

创建并缓存区间累计期权。函数验证并转换字段，构造 `RangeAccrualOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

asset DOUBLE 类型。资产收益或资产返还金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

cash DOUBLE 类型。现金收益或现金返还金额。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

lowerBarrier DOUBLE 类型。下障碍水平。**有效性:** 必须非负且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

upperBarrier DOUBLE 类型。上障碍水平。**有效性:** 必须非负且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

fixingDates DATE 向量 类型。观察或定盘日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

fixingValues DOUBLE 向量 类型。与观察日期对齐的定盘值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

fixingWeights DOUBLE 向量 类型。观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 RangeAccrualOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
dailyObsDates = [2020.02.21]
dailyObsValues = [0.0]
dailyObsWeights = [1.0]
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createRangeAccrualOption(
    2020.08.19, 2020.08.20, 0.0, 0.01,
    underlyingPrice * 0.95, underlyingPrice * 1.05,
    1000000.0, currency, "FUTURE", currency, underlying, "CM_RA_INST",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createAirbagOption

语法

```dolphindb
caplib::createAirbagOption(payoffType, expiry, delivery, lowerStrike, upperStrike, lowerGearing, upperGearing, knockInStrike, barrierType, barrierValue, barrierObsType, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, fixingDates, fixingValues, fixingWeights[, returnJson])
```

详情

创建并缓存安全气囊期权。函数验证并转换字段，构造 `AirbagOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

payoffType STRING 类型。收益类型，例如 CALL 或 PUT。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

lowerStrike DOUBLE 类型。下行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

upperStrike DOUBLE 类型。上行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

lowerGearing DOUBLE 类型。下行收益杠杆。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

upperGearing DOUBLE 类型。上行收益杠杆。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

knockInStrike DOUBLE 类型。敲入后使用的行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

barrierType STRING 类型。障碍方向或类型枚举。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

barrierValue DOUBLE 类型。障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

barrierObsType STRING 类型。障碍观察约定。**有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

fixingDates DATE 向量 类型。观察或定盘日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

fixingValues DOUBLE 向量 类型。与观察日期对齐的定盘值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

fixingWeights DOUBLE 向量 类型。观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 AirbagOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
dailyObsDates = [2020.02.21]
dailyObsValues = [0.0]
dailyObsWeights = [1.0]
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createAirbagOption(
    "CALL", 2020.08.19, 2020.08.20,
    underlyingPrice, underlyingPrice * 1.05, 1.0, 1.0, underlyingPrice,
    "DOWN_IN", underlyingPrice * 0.8, "DISCRETE_OBSERVATION_TYPE",
    1000000.0, currency, "FUTURE", currency, underlying, "CM_AB_INST",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createPingPongOption

语法

```dolphindb
caplib::createPingPongOption(expiry, delivery, lowerBarrierType, lowerBarrierValue, upperBarrierType, upperBarrierValue, barrierObsType, paymentType, cash, asset, settlementDays, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, fixingDates, fixingValues, fixingWeights[, returnJson])
```

详情

创建并缓存乒乓期权。函数验证并转换字段，构造 `PingPongOption` protobuf 并存入 ObjectCache，供后续分析使用。

参数

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

lowerBarrierType STRING 类型。下障碍类型。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

lowerBarrierValue DOUBLE 类型。下障碍水平。**有效性:** 必须非负且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

upperBarrierType STRING 类型。上障碍类型。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

upperBarrierValue DOUBLE 类型。上障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

barrierObsType STRING 类型。障碍观察约定。**有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。

paymentType STRING 类型。返还或障碍支付时点类型。**有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。

cash DOUBLE 类型。现金收益或现金返还金额。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

asset DOUBLE 类型。资产收益或资产返还金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

fixingDates DATE 向量 类型。观察或定盘日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

fixingValues DOUBLE 向量 类型。与观察日期对齐的定盘值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

fixingWeights DOUBLE 向量 类型。观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PingPongOption 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
dailyObsDates = [2020.02.21]
dailyObsValues = [0.0]
dailyObsWeights = [1.0]
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createPingPongOption(
    2020.08.19, 2020.08.20, "DOWN_IN", underlyingPrice * 0.95,
    "UP_IN", underlyingPrice * 1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.015, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_PP_INST",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createPhoenixAutoCallableNote

语法

```dolphindb
caplib::createPhoenixAutoCallableNote(couponPayoffType, couponStrike, couponRate, dayCountConvention, startDate, couponDates, knockOutBarrierType, knockOutBarrierValue, knockInBarrierType, knockInBarrierValue, longShort, knockInPayoffType, knockInPayoffStrike, expiry, delivery, settlementDays, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, knockOutDates, knockOutValues, knockOutWeights, knockInDates, knockInValues, knockInWeights[, returnJson])
```

详情

创建并缓存凤凰自动赎回票据。函数验证并转换字段，构造 `PhoenixAutoCallableNote` protobuf 并存入 ObjectCache，供后续分析使用。

参数

couponPayoffType STRING 类型。票息收益类型。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

couponStrike DOUBLE 类型。票息条件使用的行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

couponRate DOUBLE 类型。票息率。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

dayCountConvention STRING 类型。计息惯例。**有效性:** 值必须是以下完整 protobuf 标签之一：`ACT_360`, `ACTUAL_360`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `ACT_ACT_ISMA`, `ACTUAL_ACTUAL_ISMA`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `THIRTY_360`, `BOND_BASIS`, `THIRTY_E_360`, `EUROBOND_BASIS`, `THIRTY_E_360_ISDA`, `ONE_ONE`, `THIRTY_U_360`, `THIRTY_U_360_EOM`, `THIRTY_360_PSA`, `THIRTY_E_360_PLUS`, `THIRTY_360_IT`, `ACT_ACT_AFB`, `ACTUAL_ACTUAL_AFB`, `ACT_364`, `ACTUAL_364`, `ACT_365_25`, `ACTUAL_365_25`, `ACT_365_ACT`, `ACTUAL_365_ACTUAL`, `ACT_365_L`, `ACTUAL_365_LONG`, `ACT_365_NL`, `ACTUAL_365_NO_LEAP`, `ACT_ACT_YEAR`, `ACTUAL_ACTUAL_YEAR`, `BUSINESS_252`。

startDate DATE 类型。起始日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

couponDates DATE 向量 类型。票息支付日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

knockOutBarrierType STRING 类型。敲出障碍类型。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

knockOutBarrierValue DOUBLE 类型。敲出障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

knockInBarrierType STRING 类型。敲入障碍类型。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

knockInBarrierValue DOUBLE 类型。敲入障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

longShort STRING 类型。多空方向。**有效性:** 可接受值：`BUY`, `Buy`, `buy`, `SELL`, `Sell`, `sell`。仅接受所示精确拼写。

knockInPayoffType STRING 类型。敲入后收益类型。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

knockInPayoffStrike DOUBLE 类型。敲入后收益使用的行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

knockOutDates DATE 向量 类型。敲出观察日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

knockOutValues DOUBLE 向量 类型。与敲出日期对齐的敲出观察值数组。**有效性:** 所有障碍水平必须非负且有限，并与对应日期/权重向量等长。

knockOutWeights DOUBLE 向量 类型。敲出观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

knockInDates DATE 向量 类型。敲入观察日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

knockInValues DOUBLE 向量 类型。与敲入日期对齐的敲入观察值数组。**有效性:** 所有障碍水平必须非负且有限，并与对应日期/权重向量等长。

knockInWeights DOUBLE 向量 类型。敲入观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PhoenixAutoCallableNote 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


couponDates = [2020.02.21]
couponObsValues = [0.0]
couponObsWeights = [0.0]
currency = "CNY"
dailyObsDates = [2020.02.21]
dailyObsValues = [0.0]
dailyObsWeights = [1.0]
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createPhoenixAutoCallableNote(
    "CALL", underlyingPrice, 0.12, "ACT_365_FIXED", 2020.02.22,
    couponDates, "UP_OUT", underlyingPrice * 1.1, "DOWN_IN", underlyingPrice * 0.9,
    "SELL", "PUT", underlyingPrice * 0.85, 2020.08.19, 2020.08.20,
    1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_PH_INST",
    couponDates, couponObsValues, couponObsWeights,
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createSnowballAutoCallableNote

语法

```dolphindb
caplib::createSnowballAutoCallableNote(couponRate, startDate, couponDates, dayCountConvention, knockOutBarrierType, knockOutBarrierValue, knockInBarrierType, knockInBarrierValue, longShort, knockInPayoffType, knockInPayoffStrike, knockInPayoffGearing, referencePrice, expiry, delivery, settlementDays, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle, knockOutDates, knockOutValues, knockOutWeights, knockInDates, knockInValues, knockInWeights[, returnJson])
```

详情

创建并缓存雪球自动赎回票据。函数验证并转换字段，构造 `SnowballAutoCallableNote` protobuf 并存入 ObjectCache，供后续分析使用。

参数

couponRate DOUBLE 类型。票息率。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

startDate DATE 类型。起始日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

couponDates DATE 向量 类型。票息支付日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

dayCountConvention STRING 类型。计息惯例。**有效性:** 值必须是以下完整 protobuf 标签之一：`ACT_360`, `ACTUAL_360`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `ACT_ACT_ISMA`, `ACTUAL_ACTUAL_ISMA`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `THIRTY_360`, `BOND_BASIS`, `THIRTY_E_360`, `EUROBOND_BASIS`, `THIRTY_E_360_ISDA`, `ONE_ONE`, `THIRTY_U_360`, `THIRTY_U_360_EOM`, `THIRTY_360_PSA`, `THIRTY_E_360_PLUS`, `THIRTY_360_IT`, `ACT_ACT_AFB`, `ACTUAL_ACTUAL_AFB`, `ACT_364`, `ACTUAL_364`, `ACT_365_25`, `ACTUAL_365_25`, `ACT_365_ACT`, `ACTUAL_365_ACTUAL`, `ACT_365_L`, `ACTUAL_365_LONG`, `ACT_365_NL`, `ACTUAL_365_NO_LEAP`, `ACT_ACT_YEAR`, `ACTUAL_ACTUAL_YEAR`, `BUSINESS_252`。

knockOutBarrierType STRING 类型。敲出障碍类型。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

knockOutBarrierValue DOUBLE 类型。敲出障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

knockInBarrierType STRING 类型。敲入障碍类型。**有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。

knockInBarrierValue DOUBLE 类型。敲入障碍水平。**有效性:** 必须非负且有限；包装器通常仅检查类型。

longShort STRING 类型。多空方向。**有效性:** 可接受值：`BUY`, `Buy`, `buy`, `SELL`, `Sell`, `sell`。仅接受所示精确拼写。

knockInPayoffType STRING 类型。敲入后收益类型。**有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。

knockInPayoffStrike DOUBLE 类型。敲入后收益使用的行权价。**有效性:** 必须非负且有限；包装器仅检查类型/形状。

knockInPayoffGearing DOUBLE 类型。敲入收益杠杆。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

referencePrice DOUBLE 类型。收益结构使用的参考价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

expiry DATE 类型。到期日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

delivery DATE 类型。交割或结算日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。

settlementDays INT 类型。交易或行权到结算的工作日天数。**有效性:** 必须非负；包装器通常仅检查类型。

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；实测包装器校验该约束，违规值抛 IllegalArgumentException（2026-10-15 全新容器实测）。

payoffCurrency STRING 类型。收益支付币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlyingType STRING 类型。标的类型枚举。**有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。

underlyingCurrency STRING 类型。标的资产币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

knockOutDates DATE 向量 类型。敲出观察日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

knockOutValues DOUBLE 向量 类型。与敲出日期对齐的敲出观察值数组。**有效性:** 所有障碍水平必须非负且有限，并与对应日期/权重向量等长。

knockOutWeights DOUBLE 向量 类型。敲出观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

knockInDates DATE 向量 类型。敲入观察日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

knockInValues DOUBLE 向量 类型。与敲入日期对齐的敲入观察值数组。**有效性:** 所有障碍水平必须非负且有限，并与对应日期/权重向量等长。

knockInWeights DOUBLE 向量 类型。敲入观察权重数组。**有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 SnowballAutoCallableNote 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


couponDates = [2020.02.21]
couponObsValues = [0.0]
couponObsWeights = [0.0]
currency = "CNY"
dailyObsDates = [2020.02.21]
dailyObsValues = [0.0]
dailyObsWeights = [1.0]
underlying = "EURUSD"
underlyingPrice = 100.0
caplib::createSnowballAutoCallableNote(
    0.12, 2020.02.21, couponDates, "ACT_365_FIXED",
    "UP_OUT", underlyingPrice * 1.05, "DOWN_IN", underlyingPrice * 0.8,
    "SELL", "PUT", underlyingPrice, 1.0, underlyingPrice,
    2020.08.22, 2020.08.22, 1, 1000000.0,
    currency, "FUTURE", currency, underlying, "CM_SN_INST",
    couponDates, couponObsValues, couponObsWeights,
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### priceEqAmericanOption

语法

```dolphindb
caplib::priceEqAmericanOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益美式期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical pricing settings and EQ risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// American call on the 50ETF spot
americanOption = caplib::createAmericanOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    1, 1000000.0, currency, "SPOT", currency, underlying, "EQ_AMERICAN", false)
result = caplib::priceEqAmericanOption(americanOption, asOfDate, mktData,
    bsmAnalyticalSettings, riskSettings, "", "", true)
```

#### priceEqAsianOption

语法

```dolphindb
caplib::priceEqAsianOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益亚式期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical settings drive the surface build; Monte Carlo settings price the Asian payoff
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 1, "EQ_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MC_MODEL", false)
bsmMcSettings = caplib::createPricingSettings(currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "EQ_BSM_MC", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Discretely observed Asian call on the 50ETF spot
dailyObsDates = 2020.02.22..2020.08.19
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))
asianOption = caplib::createAsianOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    "FIXED_STRIKE", "ARITHMETIC_AVERAGE_METHOD", "DISCRETE_OBSERVATION_TYPE",
    1000000.0, currency, "SPOT", currency, underlying, "EQ_ASIAN",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceEqAsianOption(asianOption, asOfDate, mktData,
    bsmMcSettings, riskSettings, "", "", true)
```

#### priceEqDigitalOption

语法

```dolphindb
caplib::priceEqDigitalOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益数字期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical pricing settings and EQ risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Asset-or-nothing digital call on the 50ETF spot
digitalOption = caplib::createDigitalOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    0.0, 1.0, 1000000.0, currency, "SPOT", currency, underlying, "EQ_DIGITAL", false)
result = caplib::priceEqDigitalOption(digitalOption, asOfDate, mktData,
    bsmAnalyticalSettings, riskSettings, "", "", true)
```

#### priceEqOneTouchOption

语法

```dolphindb
caplib::priceEqOneTouchOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益单触碰期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical pricing settings and EQ risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Up-and-in one-touch with cash payout at maturity
oneTouchOption = caplib::createOneTouchOption(2020.08.19, 2020.08.20, "UP_IN",
    underlyingPrice * 1.05, "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    1.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying, "EQ_ONE_TOUCH", false)
result = caplib::priceEqOneTouchOption(oneTouchOption, asOfDate, mktData,
    bsmAnalyticalSettings, riskSettings, "", "", true)
```

#### priceEqDoubleTouchOption

语法

```dolphindb
caplib::priceEqDoubleTouchOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益双触碰期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical pricing settings and EQ risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Double-touch with cash payout at maturity
doubleTouchOption = caplib::createDoubleTouchOption(2020.08.19, 2020.08.20, "DOWN_IN",
    underlyingPrice * 0.95, "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    1.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying, "EQ_DOUBLE_TOUCH", false)
result = caplib::priceEqDoubleTouchOption(doubleTouchOption, asOfDate, mktData,
    bsmAnalyticalSettings, riskSettings, "", "", true)
```

#### priceEqSingleBarrierOption

语法

```dolphindb
caplib::priceEqSingleBarrierOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益单障碍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical pricing settings and EQ risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Up-and-in single-barrier call without rebates
singleBarrierOption = caplib::createSingleBarrierOption("CALL", underlyingPrice,
    2020.08.19, 2020.08.20, "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying, "EQ_SINGLE_BARRIER", false)
result = caplib::priceEqSingleBarrierOption(singleBarrierOption, asOfDate, mktData,
    bsmAnalyticalSettings, riskSettings, "", "", true)
```

#### priceEqDoubleBarrierOption

语法

```dolphindb
caplib::priceEqDoubleBarrierOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益双障碍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical pricing settings and EQ risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Double-knock-in call without rebates
doubleBarrierOption = caplib::createDoubleBarrierOption("CALL", underlyingPrice,
    2020.08.19, 2020.08.20, "DOWN_IN", underlyingPrice * 0.95, "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 0.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying,
    "EQ_DOUBLE_BARRIER", false)
result = caplib::priceEqDoubleBarrierOption(doubleBarrierOption, asOfDate, mktData,
    bsmAnalyticalSettings, riskSettings, "", "", true)
```

#### priceEqSingleSharkFinOption

语法

```dolphindb
caplib::priceEqSingleSharkFinOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益单鲨鱼鳍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical settings drive the surface build; PDE settings price the shark-fin payoff
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
pdeSettings = caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "EQ_PDE_SETTINGS", false)
bsmPdeModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_PDE_MODEL", false)
bsmPdeSettings = caplib::createPricingSettings(currency, "PDE", 0, 0, take(0, 0), bsmPdeModel, pdeSettings, "", "EQ_BSM_PDE", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Discretely observed single shark-fin call
dailyObsDates = 2020.02.22..2020.08.19
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))
singleSharkFinOption = caplib::createSingleSharkFinOption("CALL", underlyingPrice,
    2020.08.19, 2020.08.20, 1.0, "RELATIVE_PERFORM_TYPE", "UP_OUT", underlyingPrice * 1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying, "EQ_SINGLE_SHARKFIN",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceEqSingleSharkFinOption(singleSharkFinOption, asOfDate, mktData,
    bsmPdeSettings, riskSettings, "", "", true)
```

#### priceEqDoubleSharkFinOption

语法

```dolphindb
caplib::priceEqDoubleSharkFinOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益双鲨鱼鳍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical settings drive the surface build; PDE settings price the shark-fin payoff
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
pdeSettings = caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "EQ_PDE_SETTINGS", false)
bsmPdeModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_PDE_MODEL", false)
bsmPdeSettings = caplib::createPricingSettings(currency, "PDE", 0, 0, take(0, 0), bsmPdeModel, pdeSettings, "", "EQ_BSM_PDE", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Discretely observed double shark-fin note
dailyObsDates = 2020.02.22..2020.08.19
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))
doubleSharkFinOption = caplib::createDoubleSharkFinOption(underlyingPrice, underlyingPrice,
    2020.08.19, 2020.08.20, 1.0, 1.0, "ABSOLUTE_PERFORM_TYPE",
    underlyingPrice * 0.95, underlyingPrice * 1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 0.0, 0.0, 1, 1000000.0, currency, "SPOT", currency, underlying,
    "EQ_DOUBLE_SHARKFIN", dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceEqDoubleSharkFinOption(doubleSharkFinOption, asOfDate, mktData,
    bsmPdeSettings, riskSettings, "", "", true)
```

#### priceEqPingPongOption

语法

```dolphindb
caplib::priceEqPingPongOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益乒乓期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical settings (surface build) and Monte Carlo pricing settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 1, "EQ_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MC_MODEL", false)
bsmMcSettings = caplib::createPricingSettings(currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "EQ_BSM_MC", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Discretely observed ping-pong option between +/-5% barriers
dailyObsDates = 2020.02.22..2020.08.19
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))
pingPongOption = caplib::createPingPongOption(2020.08.19, 2020.08.20,
    "DOWN_IN", underlyingPrice * 0.95, "UP_IN", underlyingPrice * 1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY", 0.015, 0.0,
    1, 1000000.0, currency, "SPOT", currency, underlying, "EQ_PINGPONG",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceEqPingPongOption(pingPongOption, asOfDate, mktData,
    bsmMcSettings, riskSettings, "", "", true)
```

#### priceEqAirbagOption

语法

```dolphindb
caplib::priceEqAirbagOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益安全气囊期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical settings drive the surface build; PDE settings price the airbag payoff
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
pdeSettings = caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "EQ_PDE_SETTINGS", false)
bsmPdeModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_PDE_MODEL", false)
bsmPdeSettings = caplib::createPricingSettings(currency, "PDE", 0, 0, take(0, 0), bsmPdeModel, pdeSettings, "", "EQ_BSM_PDE", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Discretely observed airbag with a knock-in strike at the spot
dailyObsDates = 2020.02.22..2020.08.19
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))
airbagOption = caplib::createAirbagOption("CALL", 2020.08.19, 2020.08.20,
    underlyingPrice, underlyingPrice * 1.05, 1.0, 1.0, underlyingPrice,
    "DOWN_IN", underlyingPrice * 0.8, "DISCRETE_OBSERVATION_TYPE",
    1000000.0, currency, "SPOT", currency, underlying, "EQ_AIRBAG",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceEqAirbagOption(airbagOption, asOfDate, mktData,
    bsmPdeSettings, riskSettings, "", "", true)
```

#### priceEqRangeAccrualOption

语法

```dolphindb
caplib::priceEqRangeAccrualOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益区间累计期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical pricing settings and EQ risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Daily-observed range accrual within +/-5% barriers
dailyObsDates = 2020.02.22..2020.08.19
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))
rangeAccrualOption = caplib::createRangeAccrualOption(2020.08.19, 2020.08.20,
    0.0, 0.01, underlyingPrice * 0.95, underlyingPrice * 1.05,
    1000000.0, currency, "SPOT", currency, underlying, "EQ_RANGE_ACCRUAL",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceEqRangeAccrualOption(rangeAccrualOption, asOfDate, mktData,
    bsmAnalyticalSettings, riskSettings, "", "", true)
```

#### priceEqPhoenixAutoCallableNote

语法

```dolphindb
caplib::priceEqPhoenixAutoCallableNote(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益凤凰自动赎回票据。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical settings (surface build) and Monte Carlo pricing settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 1, "EQ_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MC_MODEL", false)
bsmMcSettings = caplib::createPricingSettings(currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "EQ_BSM_MC", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Monthly coupons with knock-out/knock-in barriers and a short put floor
couponDates = [2020.03.23, 2020.04.22, 2020.05.22, 2020.06.22, 2020.07.23, 2020.08.22]
couponObsValues = take(0.0, size(couponDates))
couponObsWeights = take(1.0, size(couponDates))
dailyObsDates = 2020.02.22..2020.08.19
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))
phoenixNote = caplib::createPhoenixAutoCallableNote("CALL", underlyingPrice, 0.12,
    "ACT_365_FIXED", 2020.02.22, couponDates, "UP_OUT", underlyingPrice * 1.1,
    "DOWN_IN", underlyingPrice * 0.9, "SELL", "PUT", underlyingPrice * 0.85,
    2020.08.19, 2020.08.20, 1, 1000000.0, currency, "SPOT", currency, underlying,
    "EQ_PHOENIX", couponDates, couponObsValues, couponObsWeights,
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceEqPhoenixAutoCallableNote(phoenixNote, asOfDate, mktData,
    bsmMcSettings, riskSettings, "", "", true)
```

#### priceEqSnowballAutoCallableNote

语法

```dolphindb
caplib::priceEqSnowballAutoCallableNote(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价权益雪球自动赎回票据。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and market curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "50ETF.SSE"
underlyingPrice = 2.958
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24, 2020.05.24, 2020.08.24, 2020.11.24,
     2021.02.24, 2022.02.24, 2023.02.24, 2024.02.24, 2025.02.24, 2027.02.24, 2030.02.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655,
     0.0241740300538751, 0.0256822601972516, 0.0265096948143765, 0.0271330931714993,
     0.0274314991366822, 0.0284834397783798, 0.0297276346662025, 0.0308410887945891,
     0.032692683803743, 0.034410206396147],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
divCurve = caplib::createDividendCurve(asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate, "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "EQ_DIV_50ETF", "EQ_DIV_CURVE", false)

// BSM analytical settings (surface build) and Monte Carlo pricing settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
bsmAnalyticalSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 1, "EQ_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MC_MODEL", false)
bsmMcSettings = caplib::createPricingSettings(currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "EQ_BSM_MC", false)
riskSettings = caplib::createEqRiskSettings(0, 0, 0, 0, "EQ_RISK", false)

// Equity option quote matrix, surface definition and build settings
termDates = [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23]
payoffTypes = [take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5),
               take("PUT", 10) join take("CALL", 5), take("PUT", 10) join take("CALL", 5)]
optionPrices = [
    [0.0002, 0.0002, 0.0002, 0.0002, 0.0004, 0.0008, 0.0015, 0.0023, 0.0065, 0.0184, 0.0053, 0.0012, 0.0005, 0.0001, 0.0001],
    [0.0027, 0.0033, 0.0040, 0.0054, 0.0081, 0.0113, 0.0172, 0.0270, 0.0400, 0.0608, 0.0498, 0.0216, 0.0110, 0.0066, 0.0046],
    [0.0201, 0.0230, 0.0281, 0.0345, 0.0433, 0.0541, 0.0668, 0.0818, 0.1004, 0.1229, 0.1325, 0.0935, 0.0659, 0.0470, 0.0330],
    [0.0365, 0.0434, 0.0516, 0.0612, 0.0724, 0.0862, 0.1015, 0.1184, 0.1381, 0.1595, 0.1930, 0.1483, 0.1298, 0.0897, 0.0702]]
optionStrikes = [
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4],
    [2.5, 2.55, 2.6, 2.65, 2.7, 2.75, 2.8, 2.85, 2.9, 2.95, 3.0, 3.1, 3.2, 3.3, 3.4]]
optionQuotes = caplib::createEqOptionQuoteMatrix("EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, optionPrices, optionStrikes, underlying, "EQ_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "EQ_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", false)
volSurface = caplib::buildEqVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [underlyingPrice], irCurve, divCurve, volBuildSettings, bsmAnalyticalSettings,
    "EQ_VOL_SURF", false)

// Quanto curves and the EQ market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "EQ_QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "EQ_QUANTO_FX_VOL", false)
mktData = caplib::createEqMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, divCurve, volSurface, quantoIr, quantoFxVol, 0.0, "EQ_MKT", false)

// Monthly coupons with knock-out/knock-in barriers and a short put at spot
couponDates = [2020.03.23, 2020.04.22, 2020.05.22, 2020.06.22, 2020.07.23, 2020.08.22]
couponObsValues = take(0.0, size(couponDates))
couponObsWeights = take(1.0, size(couponDates))
dailyObsDates = 2020.02.22..2020.08.19
dailyObsValues = take(0.0, size(dailyObsDates))
dailyObsWeights = take(1.0, size(dailyObsDates))
snowballNote = caplib::createSnowballAutoCallableNote(0.12, 2020.02.21, couponDates,
    "ACT_365_FIXED", "UP_OUT", underlyingPrice * 1.05, "DOWN_IN", underlyingPrice * 0.8,
    "SELL", "PUT", underlyingPrice, 1.0, underlyingPrice,
    2020.08.19, 2020.08.20, 1, 1000000.0, currency, "SPOT", currency, underlying,
    "EQ_SNOWBALL", couponDates, couponObsValues, couponObsWeights,
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
result = caplib::priceEqSnowballAutoCallableNote(snowballNote, asOfDate, mktData,
    bsmMcSettings, riskSettings, "", "", true)
```

### 商品

#### buildCmVolatilitySurface

语法

```dolphindb
caplib::buildCmVolatilitySurface(asOfDate, underlying, definitionHandle, quoteMatrixHandle, underlyingPrices, discountCurveHandle, fwdCurveHandle, buildSettingsHandle, handle[, returnJson])
```

详情

构建商品波动率曲面。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `VolatilitySurface`。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

definitionHandle STRING 类型。波动率曲面定义 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

quoteMatrixHandle STRING 类型。期权报价矩阵 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

underlyingPrices DOUBLE 向量 类型。与报价期限或校准行对齐的标的价格数组。**有效性:** 所有元素必须有限并与配对日期等长；通常应为正，但可出现负价格的市场由下游业务规则决定。

discountCurveHandle STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

fwdCurveHandle STRING 类型。远期曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

buildSettingsHandle STRING 类型。构建设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolatilitySurface 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying and curves
asOfDate = 2020.02.21
underlying = "CU.SHFE"
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CNY", "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// Option quote matrix: two tenors, nine strikes per tenor
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)

// Surface definition and build settings
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)

// One underlying forward price per quote tenor
underlyingPrices = [66460.0, 66380.0]
result = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    underlyingPrices, irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", true)
```

#### buildPmYieldCurve

语法

```dolphindb
caplib::buildPmYieldCurve(asOfDate, parCurveHandle, discountCurveHandle, pmTemplateHandle, spotPrice, calcJacobian, dayCountConvention, interpMethod, extrapMethod, curveType, curveName, shift, method, mode, handle[, returnJson])
```

详情

构建贵金属收益率曲线。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `DividendCurve`。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

parCurveHandle STRING 类型。平价曲线输入对象 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

discountCurveHandle STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pmTemplateHandle STRING 类型。贵金属模板 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

spotPrice DOUBLE 类型。标的或贵金属的即期价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

calcJacobian INT 类型。是否计算并返回校准雅可比信息。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

dayCountConvention STRING 类型。计息惯例。**有效性:** 值必须是以下完整 protobuf 标签之一：`ACT_360`, `ACTUAL_360`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `ACT_ACT_ISMA`, `ACTUAL_ACTUAL_ISMA`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `THIRTY_360`, `BOND_BASIS`, `THIRTY_E_360`, `EUROBOND_BASIS`, `THIRTY_E_360_ISDA`, `ONE_ONE`, `THIRTY_U_360`, `THIRTY_U_360_EOM`, `THIRTY_360_PSA`, `THIRTY_E_360_PLUS`, `THIRTY_360_IT`, `ACT_ACT_AFB`, `ACTUAL_ACTUAL_AFB`, `ACT_364`, `ACTUAL_364`, `ACT_365_25`, `ACTUAL_365_25`, `ACT_365_ACT`, `ACTUAL_365_ACTUAL`, `ACT_365_L`, `ACTUAL_365_LONG`, `ACT_365_NL`, `ACTUAL_365_NO_LEAP`, `ACT_ACT_YEAR`, `ACTUAL_ACTUAL_YEAR`, `BUSINESS_252`。

interpMethod STRING 类型。插值方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `SABR_INTERP`, `SVI_INTERP`, `LOG_MONEYNESS_CUBIC_SPLINE_INTERP`, `SABR_NORMAL_INTERP`, `QUADRATIC_POLYNOMIAL_INTERP`, `CUBIC_POLYNOMIAL_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。

extrapMethod STRING 类型。外推方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`FLAT_EXTRAP`, `LINEAR_EXTRAP`, `NATURAL_EXTRAP`, `ADJ_FLAT_EXTRAP`。

curveType STRING 类型。曲线值类型，例如零利率、贴现因子或利差。**有效性:** 值必须是以下完整 protobuf 标签之一：`ZERO_RATE`, `LOG_DISCOUNT`, `FORWARD_RATE`。

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

shift DOUBLE 类型。风险或校准计算使用的扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

method STRING 类型。计算、校准或有限差分方法选择器。**有效性:** 值必须是以下完整 protobuf 标签之一：`CENTRAL_DIFFERENCE_METHOD`, `ONE_SIDE_DOWN_METHOD`, `ONE_SIDE_UP_METHOD`。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 值必须是以下完整 protobuf 标签之一：`SINGLE_THREADING_MODE`, `MULTI_THREADING_MODE`。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 DividendCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2019.09.04

// Business calendar and PM cash template
caplib::createCalendar("CAL_GBLO", [44623])
pmCashTemplate = caplib::createPmCashTemplate("XAUUSD", 2, "FOLLOWING", ["CAL_GBLO"], "ACT_360", false)

// USD deposit discount curve
discountCurve = caplib::createIrYieldCurve(asOfDate,
    [2019.09.09, 2019.11.06, 2020.06.08, 2021.03.08, 2023.09.06, 2026.09.07, 2034.09.06, 2049.09.06],
    [0.021594, 0.019103, 0.015248, 0.012617, 0.010018, 0.011028, 0.013473, 0.015525],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "USD_DEPO_CURVE", false)

// PM par rate curve with pillar swap rates
parCurve = caplib::createPmParRateCurve(asOfDate, "USD", "XAU_XAUUSD",
    table(
        ["XAUUSD","XAUUSD","XAUUSD","XAUUSD","XAUUSD","XAUUSD","XAUUSD","XAUUSD","XAUUSD"] as instrument_name,
        ["PM_SWAP","PM_SWAP","PM_SWAP","PM_SWAP","PM_SWAP","PM_SWAP","PM_SWAP","PM_SWAP","PM_SWAP"] as instrument_type,
        ["1W","2W","1M","2M","3M","6M","9M","12M","2Y"] as instrument_term,
        [0.025, 0.025, 0.0248, 0.02, 0.0235, 0.0223, 0.0203, 0.0192, 0.0152] as instrument_rate),
    "PM_PAR_CURVE", false)

result = caplib::buildPmYieldCurve(asOfDate, parCurve, discountCurve, pmCashTemplate, 1544.06, 0,
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", "ZERO_RATE", "XAU_XAUUSD", 1.0e-4,
    "CENTRAL_DIFFERENCE_METHOD", "SINGLE_THREADING_MODE", "PM_YIELD_CURVE", true)
```

#### buildPmVolatilitySurface

语法

```dolphindb
caplib::buildPmVolatilitySurface(asOfDate, underlying, definitionHandle, quoteMatrixHandle, underlyingPrice, discountCurveHandle, fwdCurveHandle, buildSettingsHandle, marketConventionsHandle, spotTemplateHandle, handle[, returnJson])
```

详情

构建贵金属波动率曲面。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `VolatilitySurface`。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

definitionHandle STRING 类型。波动率曲面定义 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

quoteMatrixHandle STRING 类型。期权报价矩阵 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

underlyingPrice DOUBLE 类型。当前标的价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

discountCurveHandle STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

fwdCurveHandle STRING 类型。远期曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

buildSettingsHandle STRING 类型。构建设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

marketConventionsHandle STRING 类型。市场惯例 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

spotTemplateHandle STRING 类型。即期模板 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 VolatilitySurface 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2019.09.04
underlying = "XAUUSD"
spotPrice = 1544.06

// Calendar, cash template, USD deposit curve and PM par curve
caplib::createCalendar("CAL_CFETS")
caplib::createPmCashTemplate(underlying, 2, "FOLLOWING", ["CAL_CFETS"], "ACT_360", false)
depoCurve = caplib::createIrYieldCurve(asOfDate, [2019.09.09, 2020.09.08, 2021.09.07],
    [0.021594, 0.014216, 0.012617], "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_DEPO", "PM_DEPO_CURVE", false)
caplib::createPmParRateCurve(asOfDate, "USD", "XAU_XAUUSD",
    table(["XAUUSD","XAUUSD","XAUUSD"] as instrument_name,
          ["PM_SWAP","PM_SWAP","PM_SWAP"] as instrument_type,
          ["1M","6M","12M"] as instrument_term,
          [0.0248, 0.0223, 0.0192] as instrument_rate), "PM_PAR_CURVE", false)
fwdCurve = caplib::buildPmYieldCurve(asOfDate, "PM_PAR_CURVE", "PM_DEPO_CURVE", underlying, spotPrice, 0,
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", "ZERO_RATE", "XAU_XAUUSD", 0.0001,
    "CENTRAL_DIFFERENCE_METHOD", "SINGLE_THREADING_MODE", "PM_FWD_CURVE", false)

// PM option quote matrix, market conventions, surface definition and build settings
caplib::createPmOptionQuoteMatrix(underlying, asOfDate, ["1M", "6M", "1Y"],
    [["ATM_STRADDLE", "RISK_REVERSAL", "BUTTERFLY", "RISK_REVERSAL", "BUTTERFLY"],
     ["ATM_STRADDLE", "RISK_REVERSAL", "BUTTERFLY", "RISK_REVERSAL", "BUTTERFLY"],
     ["ATM_STRADDLE", "RISK_REVERSAL", "BUTTERFLY", "RISK_REVERSAL", "BUTTERFLY"]],
    [[0, 0.25, 0.25, 0.10, 0.10],
     [0, 0.25, 0.25, 0.10, 0.10],
     [0, 0.25, 0.25, 0.10, 0.10]],
    [[0.15340, 0.03623, 0.00578, 0.06738, 0.01753],
     [0.15153, 0.04255, 0.00808, 0.08120, 0.02148],
     [0.15383, 0.04725, 0.01070, 0.09253, 0.02838]], "PM_QUOTE_MATRIX", false)
caplib::createPmMktConventions("ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "PIPS_SPOT_DELTA", "RR_CALL_PUT", "BUTTERFLY_QUOTE", underlying, "PM_MKT_CONV", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD", "FLAT_EXTRAP",
    "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY", "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -0.0001, 0.0001, "PM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "PM_VOL_BUILD", false)

result = caplib::buildPmVolatilitySurface(asOfDate, underlying, volDef, "PM_QUOTE_MATRIX", spotPrice,
    "PM_DEPO_CURVE", fwdCurve, volBuildSettings, "PM_MKT_CONV", underlying, "PM_VOL_SURF", true)
```

#### createCmMktDataSet

语法

```dolphindb
caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice, discountCurve, dividendCurve, volSurface, quantoDiscountCurve, quantoFxVolCurve, quantoCorrelation, handle[, returnJson])
```

详情

创建并缓存商品市场数据集。函数验证并转换字段，构造 `CmMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

underlyingPrice DOUBLE 类型。当前标的价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

discountCurve STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

dividendCurve STRING 类型。股息或远期收益曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

volSurface STRING 类型。波动率曲面 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

quantoDiscountCurve STRING 类型。Quanto 贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

quantoFxVolCurve STRING 类型。Quanto 外汇波动率曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

quantoCorrelation DOUBLE 类型。Quanto 调整相关系数。**有效性:** 必须有限且业务有效范围为 `[-1,1]`；包装器仅检查类型。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CmMktDataSet 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CNY", "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// Build the volatility surface from a compact option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Explicit zero-rate quanto curves, even with zero correlation
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)

result = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", true)
```

#### createCmRiskSettings

语法

```dolphindb
caplib::createCmRiskSettings(irDelta, priceDelta, volVega, theta, handle[, returnJson])
```

详情

创建并缓存商品风险设置。函数验证并转换字段，构造 `CmRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

irDelta INT 类型。是否计算利率 Delta 风险。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

priceDelta INT 类型。是否计算标的价格 Delta 风险。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

volVega INT 类型。是否计算波动率 Vega 风险。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

theta INT 类型。是否计算 Theta 风险。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CmRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", true)
```

#### priceCmEuropeanOption

语法

```dolphindb
caplib::priceCmEuropeanOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品欧式期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM analytical pricing settings and CM risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "CM_BSM_ANALYTICAL", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// European call on the copper future
europeanOption = caplib::createEuropeanOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    1000000.0, currency, "FUTURE", currency, underlying, "CM_EUROPEAN", false)
result = caplib::priceCmEuropeanOption(europeanOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmAmericanOption

语法

```dolphindb
caplib::priceCmAmericanOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品美式期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM analytical pricing settings and CM risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "CM_BSM_ANALYTICAL", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// American call on the copper future
americanOption = caplib::createAmericanOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_AMERICAN", false)
result = caplib::priceCmAmericanOption(americanOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmAsianOption

语法

```dolphindb
caplib::priceCmAsianOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品亚式期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM Monte Carlo pricing settings and CM risk settings
modelParams = [0.0]
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 1, "CM_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MC_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "CM_BSM_MC", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Daily average observation schedule and arithmetic average Asian call
obsDates = 2020.02.22..2020.08.19
obsValues = take(0.0, size(obsDates))
obsWeights = take(1.0, size(obsDates))
asianOption = caplib::createAsianOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    "FIXED_STRIKE", "ARITHMETIC_AVERAGE_METHOD", "DISCRETE_OBSERVATION_TYPE", 1000000.0,
    currency, "FUTURE", currency, underlying, "CM_ASIAN", obsDates, obsValues, obsWeights, false)
result = caplib::priceCmAsianOption(asianOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmDigitalOption

语法

```dolphindb
caplib::priceCmDigitalOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品数字期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM analytical pricing settings and CM risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "CM_BSM_ANALYTICAL", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Cash-or-nothing digital call paying 1.0 per notional
digitalOption = caplib::createDigitalOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    0.0, 1.0, 1000000.0, currency, "FUTURE", currency, underlying, "CM_DIGITAL", false)
result = caplib::priceCmDigitalOption(digitalOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmOneTouchOption

语法

```dolphindb
caplib::priceCmOneTouchOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品单触碰期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM analytical pricing settings and CM risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "CM_BSM_ANALYTICAL", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Up-and-in one-touch option with continuous observation
oneTouchOption = caplib::createOneTouchOption(2020.08.19, 2020.08.20, "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY", 1.0, 0.0, 1, 1000000.0,
    currency, "FUTURE", currency, underlying, "CM_ONE_TOUCH", false)
result = caplib::priceCmOneTouchOption(oneTouchOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmDoubleTouchOption

语法

```dolphindb
caplib::priceCmDoubleTouchOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品双触碰期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM analytical pricing settings and CM risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "CM_BSM_ANALYTICAL", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Double-touch option with a lower down-in and an upper up-in barrier
doubleTouchOption = caplib::createDoubleTouchOption(2020.08.19, 2020.08.20,
    "DOWN_IN", underlyingPrice * 0.95, "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY", 1.0, 0.0, 1, 1000000.0,
    currency, "FUTURE", currency, underlying, "CM_DOUBLE_TOUCH", false)
result = caplib::priceCmDoubleTouchOption(doubleTouchOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmSingleBarrierOption

语法

```dolphindb
caplib::priceCmSingleBarrierOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品单障碍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM analytical pricing settings and CM risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "CM_BSM_ANALYTICAL", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Up-and-in single barrier call
singleBarrierOption = caplib::createSingleBarrierOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    "UP_IN", underlyingPrice * 1.05, "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_SINGLE_BARRIER", false)
result = caplib::priceCmSingleBarrierOption(singleBarrierOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmDoubleBarrierOption

语法

```dolphindb
caplib::priceCmDoubleBarrierOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品双障碍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM analytical pricing settings and CM risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "CM_BSM_ANALYTICAL", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Knock-in double barrier call with lower and upper barriers
doubleBarrierOption = caplib::createDoubleBarrierOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    "DOWN_IN", underlyingPrice * 0.95, "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 0.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_DOUBLE_BARRIER", false)
result = caplib::priceCmDoubleBarrierOption(doubleBarrierOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmSingleSharkFinOption

语法

```dolphindb
caplib::priceCmSingleSharkFinOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品单鲨鱼鳍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM PDE pricing settings and CM risk settings
modelParams = [0.0]
pdeSettings = caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "CM_PDE_SETTINGS", false)
bsmPdeModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_PDE_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "PDE", 0, 0, take(0, 0), bsmPdeModel, pdeSettings, "", "CM_BSM_PDE", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Discrete observation schedule and up-and-out single shark fin call
obsDates = 2020.02.22..2020.08.19
obsValues = take(0.0, size(obsDates))
obsWeights = take(1.0, size(obsDates))
singleSharkFinOption = caplib::createSingleSharkFinOption("CALL", underlyingPrice, 2020.08.19, 2020.08.20, 1.0,
    "RELATIVE_PERFORM_TYPE", "UP_OUT", underlyingPrice * 1.05, "DISCRETE_OBSERVATION_TYPE",
    "PAY_AT_MATURITY", 0.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying,
    "CM_SINGLE_SHARK_FIN", obsDates, obsValues, obsWeights, false)
result = caplib::priceCmSingleSharkFinOption(singleSharkFinOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmDoubleSharkFinOption

语法

```dolphindb
caplib::priceCmDoubleSharkFinOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品双鲨鱼鳍期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM PDE pricing settings and CM risk settings
modelParams = [0.0]
pdeSettings = caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "CM_PDE_SETTINGS", false)
bsmPdeModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_PDE_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "PDE", 0, 0, take(0, 0), bsmPdeModel, pdeSettings, "", "CM_BSM_PDE", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Discrete observation schedule and double shark fin note
obsDates = 2020.02.22..2020.08.19
obsValues = take(0.0, size(obsDates))
obsWeights = take(1.0, size(obsDates))
doubleSharkFinOption = caplib::createDoubleSharkFinOption(underlyingPrice, underlyingPrice,
    2020.08.19, 2020.08.20, 1.0, 1.0, "ABSOLUTE_PERFORM_TYPE",
    underlyingPrice * 0.95, underlyingPrice * 1.05, "DISCRETE_OBSERVATION_TYPE",
    "PAY_AT_MATURITY", 0.0, 0.0, 0.0, 0.0, 1, 1000000.0,
    currency, "FUTURE", currency, underlying, "CM_DOUBLE_SHARK_FIN",
    obsDates, obsValues, obsWeights, false)
result = caplib::priceCmDoubleSharkFinOption(doubleSharkFinOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmPingPongOption

语法

```dolphindb
caplib::priceCmPingPongOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品乒乓期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM Monte Carlo pricing settings and CM risk settings
modelParams = [0.0]
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 1, "CM_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MC_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "CM_BSM_MC", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Discrete observation schedule and ping-pong option
obsDates = 2020.02.22..2020.08.19
obsValues = take(0.0, size(obsDates))
obsWeights = take(1.0, size(obsDates))
pingPongOption = caplib::createPingPongOption(2020.08.19, 2020.08.20,
    "DOWN_IN", underlyingPrice * 0.95, "UP_IN", underlyingPrice * 1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY", 0.015, 0.0, 1, 1000000.0,
    currency, "FUTURE", currency, underlying, "CM_PING_PONG",
    obsDates, obsValues, obsWeights, false)
result = caplib::priceCmPingPongOption(pingPongOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmAirbagOption

语法

```dolphindb
caplib::priceCmAirbagOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品安全气囊期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM PDE pricing settings and CM risk settings
modelParams = [0.0]
pdeSettings = caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "CM_PDE_SETTINGS", false)
bsmPdeModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_PDE_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "PDE", 0, 0, take(0, 0), bsmPdeModel, pdeSettings, "", "CM_BSM_PDE", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Discrete observation schedule and airbag option
obsDates = 2020.02.22..2020.08.19
obsValues = take(0.0, size(obsDates))
obsWeights = take(1.0, size(obsDates))
airbagOption = caplib::createAirbagOption("CALL", 2020.08.19, 2020.08.20,
    underlyingPrice, underlyingPrice * 1.05, 1.0, 1.0, underlyingPrice,
    "DOWN_IN", underlyingPrice * 0.8, "DISCRETE_OBSERVATION_TYPE",
    1000000.0, currency, "FUTURE", currency, underlying, "CM_AIRBAG",
    obsDates, obsValues, obsWeights, false)
result = caplib::priceCmAirbagOption(airbagOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmRangeAccrualOption

语法

```dolphindb
caplib::priceCmRangeAccrualOption(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品区间累计期权。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM analytical pricing settings and CM risk settings
modelParams = [0.0]
bsmModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "ANALYTICAL", 0, 0, take(0, 0), bsmModel, "", "", "CM_BSM_ANALYTICAL", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Daily observation schedule and range accrual option
obsDates = 2020.02.22..2020.08.19
obsValues = take(0.0, size(obsDates))
obsWeights = take(1.0, size(obsDates))
rangeAccrualOption = caplib::createRangeAccrualOption(2020.08.19, 2020.08.20, 0.0, 0.01,
    underlyingPrice * 0.95, underlyingPrice * 1.05, 1000000.0,
    currency, "FUTURE", currency, underlying, "CM_RANGE_ACCRUAL",
    obsDates, obsValues, obsWeights, false)
result = caplib::priceCmRangeAccrualOption(rangeAccrualOption, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmPhoenixAutoCallableNote

语法

```dolphindb
caplib::priceCmPhoenixAutoCallableNote(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品凤凰自动赎回票据。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM Monte Carlo pricing settings and CM risk settings
modelParams = [0.0]
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 1, "CM_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MC_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "CM_BSM_MC", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Coupon and daily observation schedules for the phoenix auto-callable note
couponDates = [2020.03.23, 2020.04.22, 2020.05.22, 2020.06.22, 2020.07.23, 2020.08.22]
couponValues = take(0.0, size(couponDates))
couponWeights = take(1.0, size(couponDates))
obsDates = 2020.02.22..2020.08.19
obsValues = take(0.0, size(obsDates))
obsWeights = take(1.0, size(obsDates))
phoenixNote = caplib::createPhoenixAutoCallableNote("CALL", underlyingPrice, 0.12, "ACT_365_FIXED",
    2020.02.22, couponDates, "UP_OUT", underlyingPrice * 1.1, "DOWN_IN", underlyingPrice * 0.9,
    "SELL", "PUT", underlyingPrice * 0.85, 2020.08.19, 2020.08.20, 1, 1000000.0,
    currency, "FUTURE", currency, underlying, "CM_PHOENIX",
    couponDates, couponValues, couponWeights, obsDates, obsValues, obsWeights, false)
result = caplib::priceCmPhoenixAutoCallableNote(phoenixNote, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### priceCmSnowballAutoCallableNote

语法

```dolphindb
caplib::priceCmSnowballAutoCallableNote(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价商品雪球自动赎回票据。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Valuation date, underlying, discount and forward curves
asOfDate = 2020.02.21
currency = "CNY"
underlying = "CU.SHFE"
underlyingPrice = 66380.00
irCurve = caplib::createIrYieldCurve(asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_SHIBOR_3M", "CM_IR_CURVE", false)
fwdCurve = caplib::createDividendCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0], asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CM_FLAT_FWD", "CM_FWD_CURVE", false)

// BSM Monte Carlo pricing settings and CM risk settings
modelParams = [0.0]
mcSettings = caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 1, "CM_MC_SETTINGS", false)
bsmMcModel = caplib::createPricingModelSettings("BLACK_SCHOLES_MERTON", "", 0, modelParams, "CM_BSM_MC_MODEL", false)
pricingSettings = caplib::createPricingSettings(currency, "MONTE_CARLO", 0, 0, take(0, 0), bsmMcModel, "", mcSettings, "CM_BSM_MC", false)
riskSettings = caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", false)

// Build the volatility surface from a compact two-tenor option quote matrix
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
optionQuotes = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", false)
volDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA", -1.0e-5, 1.0e-5, "CM_VOL_DEF", false)
volBuildSettings = caplib::createVolSurfBuildSettings(1, 0.5, "CM_VOL_BUILD", false)
volSurface = caplib::buildCmVolatilitySurface(asOfDate, underlying, volDef, optionQuotes,
    [66460.0, 66380.0], irCurve, fwdCurve, volBuildSettings, "CM_VOL_SURF", false)

// Zero-rate quanto curves and the CM market data set
quantoIr = caplib::createIrYieldCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "USD", "USD_FLAT_ZERO", "QUANTO_IR", false)
quantoFxVol = caplib::createVolatilityCurve(asOfDate, [2020.02.22, 2030.02.24], [0.0, 0.0],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP", underlying, "QUANTO_FX_VOL", false)
mktData = caplib::createCmMktDataSet(asOfDate, underlying, underlyingPrice,
    irCurve, fwdCurve, volSurface, quantoIr, quantoFxVol, 0.0, "CM_MKT", false)

// Coupon and daily observation schedules for the snowball auto-callable note
couponDates = [2020.03.23, 2020.04.22, 2020.05.22, 2020.06.22, 2020.07.23, 2020.08.22]
couponValues = take(0.0, size(couponDates))
couponWeights = take(1.0, size(couponDates))
obsDates = 2020.02.22..2020.08.19
obsValues = take(0.0, size(obsDates))
obsWeights = take(1.0, size(obsDates))
snowballNote = caplib::createSnowballAutoCallableNote(0.12, 2020.02.21, couponDates, "ACT_365_FIXED",
    "UP_OUT", underlyingPrice * 1.05, "DOWN_IN", underlyingPrice * 0.8,
    "SELL", "PUT", underlyingPrice, 1.0, underlyingPrice, 2020.08.22, 2020.08.22,
    1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_SNOWBALL",
    couponDates, couponValues, couponWeights, obsDates, obsValues, obsWeights, false)
result = caplib::priceCmSnowballAutoCallableNote(snowballNote, asOfDate, mktData,
    pricingSettings, riskSettings, "", "", true)
```

#### createPmCashTemplate

语法

```dolphindb
caplib::createPmCashTemplate(instName, startDelay, deliveryDayConvention, calendars, dayCountConvention[, returnJson])
```

详情

创建并缓存贵金属现金工具模板。函数验证并转换字段，构造 `PmCashTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

参数

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

startDelay INT 类型。起息或交割延迟天数。**有效性:** 非负整数（天数）。

deliveryDayConvention STRING 类型。交割日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

calendars STRING 或 STRING 向量 类型。日期调整使用的业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

dayCountConvention STRING 类型。计息惯例。**有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。任何其他字符串均回退到函数指定的默认日计数。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PmCashTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Register the business calendar referenced by the template
caplib::createCalendar("CAL_CFETS")
result = caplib::createPmCashTemplate("XAUUSD", 2, "FOLLOWING", ["CAL_CFETS"], "ACT_360", true)
```

#### createPmParRateCurve

语法

```dolphindb
caplib::createPmParRateCurve(asOfDate, currency, curveName, pillarsTable MATRIX/TABLE, handle[, returnJson])
```

详情

创建并缓存贵金属平价利率曲线输入。函数验证并转换字段，构造 `PmParRateCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

pillarsTable MATRIX/TABLE 类型。曲线节点输入表。**有效性:** 必须具有所列元素类型和形状；元素不得为空；除明确说明外包装器不强制非空。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PmParRateCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2019.09.04
pillarsTable = table(
    ["XAUUSD","XAUUSD","XAUUSD"] as instrument_name,
    ["PM_SWAP","PM_SWAP","PM_SWAP"] as instrument_type,
    ["1W","2W","1M"] as instrument_term,
    [0.025, 0.025, 0.0248] as instrument_rate)
result = caplib::createPmParRateCurve(asOfDate, "USD", "XAU_XAUUSD", pillarsTable, "PM_PAR_CURVE", true)
```

#### createPmMktConventions

语法

```dolphindb
caplib::createPmMktConventions(atmType, shortDeltaType, longDeltaType, deltaCutoff, riskReversal, smileQuoteType, underlying, handle[, returnJson])
```

详情

创建并缓存贵金属市场惯例。函数验证并转换字段，构造 `PmMarketConventions` protobuf 并存入 ObjectCache，供后续分析使用。

参数

atmType STRING 类型。ATM 报价类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`ATM_FORWARD`, `ATM_DNS_PIPS`, `ATM_DNS_PERCENTAGE`, `ATM_SPOT`。

shortDeltaType STRING 类型。短期限 Delta 报价类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。

longDeltaType STRING 类型。长期限 Delta 报价类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。

deltaCutoff STRING 类型。Delta 报价切换阈值。**有效性:** 值必须是以下完整 protobuf 标签之一：`PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。

riskReversal STRING 类型。设置对象的缓存句柄或配置值。**有效性:** 值必须是以下完整 protobuf 标签之一：`RR_CALL_PUT`, `RR_PUT_CALL`。

smileQuoteType STRING 类型。波动率微笑报价类型。**有效性:** 值必须是以下完整 protobuf 标签之一：`BUTTERFLY_QUOTE`, `MARKET_STRANGLE_QUOTE`, `WINGS_RATIO_BF_QUOTE`。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PmMarketConventions 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

result = caplib::createPmMktConventions("ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "PERCENTAGE_SPOT_DELTA", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "XAUUSD", "PM_MKT_CONV", true)
```

#### createPmOptionQuoteMatrix

语法

```dolphindb
caplib::createPmOptionQuoteMatrix(underlying, asOfDate, terms, payoffTypes, deltas, quotes, handle[, returnJson])
```

详情

创建并缓存贵金属期权报价矩阵。函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

参数

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

terms STRING 向量 类型。报价期限数组。**有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。

payoffTypes STRING 矩阵/向量 类型。与报价值对齐的收益类型矩阵或向量。**有效性:** 每个元素必须是以下完整 protobuf 标签之一：`CALL`, `PUT`, `STRADDLE`, `STRANGLE`, `RISK_REVERSAL`, `BUTTERFLY`, `ATM_STRADDLE`。

deltas DOUBLE 矩阵/向量 类型。Delta 行权价矩阵或向量。**有效性:** 所有元素必须有限且位于 `[-1,1]`，形状须与配对报价矩阵一致；包装器仅强制形状/类型。

quotes DOUBLE 矩阵/向量 类型。市场报价值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 OptionQuoteMatrix 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2022.03.09
terms = ["1M"]
payoffTypes = ["CALL"]
deltas = [0.10]
quotes = matrix([450.0])
result = caplib::createPmOptionQuoteMatrix("AU.SHFE", asOfDate, terms, payoffTypes, deltas, quotes, "PM_OPTION_QUOTES", true)
```

#### createCmOptionQuoteMatrix

语法

```dolphindb
caplib::createCmOptionQuoteMatrix(exerciseType, underlyingType, asOfDate, termDates, payoffTypes, strikes, prices, underlying, handle[, returnJson])
```

详情

创建并缓存商品期权报价矩阵。函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

参数

exerciseType STRING 类型。期权行权风格。**有效性:** 值必须是以下完整 protobuf 标签之一：`EUROPEAN`, `AMERICAN`, `BERMUDAN`。

underlyingType STRING 类型。标的类型枚举。**有效性:** 值必须是以下完整 protobuf 标签之一：`SPOT_UNDERLYING_TYPE`, `FUTURE_UNDERLYING_TYPE`。

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

termDates DATE 向量 类型。报价期限对应的到期日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

payoffTypes STRING 矩阵/向量 类型。与报价值对齐的收益类型矩阵或向量。**有效性:** 每个元素必须是以下完整 protobuf 标签之一：`CALL`, `PUT`, `STRADDLE`, `STRANGLE`, `RISK_REVERSAL`, `BUTTERFLY`, `ATM_STRADDLE`。

strikes DOUBLE 矩阵/向量 类型。行权价数组或矩阵。**有效性:** 必须有限；价格型标的通常要求非负，利率型标的可为负。包装器仅检查类型/形状。

prices DOUBLE 矩阵/向量 类型。期权价格矩阵或报价数组。**有效性:** 所有元素必须非负且有限，并与配对行权价/期限参数形状一致；包装器主要检查类型/形状。

underlying STRING 类型。标的资产、指数、商品或货币对标识。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 OptionQuoteMatrix 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// Two expiry tenors, nine strikes per tenor
asOfDate = 2020.02.21
termDates = [2020.08.12, 2020.09.11]
payoffTypes = [take("PUT", 4) join take("CALL", 5), take("PUT", 4) join take("CALL", 5)]
strikes = [
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000],
    [63000, 64000, 65000, 66000, 67000, 68000, 69000, 70000, 71000]]
prices = [
    [2446.0, 2862.0, 3314.0, 3814.0, 3590.0, 3168.0, 2784.0, 2446.0, 2136.0],
    [2688.0, 3118.0, 3578.0, 4078.0, 3828.0, 3408.0, 3024.0, 2680.0, 2358.0]]
result = caplib::createCmOptionQuoteMatrix("AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, "CU.SHFE", "CM_OPTION_QUOTES", true)
```

### 信用

#### createCreditCurve

语法

```dolphindb
caplib::createCreditCurve(asOfDate, pillarDates, spreads, dayCountConvention, interp, extrap, name, handle[, returnJson])
```

详情

创建并缓存信用曲线。函数验证并转换字段，构造 `CreditCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

pillarDates DATE 向量 类型。曲线节点日期数组。**有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。

spreads DOUBLE 向量 类型。信用利差或曲线利差数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。

dayCountConvention STRING 类型。计息惯例。**有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。

interp STRING 类型。插值方法。**有效性:** 可接受值：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。仅接受所示精确拼写。

extrap STRING 类型。外推方法。**有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CreditCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
caplib::createCreditCurve(
    asOfDate,
    [2020.03.01, 2020.03.22, 2020.05.21, 2020.08.22],
    [0.0012, 0.0018, 0.0024, 0.0030],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "BOND_CREDIT", "CR_BASE_CREDIT_CURVE", false)
```

#### createCreditCurveRiskSettings

语法

```dolphindb
caplib::createCreditCurveRiskSettings(delta, gamma, shift, method, granularity, scaling, threading, handle[, returnJson])
```

详情

创建并缓存信用曲线风险设置。函数验证并转换字段，构造 `CreditCurveRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

delta BOOL 类型。是否计算 Delta 风险或 Delta 数值。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

gamma BOOL 类型。是否计算 Gamma 风险。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

shift DOUBLE 类型。风险或校准计算使用的扰动大小。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

method INT 类型。计算、校准或有限差分方法选择器。**有效性:** 映射：`value =2` 为 ONE_SIDE_UP。

granularity INT 类型。风险桶或扰动粒度。**有效性:** 映射：`value =2` 为 TERM_STRIKE。

scaling DOUBLE 类型。风险扰动缩放因子。**有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。

threading INT 类型。线程模式选择器。**有效性:** 仅 `1` 选择多线程；其他整数均为单线程。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CreditCurveRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createCreditCurveRiskSettings(
    1, 0, 1.0e-4, 0, 1, 1.0e-4, 0, "CR_CREDIT_RISK", false)
```

#### buildBondCreditSpreadCurve

语法

```dolphindb
caplib::buildBondCreditSpreadCurve(asOfDate, curveName, parCurveHandle, discountCurveHandle, forwardCurveHandle, buildingMethod, calcJacobian, handle[, returnJson])
```

详情

构建债券信用利差曲线。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `CreditCurve`。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

parCurveHandle STRING 类型。平价曲线输入对象 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

discountCurveHandle STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

forwardCurveHandle STRING 类型。远期曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

buildingMethod STRING 类型。曲线或曲面构建算法名称。**有效性:** 识别值：`BOOTSTRAP`, `BOOTSTRAPPING`, `BOOTSTRAPPING_METHOD`, `GLOBAL_OPTIMIZATION`, `GLOBAL_OPTIMIZATION_METHOD`, `HYBRID`, `HYBRID_METHOD`。不区分大小写。空值或其他字符串回退为 BOOTSTRAPPING_METHOD。

calcJacobian INT 类型。是否计算并返回校准雅可比信息。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CreditCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// 标准债券模板（同 test/cr/test_buildBondCreditSpreadCurve.dos 的 setup）
def createStdBondTemplate(instName, bondType, maturity, currency, calendarName, asOfDate) {
    return caplib::createVanillaBondTemplate(
        instName, bondType,
        asOfDate, 1, asOfDate, maturity,
        0.0, currency, 100.0,
        "ACT_365_FIXED", calendarName, "ANNUAL",
        "MODIFIED_FOLLOWING", "INITIAL", "LONG",
        0, "MODIFIED_FOLLOWING", "",
        "", "INVALID_FREQUENCY", "INVALID_BUSINESS_DAY_CONVENTION",
        "INVALID_DATE_GENERATION_MODE", -1,
        "0d", "", "INVALID_BUSINESS_DAY_CONVENTION", false,
        "CONST_NOTIONAL", 0.0, true);
}

asOfDate = 2021.07.22
currency = "CNY"
calCfets = "CAL_CFETS"
caplib::createCalendar(calCfets)

// 国债模板与平价曲线（取测试 setup 的子集）
createStdBondTemplate("CNY_TREAS_ZERO_1M", "ZERO_COUPON_BOND", "1M", currency, calCfets, asOfDate)
createStdBondTemplate("CNY_TREAS_CPN_A_6M", "FIXED_COUPON_BOND", "6M", currency, calCfets, asOfDate)
createStdBondTemplate("CNY_TREAS_CPN_A_1Y", "FIXED_COUPON_BOND", "1Y", currency, calCfets, asOfDate)
createStdBondTemplate("CNY_TREAS_CPN_A_3Y", "FIXED_COUPON_BOND", "3Y", currency, calCfets, asOfDate)
createStdBondTemplate("CNY_TREAS_CPN_A_5Y", "FIXED_COUPON_BOND", "5Y", currency, calCfets, asOfDate)

cnyTreasStdCfetsName = "cny_treas_std_cfets"
parCnyTreasStdCfets = caplib::createBondParCurve(
    asOfDate, currency,
    ["CNY_TREAS_ZERO_1M", "CNY_TREAS_CPN_A_6M", "CNY_TREAS_CPN_A_1Y",
     "CNY_TREAS_CPN_A_3Y", "CNY_TREAS_CPN_A_5Y"],
    [1.7112e-2, 1.9413e-2, 2.1563e-2, 2.5538e-2, 2.7550e-2],
    "YIELD_TO_MATURITY", cnyTreasStdCfetsName, true)
cnyTreasBuildSettings = caplib::createBondYieldCurveBuildSettings(
    cnyTreasStdCfetsName, "ZERO_RATE", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CNY_TREAS_STD_CFETS_BUILD_SETTINGS", true)
cnyTreasStdCfets = caplib::buildBondYieldCurve(
    asOfDate, cnyTreasBuildSettings[0], cnyTreasStdCfetsName, parCnyTreasStdCfets[0],
    "ACT_365_FIXED", "CONTINUOUS_COMPOUNDING", "ANNUAL",
    "BOOTSTRAPPING_METHOD", 0, "", "CNY_TREAS_STD_CFETS", true)

// 中票 AA+ 模板与平价曲线（取测试 setup 的子集）
createStdBondTemplate("CNY_MTN_AAA_CPN_A_1M", "FIXED_COUPON_BOND", "1M", currency, calCfets, asOfDate)
createStdBondTemplate("CNY_MTN_AAA_CPN_A_1Y", "FIXED_COUPON_BOND", "1Y", currency, calCfets, asOfDate)
createStdBondTemplate("CNY_MTN_AAA_CPN_A_3Y", "FIXED_COUPON_BOND", "3Y", currency, calCfets, asOfDate)
createStdBondTemplate("CNY_MTN_AAA_CPN_A_5Y", "FIXED_COUPON_BOND", "5Y", currency, calCfets, asOfDate)

cnyMtnAaaSprdStdCfetsName = "cny_mtn_aaa_sprd_std_cfets"
parCnyMtnAaaSprdStdCfets = caplib::createBondParCurve(
    asOfDate, currency,
    ["CNY_MTN_AAA_CPN_A_1M", "CNY_MTN_AAA_CPN_A_1Y",
     "CNY_MTN_AAA_CPN_A_3Y", "CNY_MTN_AAA_CPN_A_5Y"],
    [0.022916, 0.027216, 0.031112, 0.033816],
    "YIELD_TO_MATURITY", cnyMtnAaaSprdStdCfetsName, true)

cnyMtnAaaSprdStdCfets = caplib::buildBondCreditSpreadCurve(
    asOfDate, cnyMtnAaaSprdStdCfetsName, parCnyMtnAaaSprdStdCfets[0],
    cnyTreasStdCfets[0], "", "BOOTSTRAPPING_METHOD", 0,
    "CNY_MTN_AAA_SPRD_STD_CFETS", true)
```

#### createCreditParCurve

语法

```dolphindb
caplib::createCreditParCurve(asOfDate, currency, curveName, instrumentNames, instrumentTypes, maturities, quotes, startConventions, handle[, returnJson])
```

详情

创建并缓存信用平价曲线输入。函数验证并转换字段，构造 `CreditParCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

instrumentNames STRING 向量 类型。市场工具名称数组。**有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

instrumentTypes STRING 向量 类型。市场工具类型数组。**有效性:** 每个元素必须是以下完整 protobuf 标签之一：`DEPOSIT`, `FORWARD_RATE_AGREEMENT`, `IR_VANILLA_SWAP`, `OVERNIGHT_INDEX_SWAP`, `CROSS_CURRENCY_SWAP`, `MTM_CROSS_CURRENCY_SWAP`, `STD_CROSS_CURRENCY_SWAP`, `IR_BOND`, `NON_DELIVERABLE_SWAP`, `IR_EUROPEAN_SWAPTION`, `IR_CAP_FLOOR`, `IR_FUTURE`, `IR_FUTURE_IMM`, `IR_FUTURE_ASX`, `IR_VANILLA_BOND`, `IMM_FORWARD_RATE_AGREEMENT`, `IR_BOND_OPTION`, `IR_RANGEACCRUAL_SWAP`, `IR_STRUCTURED_SWAP`, `FX_SPOT`, `FX_FORWARD`, `FX_NON_DELIVERABLE_FORWARD`, `FX_SWAP`, `FX_SWAP_ON`, `FX_SWAP_TN`, `FX_EUROPEAN_OPTION`, `FX_TIME_OPTION`, `FX_DIGITAL_OPTION`, `FX_QUANTO_OPTION`, `FX_TOUCH_OPTION`, `FX_BARRIER_OPTION`, `FX_VANILLA_STRATEGY`, `FX_TOUCH_QUANTO_OPTION`, `FX_DIGITAL_QUANTO_OPTION`, `EQ_INDEX_FUTURE`, `EQ_EUROPEAN_OPTION`, `EQ_AMERICAN_OPTION`, `EQ_SPOT`, `EQ_VANILLA_OPTION`, `EQ_DIGITAL_OPTION`, `EQ_BARRIER_OPTION`, `EQ_RANGE_ACCRUAL_OPTION`, `EQ_TOUCH_OPTION`, `EQ_QUANTO_OPTION`, `CM_SPOT`, `CM_FUTURE`, `CM_EUROPEAN_OPTION`, `CM_AMERICAN_OPTION`, `CM_VANILLA_OPTION`, `CM_ASIAN_OPTION`, `CM_DIGITAL_OPTION`, `CM_SWAP`, `CM_DIGITAL_ASIAN_OPTION`, `PM_SPOT`, `PM_SWAP`, `CREDIT_DEFAULT_SWAP`, `SPOT`, `FUTURE`, `FORWARD`, `SWAP`, `EUROPEAN_OPTION`, `AMERICAN_OPTION`。

maturities STRING 向量 类型。工具到期期限数组。**有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。

quotes DOUBLE 向量 类型。市场报价值数组。**有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。

startConventions STRING 向量 类型。工具起息日约定数组。**有效性:** 每个元素必须是以下完整 protobuf 标签之一：`INVALID_INSTRUMENT_START_CONVENTION`, `SPOTSTART`, `TODAYSTART`, `TOMORROWSTART`。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CreditParCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
currency = "CNY"
caplib::createCreditParCurve(
    asOfDate, currency, "BOND_CREDIT",
    ["CFETS-SHCH-GTJA", "CFETS-SHCH-GTJA", "CFETS-SHCH-GTJA"],
    ["CREDIT_DEFAULT_SWAP", "CREDIT_DEFAULT_SWAP", "CREDIT_DEFAULT_SWAP"],
    ["1Y", "3Y", "5Y"],
    [0.0080, 0.0100, 0.0120],
    ["SPOTSTART", "SPOTSTART", "SPOTSTART"],
    "CR_CREDIT_PAR_CURVE", true)
```

#### buildCreditCurve

语法

```dolphindb
caplib::buildCreditCurve(asOfDate, parCurveHandle, discountCurveHandle, curveName, method, handle[, returnJson])
```

详情

构建信用曲线。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `CreditCurve`。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

parCurveHandle STRING 类型。平价曲线输入对象 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

discountCurveHandle STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

curveName STRING 类型。曲线业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

method STRING 类型。计算、校准或有限差分方法选择器。**有效性:** 必须为非空 STRING；值会原样传给信用曲线服务，插件未定义本地枚举。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CreditCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2020.02.21
currency = "CNY"
caplib::createCalendar("CAL_CFETS")

caplib::createCdsTemplate(
    "CFETS-SHCH-GTJA", "1d", "CASH_SETTLEMENT", 0.0, 1.0,
    "PAY_PROTECTION_AT_MATURITY", 0.4, "PAY_PREMIUM_UPTO_CURRENT_PERIOD",
    "ACTUAL_360", "QUARTERLY", "MODIFIED_FOLLOWING", ["CAL_CFETS"], false, true)

discountCurve = caplib::createIrYieldCurve(
    asOfDate,
    [2020.03.22, 2020.05.21, 2020.08.22, 2021.02.21, 2022.02.21,
     2023.02.21, 2024.02.21, 2025.02.21, 2027.02.21, 2030.02.21],
    [0.0166, 0.0183, 0.0198, 0.0212, 0.0234,
     0.0256, 0.0268, 0.0280, 0.0294, 0.0305],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CN_TREAS", "CR_DISCOUNT_CURVE", false)

creditParCurve = caplib::createCreditParCurve(
    asOfDate, currency, "BOND_CREDIT",
    ["CFETS-SHCH-GTJA", "CFETS-SHCH-GTJA", "CFETS-SHCH-GTJA"],
    ["CREDIT_DEFAULT_SWAP", "CREDIT_DEFAULT_SWAP", "CREDIT_DEFAULT_SWAP"],
    ["1Y", "3Y", "5Y"],
    [0.0080, 0.0100, 0.0120],
    ["SPOTSTART", "SPOTSTART", "SPOTSTART"],
    "CR_CREDIT_PAR_CURVE", true)

caplib::buildCreditCurve(
    asOfDate, creditParCurve[0], discountCurve, "BOND_CREDIT",
    "BOOTSTRAPPING_METHOD", "CR_CREDIT_CURVE", true)
```

#### priceCreditDefaultSwap

语法

```dolphindb
caplib::priceCreditDefaultSwap(instrumentHandle, asOfDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode[, returnJson])
```

详情

定价信用违约互换。函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

参数

instrumentHandle STRING 类型。被定价工具的 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

asOfDate DATE 类型。定价请求使用的估值日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

mktDataHandle STRING 类型。定价使用的市场数据集 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

pricingSettingsHandle STRING 类型。定价设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

riskSettingsHandle STRING 类型。风险设置 ObjectCache 句柄。**有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。

scnSettingsHandle STRING 类型。情景分析设置 ObjectCache 句柄；未使用时传空字符串。**有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。

mode STRING 类型。远程执行模式或服务端点；传空字符串使用默认模式。**有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingResults 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// 数值同 test/cr/test_priceCreditDefaultSwap.dos 的 setup
asOfDate = 2020.02.21
currency = "CNY"
caplib::createCalendar("CAL_CFETS")

cdsTpl = caplib::createCdsTemplate(
    "CFETS-SHCH-GTJA", "1d", "CASH_SETTLEMENT", 0.0, 1.0,
    "PAY_PROTECTION_AT_MATURITY", 0.4, "PAY_PREMIUM_UPTO_CURRENT_PERIOD",
    "ACTUAL_360", "QUARTERLY", "MODIFIED_FOLLOWING", ["CAL_CFETS"], false, true)

discountCurve = caplib::createIrYieldCurve(
    asOfDate,
    [2020.03.22, 2020.05.21, 2020.08.22, 2021.02.21, 2022.02.21,
     2023.02.21, 2024.02.21, 2025.02.21, 2027.02.21, 2030.02.21],
    [0.0166, 0.0183, 0.0198, 0.0212, 0.0234,
     0.0256, 0.0268, 0.0280, 0.0294, 0.0305],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CN_TREAS", "CR_DISCOUNT_CURVE", false)

pricingSettings = caplib::createCdsPricingSettings(
    currency, 0, 1, 0, "TAYLOR", "HALFDAYBIAS", "PIECEWISE",
    "CR_PRICING_NAME", "CR_PRICING", true)

irRisk = caplib::createIrCurveRiskSettings(
    1, 0, 0, 1.0e-4, 5.0e-1, 0, 1, 1.0e-4, 0, "CR_IR_RISK", false)
creditRisk = caplib::createCreditCurveRiskSettings(
    1, 0, 1.0e-4, 0, 1, 1.0e-4, 0, "CR_CREDIT_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(1, 1, 1.0 / 365.0, "CR_THETA_RISK", false)
crRisk = caplib::createCrRiskSettings(
    irRisk, creditRisk, thetaRisk, "CR_RISK_NAME", "CR_RISK", true)

creditParCurve = caplib::createCreditParCurve(
    asOfDate, currency, "BOND_CREDIT",
    ["CFETS-SHCH-GTJA", "CFETS-SHCH-GTJA", "CFETS-SHCH-GTJA"],
    ["CREDIT_DEFAULT_SWAP", "CREDIT_DEFAULT_SWAP", "CREDIT_DEFAULT_SWAP"],
    ["1Y", "3Y", "5Y"],
    [0.0080, 0.0100, 0.0120],
    ["SPOTSTART", "SPOTSTART", "SPOTSTART"],
    "CR_CREDIT_PAR_CURVE", true)

creditCurve = caplib::buildCreditCurve(
    asOfDate, creditParCurve[0], discountCurve, "BOND_CREDIT",
    "BOOTSTRAPPING_METHOD", "CR_CREDIT_CURVE", true)

mktData = caplib::createCrMktDataSet(
    asOfDate, discountCurve, creditCurve[0], "CR_MKT_NAME", "CR_MKT", true)

cds = caplib::buildCreditDefaultSwap(
    1000000.0, currency, 2019.06.20, 2024.06.20,
    "PAY", "CASH", 1.0, 1.0, "SENIOR", 0.4,
    0.01, "FLAT_SPREAD", "ACT_360", "QUARTERLY",
    "MODIFIED_FOLLOWING", "CAL_CFETS", 0.01, 0,
    "CR_CDS_NAME", "CR_CDS", false)

cdsPricingResult = caplib::priceCreditDefaultSwap(
    cds, asOfDate, mktData[0], pricingSettings[0], crRisk[0], "", "", true)
```

#### createCdsTemplate

语法

```dolphindb
caplib::createCdsTemplate(instName, startDelay, settlementType, referencePrice, leverage, creditProtectionType, recoveryRate, creditPremiumType, dayCountConvention, frequency, businessDayConvention, calendars, rebateAccrual BOOL or[, returnJson])
```

详情

创建并缓存信用违约互换模板。函数验证并转换字段，构造 `CreditInstrumentTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

参数

instName STRING 类型。工具或模板名称，通常也作为缓存句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

startDelay STRING 或 INT 类型。起息或交割延迟天数。**有效性:** INT 输入按天计，无需单位；STRING 输入为带可选正负号的整数和可选单位 `Y/M/W/D`（或完整英文单位），省略单位时按天计，负号会被保留。

settlementType STRING 类型。结算类型。**有效性:** 可接受值：`PHYSICAL`, `PHYSICAL_SETTLEMENT`, `CASH`, `CASH_SETTLEMENT`, `CASH_ZERO_COUPON_SETTLEMENT`。不区分大小写。空字符串或 NAN 回退为 PHYSICAL_SETTLEMENT；其他未知值报错。

referencePrice DOUBLE 类型。收益结构使用的参考价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

leverage DOUBLE 类型。保护腿或收益结构杠杆。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

creditProtectionType STRING 类型。信用保护类型。**有效性:** 可接受值：`PAY_PROTECTION_AT_DEFAULT`, `PAY_PROTECTION_AT_MATURITY`。不区分大小写。空字符串或 NAN 回退为 PAY_PROTECTION_AT_DEFAULT；其他未知值报错。

recoveryRate DOUBLE 类型。回收率。**有效性:** 必须有限且业务有效范围为 `[0,1]`；包装器仅检查类型。

creditPremiumType STRING 类型。信用产品溢价支付类型。**有效性:** 可接受值：`PAY_PREMIUM_AT_DEFAULT`, `PAY_PREMIUM_UPTO_CURRENT_PERIOD`, `PAY_PREMIUM_UPTO_MATURITY`, `PAY_NOTHING_AFTER_DEFAULT`。不区分大小写。空字符串或 NAN 回退为 PAY_PREMIUM_AT_DEFAULT；其他未知值报错。

dayCountConvention STRING 类型。计息惯例。**有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。任何其他字符串均回退到函数指定的默认日计数。

frequency STRING 类型。频率。**有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。任何其他字符串均回退到函数指定的默认频率。

businessDayConvention STRING 类型。营业日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

calendars STRING 或 STRING 向量 类型。日期调整使用的业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

rebateAccrual BOOL 或 INT 类型。是否返还应计利息。**有效性:** 接受 BOOL 或 INT；0 为 false，非零为 true。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CreditInstrumentTemplate 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

caplib::createCdsTemplate(
    "CFETS-SHCH-GTJA", 0, "CASH", 1.0,
    1.0, "SENIOR", 0.4, "FLAT_SPREAD",
    "ACT_360", "QUARTERLY", "MODIFIED_FOLLOWING", "CAL_CFETS", 0, false)
```

#### buildCreditDefaultSwap

语法

```dolphindb
caplib::buildCreditDefaultSwap(nominal, currency, issueDate, maturity, protectionLegPayReceive, protectionLegSettlementType, protectionLegReferencePrice, protectionLegLeverage, creditProtectionType, protectionLegRecoveryRate, couponRate, creditPremiumType, dayCountConvention, frequency, businessDayConvention, calendars, upfrontRate, rebateAccrual, name, handle[, returnJson])
```

详情

构建信用违约互换工具。函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `CreditDefaultSwap`。

参数

nominal DOUBLE 类型。工具名义金额。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

currency STRING 类型。币种代码。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

issueDate DATE 类型。发行日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

maturity DATE 类型。到期期限或到期日。**有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。

protectionLegPayReceive STRING 类型。保护腿支付或收取方向。**有效性:** 仅接受精确值 `PAY` 或 `RECEIVE`。

protectionLegSettlementType STRING 类型。保护腿结算类型。**有效性:** 仅接受精确值 `PHYSICAL` 或 `CASH`。

protectionLegReferencePrice DOUBLE 类型。保护腿参考价格。**有效性:** 必须严格为正且有限；包装器通常仅检查类型。

protectionLegLeverage DOUBLE 类型。保护腿杠杆。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

creditProtectionType STRING 类型。信用保护类型。**有效性:** 精确值 `PAY_PROTECTION_AT_MATURITY` 选择到期赔付；任何其他 STRING（包括空值或未知值）均回退为 PAY_PROTECTION_AT_DEFAULT。

protectionLegRecoveryRate DOUBLE 类型。保护腿回收率。**有效性:** 必须有限且业务有效范围为 `[0,1]`；包装器仅检查类型。

couponRate DOUBLE 类型。票息率。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

creditPremiumType STRING 类型。信用产品溢价支付类型。**有效性:** 精确值 `PAY_PREMIUM_UPTO_CURRENT_PERIOD` 选择当前期间；`PAY_PREMIUM_UPTO_MATURITY` 及任何其他 STRING 均选择到期。

dayCountConvention STRING 类型。计息惯例。**有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。任何其他字符串均回退到函数指定的默认日计数。

frequency STRING 类型。频率。**有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。任何其他字符串均回退到函数指定的默认频率。

businessDayConvention STRING 类型。营业日调整约定。**有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。任何其他字符串均回退到函数指定的默认营业日约定。

calendars STRING 类型。日期调整使用的业务日历名称。**有效性:** 每个名称必须是已注册的非空日历标识。

upfrontRate DOUBLE 类型。前端费用率。**有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。

rebateAccrual INT 类型。是否返还应计利息。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CreditDefaultSwap 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
caplib::buildCreditDefaultSwap(
    1000000.0, currency, 2019.06.20, 2024.06.20,
    "PAY", "CASH", 1.0, 1.0, "SENIOR", 0.4,
    0.01, "FLAT_SPREAD", "ACT_360", "QUARTERLY",
    "MODIFIED_FOLLOWING", "CAL_CFETS", 0.01, 0,
    "CR_CDS_NAME", "CR_CDS", false)
```

#### createCdsPricingSettings

语法

```dolphindb
caplib::createCdsPricingSettings(pricingCurrency, includeCurrentFlow, cashFlows, includeSettlementFlow, numericalFix, accrualBias, fwdsInCpnPeriod, name, handle[, returnJson])
```

详情

创建并缓存 CDS 定价设置。函数验证并转换字段，构造 `PricingSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

pricingCurrency STRING 类型。定价输出使用的币种。**有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不校验币种代码是否为有效 ISO 代码。

includeCurrentFlow INT 类型。估值输出中是否包含当前现金流。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

cashFlows INT 类型。定价结果中是否包含详细现金流输出。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

includeSettlementFlow INT 类型。估值输出中是否包含结算现金流。**有效性:** 必须是 INT 标量；0 为 false，非零为 true；传 BOOL 值会被插件拒绝。

numericalFix STRING 类型。数值稳定性修正方法。**有效性:** 值必须是以下完整 protobuf 标签之一：`NONE_FIX`, `TAYLOR`。

accrualBias STRING 类型。应计利息偏差处理方式。**有效性:** 值必须是以下完整 protobuf 标签之一：`HALFDAYBIAS`, `NOBIAS`。

fwdsInCpnPeriod STRING 类型。控制票息期间内远期利率处理方式的约定。**有效性:** 值必须是以下完整 protobuf 标签之一：`FLAT`, `PIECEWISE`。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 PricingSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


currency = "CNY"
caplib::createCdsPricingSettings(
    currency, 0, 1, 0, "TAYLOR", "HALFDAYBIAS", "PIECEWISE",
    "CR_PRICING_NAME", "CR_PRICING", true)
```

#### createCrMktDataSet

语法

```dolphindb
caplib::createCrMktDataSet(asOfDate, discountCurve, creditCurve, name, handle[, returnJson])
```

详情

创建并缓存信用市场数据集。函数验证并转换字段，构造 `CrMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。市场数据基准日或估值参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

discountCurve STRING 类型。贴现曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

creditCurve STRING 类型。信用曲线 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CrMktDataSet 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2020.02.21
currency = "CNY"
caplib::createCalendar("CAL_CFETS")

caplib::createCdsTemplate(
    "CFETS-SHCH-GTJA", "1d", "CASH_SETTLEMENT", 0.0, 1.0,
    "PAY_PROTECTION_AT_MATURITY", 0.4, "PAY_PREMIUM_UPTO_CURRENT_PERIOD",
    "ACTUAL_360", "QUARTERLY", "MODIFIED_FOLLOWING", ["CAL_CFETS"], false, true)

discountCurve = caplib::createIrYieldCurve(
    asOfDate,
    [2020.03.22, 2020.05.21, 2020.08.22, 2021.02.21, 2022.02.21,
     2023.02.21, 2024.02.21, 2025.02.21, 2027.02.21, 2030.02.21],
    [0.0166, 0.0183, 0.0198, 0.0212, 0.0234,
     0.0256, 0.0268, 0.0280, 0.0294, 0.0305],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CN_TREAS", "CR_DISCOUNT_CURVE", false)

creditParCurve = caplib::createCreditParCurve(
    asOfDate, currency, "BOND_CREDIT",
    ["CFETS-SHCH-GTJA", "CFETS-SHCH-GTJA", "CFETS-SHCH-GTJA"],
    ["CREDIT_DEFAULT_SWAP", "CREDIT_DEFAULT_SWAP", "CREDIT_DEFAULT_SWAP"],
    ["1Y", "3Y", "5Y"],
    [0.0080, 0.0100, 0.0120],
    ["SPOTSTART", "SPOTSTART", "SPOTSTART"],
    "CR_CREDIT_PAR_CURVE", true)
creditCurve = caplib::buildCreditCurve(
    asOfDate, creditParCurve[0], discountCurve, "BOND_CREDIT",
    "BOOTSTRAPPING_METHOD", "CR_CREDIT_CURVE", true)

caplib::createCrMktDataSet(
    asOfDate, discountCurve, creditCurve, "CR_MKT_NAME", "CR_MKT", true)
```

#### createCrRiskSettings

语法

```dolphindb
caplib::createCrRiskSettings(irCurveSettings, csCurveSettings, thetaSettings, name, handle[, returnJson])
```

详情

创建并缓存信用风险设置。函数验证并转换字段，构造 `CrRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

参数

irCurveSettings STRING 类型。利率曲线风险设置 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

csCurveSettings STRING 类型。信用利差曲线风险设置 ObjectCache 句柄。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

thetaSettings STRING 类型。设置对象的缓存句柄或配置值。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

name STRING 类型。写入创建对象的业务名称。**有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。

handle STRING 类型。用于后续获取创建对象的 ObjectCache 键或标签。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 应为 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CrRiskSettings 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")

// 数值同 test/cr/test_createCrRiskSettings.dos 的 setup
irRisk = caplib::createIrCurveRiskSettings(
    1, 0, 0, 1.0e-4, 5.0e-1, 0, 1, 1.0e-4, 0, "CR_IR_RISK", false)
creditRisk = caplib::createCreditCurveRiskSettings(
    1, 0, 1.0e-4, 0, 1, 1.0e-4, 0, "CR_CREDIT_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(1, 1, 1.0 / 365.0, "CR_THETA_RISK", false)
caplib::createCrRiskSettings(
    irRisk, creditRisk, thetaRisk, "CR_RISK_NAME", "CR_RISK", true)
```

#### createFlatCreditCurve

语法

```dolphindb
caplib::createFlatCreditCurve(asOfDate, hazardRate, handle[, returnJson])
```

详情

在生成期限结构的两端应用同一风险率/利差值，创建平坦 CreditCurve。函数验证并转换字段，构造 `CreditCurve` protobuf 并存入 ObjectCache，供后续分析使用。

参数

asOfDate DATE 类型。曲线、曲面或构建请求的参考日期。**有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。

hazardRate DOUBLE 类型。平坦 CreditCurve 的常量风险率/利差。**有效性:** 业务有效值须有限且非负；包装器仅检查 DOUBLE 类型。

handle STRING 类型。分配给创建对象并由函数返回的 ObjectCache 键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型。可选。省略或为 false 时仅返回 ObjectCache 句柄；为 true 时返回 [handle, protobufJson]。**有效性:** 必须是 BOOL 标量，仅可为 false 或 true。

返回值

创建的 CreditCurve 对象对应的 ObjectCache 句柄，STRING 类型标量；`returnJson=true` 时返回 `[handle, protobufJson]`。

**示例**

```dolphindb
loadPlugin("caplib")


asOfDate = 2020.02.21
caplib::createFlatCreditCurve(asOfDate, 0.002, "AN_FLAT_CREDIT_CURVE", false)
```

#### getSurvivalProbability

语法

```dolphindb
caplib::getSurvivalProbability(creditCurveHandle, dates)
```

详情

根据缓存 CreditCurve 为每个输入日期计算存活概率；输出保持输入顺序。

参数

creditCurveHandle STRING 类型。所引用具体类的 ObjectCache 句柄。**有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。

dates DATE 向量 类型。请求曲线值的日期；结果第 i 个元素对应 dates[i]。**有效性:** 必须是无空值 DATE 向量。单日使用单元素向量，多日使用更长向量；不接受 DATE 标量。

返回值

对应向量，DOUBLE 类型向量，元素顺序与输入一致。

**示例**

```dolphindb
loadPlugin("caplib")

// 平坦信用曲线：SP(t) = exp(-h*t)，h = 0.002
asOfDate = 2020.02.21
flatCreditCurve = caplib::createFlatCreditCurve(asOfDate, 0.002, "FLAT_CREDIT_CURVE", false)
caplib::getSurvivalProbability(flatCreditCurve, [2020.02.21, 2021.02.20])
```

#### getCreditSpread

语法

```dolphindb
caplib::getCreditSpread(creditCurveHandle, dates)
```

详情

根据缓存 CreditCurve 为每个输入日期计算信用利差；输出保持输入顺序。

参数

creditCurveHandle STRING 类型。所引用具体类的 ObjectCache 句柄。**有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。

dates DATE 向量 类型。请求曲线值的日期；结果第 i 个元素对应 dates[i]。**有效性:** 必须是无空值 DATE 向量。单日使用单元素向量，多日使用更长向量；不接受 DATE 标量。

返回值

对应向量，DOUBLE 类型向量，元素顺序与输入一致。

**示例**

```dolphindb
loadPlugin("caplib")

// 平坦信用曲线的信用利差恒等于风险率 0.002
asOfDate = 2020.02.21
flatCreditCurve = caplib::createFlatCreditCurve(asOfDate, 0.002, "FLAT_CREDIT_CURVE", false)
caplib::getCreditSpread(flatCreditCurve, [2020.05.21, 2021.02.20])
```


### 市场风险

市场风险（MarketRisk）服务：历史模拟情景生成器与 VaR / 期望损失（ES）度量。

#### buildHistSimFxSpotRate

语法

```dolphindb
caplib::buildHistSimFxSpotRate(simDate, referenceSpot, histStart, histEnd, useTemplate, fxSpotTemplate, handle[, returnJson])
```

详情

基于历史模拟生成 FX 即期汇率情景，可选应用 FX 即期模板。

参数

simDate DATE 类型。模拟基准日。**有效性:** 必须是非空 DolphinDB DATE 标量。

referenceSpot STRING 类型。参考 FxSpotRate 句柄。**有效性:** 必须是已存在的 FxSpotRate 对象的非空 ObjectCache 键。

histStart STRING 类型。历史起始 FxSpotRate 句柄。**有效性:** 必须是已存在的 FxSpotRate 对象的非空 ObjectCache 键。

histEnd STRING 类型。历史结束 FxSpotRate 句柄。**有效性:** 必须是已存在的 FxSpotRate 对象的非空 ObjectCache 键。

useTemplate BOOL 类型。是否应用 FX 即期模板；为 true 时 fxSpotTemplate 必填。**有效性:** 必须是 BOOL 标量。为 true 时 *fxSpotTemplate* 须为有效的 FxSpotTemplate 句柄；为 false 时须传空字符串。

fxSpotTemplate STRING 类型。FxSpotTemplate 句柄；useTemplate 为 false 时传空字符串。**有效性:** *useTemplate* 为 true 时必须是已存在的 FxSpotTemplate 对象的非空 ObjectCache 键；否则传空字符串。

handle STRING 类型。结果 FxSpotRate 的缓存键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型，可选。默认为 false。**有效性:** 必须是 BOOL 标量。

返回值

结果 FxSpotRate 句柄，STRING 类型标量。对象存入 ObjectCache。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2020.02.21
refSpot   = caplib::createFxSpotRate(7.00, "USD", "CNY", asOfDate, asOfDate, "MR_SPOT_REF", false)
startSpot = caplib::createFxSpotRate(6.99, "USD", "CNY", asOfDate, asOfDate, "MR_SPOT_START", false)
endSpot   = caplib::createFxSpotRate(7.01, "USD", "CNY", asOfDate, asOfDate, "MR_SPOT_END", false)

sim = caplib::buildHistSimFxSpotRate(asOfDate, refSpot, startSpot, endSpot,
    false, "", "MR_SPOT_SIM", false)
```

#### buildHistSimFxVolSurface

语法

```dolphindb
caplib::buildHistSimFxVolSurface(simDate, referenceVolSurf, histStart, histEnd, volSurfaceDates, volSurfaceStrikes, spot, domCurve, forCurve, settings, handle[, returnJson])
```

详情

基于历史模拟生成一个 FX 波动率曲面情景，需参考/历史曲面、目标日期与行权价网格、即期汇率及本币/外币贴现曲线。

参数

simDate DATE 类型。模拟基准日。**有效性:** 必须是非空 DolphinDB DATE 标量。

referenceVolSurf STRING 类型。参考 FxVolatilitySurface 句柄。**有效性:** 必须是已存在的 FxVolatilitySurface 对象的非空 ObjectCache 键。

histStart STRING 类型。历史起始 FxVolatilitySurface 句柄。**有效性:** 必须是已存在的 FxVolatilitySurface 对象的非空 ObjectCache 键。

histEnd STRING 类型。历史结束 FxVolatilitySurface 句柄。**有效性:** 必须是已存在的 FxVolatilitySurface 对象的非空 ObjectCache 键。

volSurfaceDates DATE 向量类型。目标曲面日期，至少两个。**有效性:** 必须是无空值的 DATE 向量，且至少两个日期；长度须与 `volSurfaceStrikes` 的行权价集个数一致。

volSurfaceStrikes 任意向量类型。每个目标日期一行权价集（DOUBLE 向量的向量），形状须与日期数匹配。**有效性:** 必须是无空值的 DOUBLE 向量的向量；长度须与 `volSurfaceDates` 的日期个数一致。

spot STRING 类型。FxSpotRate 句柄。**有效性:** 必须是已存在的 FxSpotRate 对象的非空 ObjectCache 键。

domCurve STRING 类型。本币 IrYieldCurve 句柄。**有效性:** 必须是已存在的 IrYieldCurve 对象的非空 ObjectCache 键。

forCurve STRING 类型。外币 IrYieldCurve 句柄。**有效性:** 必须是已存在的 IrYieldCurve 对象的非空 ObjectCache 键。

settings STRING 类型。VolatilitySurfaceBuildSettings 句柄，可传空字符串。**有效性:** 必须是已存在的 VolatilitySurfaceBuildSettings 对象的 ObjectCache 键，或空字符串。

handle STRING 类型。结果 FxVolatilitySurface 的缓存键。**有效性:** 必须是非空 ObjectCache 键。

returnJson BOOL 类型，可选。默认为 false。**有效性:** 必须是 BOOL 标量。

返回值

结果 FxVolatilitySurface 句柄，STRING 类型标量。服务端支持时对象存入 ObjectCache。

**示例**

```dolphindb
loadPlugin("caplib")

asOfDate = 2021.03.30
surfDef = caplib::createVolatilitySurfaceDefinition("STRIKE_VOL_SMILE", "LINEAR_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY", "ACT_365_FIXED",
    "LOG_NORMAL_VOL_TYPE", "ABSOLUTE_STRIKE", 1.0e-4, 1.0e4, "MR_DEF", false)
conv = caplib::createFxMktConventions("EURUSD", "ATM_DNS_PIPS", "PIPS_SPOT_DELTA",
    "PIPS_FORWARD_DELTA", "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "MR_CONV", false)

terms = [2021.06.30, 2021.09.30]
strikes = matrix([1.00, 1.00], [1.1761, 1.1761], [1.35, 1.35])
refSurf = caplib::createFxVolatilitySurface(asOfDate, "EUR", "USD", terms, strikes,
    matrix([0.06, 0.06], [0.06, 0.06], [0.06, 0.06]), surfDef[0], conv[0], "MR_SURF_REF", false)

spot = caplib::createFxSpotRate(1.1761, "EUR", "USD", asOfDate, asOfDate, "MR_SURF_SPOT", false)
dom  = caplib::createFlatIrYieldCurve(asOfDate, "EUR", 0.020, "MR_SURF_DOM", false)
for_ = caplib::createFlatIrYieldCurve(asOfDate, "USD", 0.010, "MR_SURF_FOR", false)

// 注意：服务端 HIST_SIM_FX_VOL_SURFACE 生成器（11006）对部分输入返回空错误
sim = caplib::buildHistSimFxVolSurface(asOfDate, refSurf, refSurf, refSurf,
    terms, [[1.00, 1.1761, 1.35], [1.00, 1.1761, 1.35]], spot, dom, for_, "", "MR_SURF_SIM", false)
```

#### calcVaR

语法

```dolphindb
caplib::calcVaR(profitLossSamples, probability, antithetic)
```

详情

计算盈亏样本的 VaR 风险价值。

参数

profitLossSamples DOUBLE 向量类型。盈亏样本序列，不能为空。**有效性:** 必须是无空值且非空的 DOUBLE 向量。

probability DOUBLE 类型。置信水平，严格在 (0, 1) 内。**有效性:** 必须是严格在 (0, 1) 内的 DOUBLE 标量。

antithetic BOOL 类型。是否同时计算对偶样本的镜像 VaR。**有效性:** 必须是 BOOL 标量。

返回值

字典，包含两个键：`value_at_risk`（VaR 值）与 `value_at_risk_mirrored`（对偶样本镜像 VaR），值均为 DOUBLE 类型标量。

**示例**

```dolphindb
loadPlugin("caplib")

samples = [-100.0, -50.0, 0.0, 50.0, 100.0]
v = caplib::calcVaR(samples, 0.95, false)
print(v.value_at_risk)          // VaR 值
print(v.value_at_risk_mirrored) // 镜像 VaR
```

#### calcExpectedShortfall

语法

```dolphindb
caplib::calcExpectedShortfall(profitLossSamples, probability, antithetic)
```

详情

计算盈亏样本的期望损失，参数同 `calcVaR`。

参数

profitLossSamples DOUBLE 向量类型。盈亏样本序列，不能为空。**有效性:** 必须是无空值且非空的 DOUBLE 向量。

probability DOUBLE 类型。置信水平，严格在 (0, 1) 内。**有效性:** 必须是严格在 (0, 1) 内的 DOUBLE 标量。

antithetic BOOL 类型。是否同时计算对偶样本的镜像期望损失。**有效性:** 必须是 BOOL 标量。

返回值

字典，包含两个键：`expected_shortfall`（期望损失值）与 `expected_shortfall_mirrored`（对偶样本镜像期望损失），值均为 DOUBLE 类型标量。

**示例**

```dolphindb
loadPlugin("caplib")

samples = [-100.0, -50.0, 0.0, 50.0, 100.0]
e = caplib::calcExpectedShortfall(samples, 0.95, false)
print(e.expected_shortfall)          // 期望损失值
print(e.expected_shortfall_mirrored) // 镜像期望损失
```

## 使用示例

以下示例展示固定收益债券定价的完整流程：加载插件、创建曲线和债券、配置定价与风险设置、组装市场数据、执行定价并输出结果。

```dolphindb
// =============================================================================
// DolphinDB caplib Plugin Example: FI Analytics
// =============================================================================
// Shows the main fixed-income curve and bond pricing flow; matches example/FiAnalytics.dos.

loadPlugin("caplib")

asOfDate = 2021.07.22
currency = "CNY"

// Create the discount curve used for bond pricing.
discountCurve = caplib::createIrYieldCurve(
    asOfDate,
    [2021.08.22, 2022.07.22, 2023.07.22, 2024.07.22],
    [0.02, 0.022, 0.024, 0.026],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", currency, "CNY_TREAS", "FI_IR_CURVE", false)

// Create the credit spread curve used for FI analytics.
spreadCurve = caplib::createCreditCurve(
    asOfDate,
    [2021.08.22, 2022.07.22, 2023.07.22, 2024.07.22],
    [0.0010, 0.0012, 0.0014, 0.0016],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CNY_MTN_AAA", "FI_CREDIT_CURVE", false)

// Create the bond template used to build a vanilla bond.
bondTemplate = caplib::createVanillaBondTemplate(
    "CNY_TREAS_CPN_BOND", "FIXED_COUPON_BOND",
    2020.07.22, 1, 2020.07.22, "5Y",
    0.03, currency, 100.0,
    "ACT_365_FIXED", calCfets, "ANNUAL",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "",
    "", "INVALID_FREQUENCY", "INVALID_BUSINESS_DAY_CONVENTION",
    "INVALID_DATE_GENERATION_MODE", -1,
    "0d", "", "INVALID_BUSINESS_DAY_CONVENTION", false,
    "CONST_NOTIONAL", 0.0, false)

// Build the vanilla bond instrument from its template.
vanillaBond = caplib::buildVanillaBond(
    1000000.0, bondTemplate, "", 2020.07.22, "FI_VANILLA_BOND", false)

// Create pricing settings for bond valuation.
pricingModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", "", 0, [0.0], "FI_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 1, 1, take(0, 0), pricingModel, "", "", "FI_PRICING", false)

// Create FI risk settings from IR, credit, and theta components.
irRisk = caplib::createIrCurveRiskSettings(
    1, 1, 1, 1.0e-4, 5.0e-3, 0, 1, 1.0e-4, 0, "FI_IR_RISK", false)
creditRisk = caplib::createCreditCurveRiskSettings(
    1, 1, 1.0e-4, 0, 1, 1.0e-4, 0, "FI_CREDIT_RISK", false)
thetaRisk = caplib::createThetaRiskSettings(1, 1, 1.0 / 365.0, "FI_THETA_RISK", false)
fiRisk = caplib::createFiRiskSettings(
    irRisk, creditRisk, thetaRisk, "FI_RISK_NAME", "FI_RISK", true)

// Assemble the FI market data set from curves.
fiMktData = caplib::createFiMktDataSet(
    asOfDate, discountCurve, spreadCurve, "", "", "", "FI_MKT_NAME", "FI_MKT", true)

// Price the vanilla bond and print the handle plus JSON payload.
vanillaBondPricingResult = caplib::priceVanillaBond(
    vanillaBond, asOfDate, fiMktData[0], pricingSettings, fiRisk[0], "", "", true)
print(vanillaBondPricingResult)
```


## 错误行为

所有接口失败时统一按下方规则抛出 DolphinDB 异常，不返回备用标量或部分对象；异常消息统一以 `[PLUGIN::CAPLIB]` 前缀标明来源。

| 错误类别 | 触发条件 | 异常类型 |
| --- | --- | --- |
| 参数验证 | 参数类型、个数、形状、空值、值域或跨参数约束不满足（含非法枚举、越界取值） | `IllegalArgumentException` |
| 句柄错误 | 句柄不存在，或其 protobuf 类型与接口要求不符 | `IllegalArgumentException` |
| 服务失败 | 底层 CAPLIB 服务返回 `success=false`，其 `err_msg` 写入异常消息 | `RuntimeException` |
| 解析 / 序列化 | protobuf 解析或序列化失败 | `RuntimeException` |

仅包装器执行的操作不提供状态标量；所有错误都表现为异常。


## 附录

### Docker 部署

Docker 镜像构建、目录布局、启动、健康检查和故障排查见 [Docker 部署说明](https://github.com/CapRiskTech/caplib-plugin-dolphindb/blob/main/docker/README.md)。

```bash
bash docker/build.sh --test
```

### 编译说明

源码编译所需的 DolphinDB Plugin SDK、ABI0 版本 `dqlibc`、Boost、log4cplus、Protobuf、CMake 和 GCC 版本及命令随源码仓提供。

### License 说明

本插件为**开源 + 免费**（`openSource/isFree/isFreeForCommercial` 均 `true`）。Caplib 本体开源；其底层计算库 `dqlibc` 为 CapRiskTech 专有软件，随发行包附带不绑定特定机器的通用 `dqlibc.lic`（签名 + 有效期校验，非机器绑定）以启用计算。企业批量/定制许可另行通过 [https://www.caprisktech.com/](https://www.caprisktech.com) 联系申请。插件在服务调用前校验该许可证，并缓存校验结果 3600 秒。

也可在 DolphinDB 中调用 `caplib::pluginInfo()` 核对插件与许可元数据（含 `isFree`、`pluginVersion`、`feature`）。

### 常见问题

| 现象 | 原因 | 处理方式 |
| --- | --- | --- |
| `Invalid plugin file` | 使用了包含 CMake 变量的源模板，或描述文件版本与 Server 不匹配 | 使用发行包内（或源码构建产物 `build/` 下）的 `PluginCaplib.txt`，并确保版本一致 |
| `GLIBCXX_* not found` | C++ 运行库版本不兼容 | 使用匹配的 ABI0 运行环境；参考 Docker 部署说明 |
| `LICENSE_FILE_NOT_FOUND` | `dqlibc.lic` 不在搜索路径 | 将许可证放到规定位置 |
| 句柄类型错误 | ObjectCache 对象的 protobuf 类型与参数要求不匹配 | 检查句柄来源及参数表中的类型要求 |
| 接口抛出异常 | 参数校验或底层服务失败 | 查看异常消息；插件不会返回部分结果 |

### 缩写与术语

| 缩写 | 全称 | 中文 |
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
