# DolphinDB Caplib 插件使用说明

Caplib 是面向金融衍生品定价与风险分析的 DolphinDB 插件。插件通过 CapRiskTech 提供的底层计算库 `dqlibc`，覆盖固定收益、利率、外汇、权益、商品和信用等资产类别，提供曲线构建、市场数据组装、金融工具创建、定价、风险分析与情景分析能力。

## 功能说明

| 资产类别 | 主要能力 |
| --- | --- |
| 固定收益（Fixed Income，FI） | 债券定价、收益率计算、Z-spread、转换因子、隐含回购利率、收益率曲线构建 |
| 利率（Interest Rate，IR） | 单币种与跨币种曲线、互换、Cap/Floor、Swaption、IBOR 和基差计算 |
| 外汇（Foreign Exchange，FX） | 即期、远期、掉期、NDF、外汇期权和波动率曲面 |
| 权益（Equity，EQ） | 股息曲线、波动率曲面及欧式、美式、亚式、障碍、雪球等期权定价 |
| 商品（Commodity，CM） | 商品与贵金属曲线、市场数据、波动率曲面和期权定价 |
| 信用（Credit，CR） | 信用曲线、信用违约互换（CDS）定价和信用风险设置 |
| 市场风险 | 历史模拟、风险价值（VaR）、预期损失（ES）、敏感度转换与情景分析 |

## 第三方库说明

本插件依赖 CapRiskTech 提供的专有 `dqlibc` 库。`dqlibc` 负责底层金融计算、protobuf 数据处理和许可证校验；Caplib 插件负责 DolphinDB 数据类型转换、ObjectCache 内存对象管理和接口注册。

使用前必须准备有效的 `dqlibc.lic`。许可证文件格式要求 `lic_ver = 200`，并应放在 `~/.dqlib/dqlibc.lic`、`/etc/dqlib/dqlibc.lic` 或 `libdqlibc.so` 所在目录。

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

加载生成后的插件描述文件：

```dolphindb
loadPlugin("/your/path/to/caplib/PluginCaplib.txt")
```

> 请使用本仓库发行包内已配置的 `PluginCaplib.txt`；不要部署源码仓库中的 CMake 模板。

## 核心概念

插件对外函数统一使用 lowerCamelCase，例如 `caplib::calcYearFraction`。`PluginCaplib.txt` 第一列保留 PascalCase C++ 实现符号，第二列记录 lowerCamelCase 外部名称。


### 工厂函数与内存对象

`create*` 和 `build*` 工厂函数创建曲线、报价、模板、设置、市场数据或金融工具，并将对象写入 ObjectCache。函数返回 STRING 句柄，后续构建与定价接口通过句柄引用对象。

### 句柄和 `returnJson`

大多数工厂与定价接口支持最后一个可选参数 `returnJson`：

- 省略或传入 `false`：只返回对象句柄。
- 传入 `true`：返回 `[handle, protobufJson]`。

### 定价接口的统一参数

| 位置 | 参数 | 类型 | 含义 |
| ---: | --- | --- | --- |
| 1 | `instrumentHandle` | STRING | 金融工具句柄 |
| 2 | `pricingDate` | DATE | 定价日 |
| 3 | `mktDataHandle` | STRING | 市场数据句柄 |
| 4 | `pricingSettingsHandle` | STRING | 定价设置句柄 |
| 5 | `riskSettingsHandle` | STRING | 风险设置句柄 |
| 6 | `scnSettingsHandle` | STRING | 情景设置句柄；不使用时传空字符串 |
| 7 | `mode` | STRING | 定价模式；使用默认模式时传空字符串 |
| 8 | `returnJson` | BOOL，可选 | 是否同时返回 JSON，默认 `false` |

### 必填参数与可选参数

接口语法中的方括号表示可选参数，例如 `[, returnJson BOOL]`。未放在方括号中的参数均为必填参数。参数表同时给出数据类型、形状、可选值、默认行为和有效性约束。

### 日期术语

- `asOfDate`、`referenceDate`：曲线、报价或市场数据的基准日。
- `pricingDate`：执行估值的日期。
- `calculationDate`：独立计算器接口使用的计算日期。

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

##### 语法

```dolphindb
caplib::calcYearFraction(startDate DATE, endDate DATE, dayCountConvention STRING)
```

##### 详情

通过 CAPLIB 日期服务应用所选日计数约定，计算 startDate 到 endDate 的应计年化比例。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `startDate` | DATE | 起始日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `endDate` | DATE | 结束日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `dayCountConvention` | STRING | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::calcYearFraction(2025.01.01, 2025.12.31, `ACTUAL_360)
```

#### createCalendar

##### 语法

```dolphindb
caplib::createCalendar(calName STRING[, holidays DATE[]|INT[][, specialBusinessDays DATE[]|INT[]]])
```

##### 详情

根据名称、假日和特殊工作日构造 Calendar，将其序列化为 CalendarList 静态数据并注册到 CAPLIB。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calName` | STRING | 日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `holidays` | DATE[] or INT[] | 节假日日期数组。 **有效性:** 可省略；显式提供时必须是非空且不含空值的 DATE/INT 向量。与特殊工作日向量的长度互相独立；包装器不检查排序或日期先后关系。 |
| `specialBusinessDays` | DATE[] or INT[] | 特殊工作日日期数组。 **有效性:** 可省略或为空向量；非空时必须是不含空值的 DATE/INT 向量。包装器不检查排序或日期先后关系。 |

##### 返回值

**返回：** BOOL `true`；失败时抛出异常，不返回 `false`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createCalendar(calEuta)
```

#### createStaticData

##### 语法

```dolphindb
caplib::createStaticData(staticDataType STRING, staticDataBytes STRING)
```

##### 详情

验证 StaticDataType，将输入 protobuf 序列化字节发送到 CAPLIB，并注册对应的具体静态数据对象。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `staticDataType` | STRING | 静态数据类型标签。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_STATIC_DATA_TYPE`, `SDT_CALENDAR`, `SDT_IBOR_INDEX`, `SDT_IR_YIELD_CURVE`, `SDT_FX_MKT_CONVENTIONS`, `SDT_FX_SPOT`, `SDT_FX_SWAP`, `SDT_FX_FORWARD`, `SDT_FX_NDF`, `SDT_IR_VANILLA_INSTRUMENT`, `SDT_IR_FUTURE`, `SDT_FX_TIME_OPTION`, `SDT_VANILLA_BOND`, `SDT_CREDIT_INSTRUMENT`, `SDT_PM_CASH`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 比较不区分大小写；空字符串和 `NAN` 映射为无效哨兵。 |
| `staticDataBytes` | STRING | 静态数据 protobuf 字节。 **有效性:** 必须是非空二进制 STRING，并能解析为说明中的精确 protobuf 类型。 |

##### 返回值

**返回：** BOOL `true`；失败时抛出异常，不返回 `false`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createStaticData(staticDataType, staticDataBytes)
```

#### getObjectCacheJson

##### 语法

```dolphindb
caplib::getObjectCacheJson(protobufType STRING, handle STRING)
```

##### 详情

按具体 protobuf 类和句柄从 ObjectCache 获取对象，序列化为 protobuf JSON，并一起返回句柄与 JSON 文本。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `protobufType` | STRING | protobuf 类型标签。 **有效性:** 可接受值：`IrYieldCurve`, `AssetYieldCurve`, `Curve`, `CreditCurve`, `DividendCurve`, `VolatilityCurve`, `VolatilitySmile`, `VolatilitySurface`, `OptionQuoteMatrix`, `VolatilitySurfaceDefinition`, `VolatilitySurfaceBuildSettings`, `PricingModelSettings`, `PdeSettings`, `MonteCarloSettings`, `PricingSettings`, `IrCurveRiskSettings`, `CreditCurveRiskSettings`, `DividendCurveRiskSettings`, `PriceRiskSettings`, `VolRiskSettings`, `PriceVolRiskSettings`, `ThetaRiskSettings`, `ScnSettings`, `ScnAnalysisSettings`, `EqMktDataSet`, `EqRiskSettings`, `PricingResults`, `FxSpotRate`, `EuropeanOption`, `AmericanOption`, `DigitalOption`, `AsianOption`, `OneTouchOption`, `DoubleTouchOption`, `SingleBarrierOption`, `DoubleBarrierOption`, `CollarOption`, `SingleSharkFinOption`, `DoubleSharkFinOption`, `RangeAccrualOption`, `AirbagOption`, `PingPongOption`, `PhoenixAutoCallableNote`, `SnowballAutoCallableNote`, `dqproto.IrYieldCurve`。区分大小写。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |

##### 返回值

**返回：** 两元素 STRING 向量 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::getObjectCacheJson("PricingResults", "EO_INST_results")
```

#### createDividendCurve

##### 语法

```dolphindb
caplib::createDividendCurve(referenceDate DATE, pillarDates DATE[], pillarValues DOUBLE[], yieldStartDate DATE, dividendType STRING, dcc STRING, interp STRING, extrap STRING, compounding STRING, name STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存股息或远期收益曲线。 函数验证并转换字段，构造 `DividendCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `pillarDates` | DATE[] | 曲线节点日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `pillarValues` | DOUBLE[] | 曲线节点值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `yieldStartDate` | DATE | 日期或日期数组。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |
| `dividendType` | STRING | 股息曲线类型。 **有效性:** 可接受值：`CONTINUOUS`, `DISCRETE`。区分大小写。 |
| `dcc` | STRING | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 |
| `interp` | STRING | 插值方法。 **有效性:** 可接受值：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。仅接受所示精确拼写。 |
| `extrap` | STRING | 外推方法。 **有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。 |
| `compounding` | STRING | 复利约定。 **有效性:** 可接受值：`CONTINUOUS_COMPOUNDING`, `DISCRETE_COMPOUNDING`, `SIMPLE_COMPOUNDING`。仅接受所示精确拼写。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `DividendCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createDividendCurve(
    asOfDate,
    [2020.02.26, 2020.03.25, 2020.06.24, 2020.09.23],
    [0.05361055758784821, 0.01338941242891319, -0.001765240983827533, -0.002594662370949712],
    asOfDate,
    "CONTINUOUS", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "DIVIDEND_CURVE_50ETF", "EQ_DIV_CURVE", false)
```

#### createVolatilityCurve

##### 语法

```dolphindb
caplib::createVolatilityCurve(referenceDate DATE, pillarDates DATE[], vols DOUBLE[], dcc STRING, interp STRING, extrap STRING, underlying STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存一维波动率曲线。 函数验证并转换字段，构造 `VolatilityCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `pillarDates` | DATE[] | 曲线节点日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `vols` | DOUBLE[] | 波动率节点值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须非负且有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `dcc` | STRING | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 |
| `interp` | STRING | 插值方法。 **有效性:** 可接受值：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。仅接受所示精确拼写。 |
| `extrap` | STRING | 外推方法。 **有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolatilityCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createVolatilityCurve(
    asOfDate, quantoDates, quantoValues,
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    underlying, "QUANTO_FX_VOL", false)
```

#### createVolatilitySurface

##### 语法

```dolphindb
caplib::createVolatilitySurface(definitionHandle STRING, referenceDate DATE, volSmileHandles STRING[], termDates DATE[], underlying STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存波动率曲面。 函数验证并转换字段，构造 `VolatilitySurface` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `definitionHandle` | STRING | 波动率曲面定义 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `volSmileHandles` | STRING[] | 波动率微笑对象 内存对象 句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `termDates` | DATE[] | 报价期限对应的到期日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolatilitySurface` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createVolatilitySurface(
    volSurfaceDefinition[0], asOfDate, [volSmile1d, volSmile3y], curveDates,
    "AN_UNDERLYING", "AN_VOL_SURFACE", false)
```

#### createOptionQuoteMatrix

##### 语法

```dolphindb
caplib::createOptionQuoteMatrix(quoteValueType STRING, quoteTermType STRING, quoteStrikeType STRING, exerciseType STRING, optionUnderlyingType STRING, asOfDate DATE, terms STRING[], termDates DATE[], payoffTypes STRING matrix/vector, values DOUBLE matrix/vector, strikes DOUBLE matrix/vector, assetName STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存通用期权报价矩阵。 函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `quoteValueType` | STRING | 报价值类型，例如价格或波动率。 **有效性:** 值必须是以下完整 protobuf 标签之一：`OQVT_INVALID`, `OQVT_VOLATILITY`, `OQVT_PRICE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `quoteTermType` | STRING | 报价期限类型。 **有效性:** 可接受值：`OQTT_INVALID`, `OQTT_ABOSULTE_TERM`, `OQTT_ABSOLUTE_TERM`, `OQTT_RELATIVE_TERM`。不区分大小写。 |
| `quoteStrikeType` | STRING | 报价行权价类型。 **有效性:** 可接受值：`OQST_INVALID`, `OQST_ABOSULTE_STRIKE`, `OQST_ABSOLUTE_STRIKE`, `OQST_RELATIVE_STRIKE`, `OQST_DELTA_STRIKE`。不区分大小写。 |
| `exerciseType` | STRING | 期权行权风格。 **有效性:** 值必须是以下完整 protobuf 标签之一：`EUROPEAN`, `AMERICAN`, `BERMUDAN`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `optionUnderlyingType` | STRING | 期权标的类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`SPOT_UNDERLYING_TYPE`, `FUTURE_UNDERLYING_TYPE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `terms` | STRING[] | 报价期限数组。 **有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `termDates` | DATE[] | 报价期限对应的到期日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `payoffTypes` | STRING matrix/vector | 与报价值对齐的收益类型矩阵或向量。 **有效性:** 每个元素必须是以下完整 protobuf 标签之一：`CALL`, `PUT`, `STRADDLE`, `STRANGLE`, `RISK_REVERSAL`, `BUTTERFLY`, `ATM_STRADDLE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `values` | DOUBLE matrix/vector | 报价值矩阵或向量。 **有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `strikes` | DOUBLE matrix/vector | 行权价数组或矩阵。 **有效性:** 必须有限；价格型标的通常要求非负，利率型标的可为负。包装器仅检查类型/形状。 |
| `assetName` | STRING | 资产或标的名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `OptionQuoteMatrix` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createOptionQuoteMatrix(
    "OQVT_PRICE", "OQTT_ABOSULTE_TERM", "OQST_ABOSULTE_STRIKE",
    "EUROPEAN", "SPOT_UNDERLYING_TYPE", asOfDate,
    [], quoteTermDates, quotePayoffTypes, quoteValues, quoteStrikes,
    "AN_UNDERLYING", "AN_OPTION_QUOTES", true)
```

#### createVolatilitySurfaceDefinition

##### 语法

```dolphindb
caplib::createVolatilitySurfaceDefinition(volSmileType STRING, smileMethod STRING, smileExtrapMethod STRING, timeInterpMethod STRING, timeExtrapMethod STRING, dayCountConvention STRING, volType STRING, wingStrikeType STRING, lower DOUBLE, upper DOUBLE, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存波动率曲面定义。 函数验证并转换字段，构造 `VolatilitySurfaceDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `volSmileType` | STRING | 波动率微笑类型。 **有效性:** 可接受值：`STRIKE`, `STRIKE_VOL_SMILE`, `DELTA`, `DELTA_VOL_SMILE`, `LOG_STRIKE`, `LOG_STRIKE_VOL_SMILE`。仅接受所示精确拼写。 |
| `smileMethod` | STRING | 微笑构建或插值方法。 **有效性:** 可接受值：`SVI`, `SVI_SMILE_METHOD`, `SABR`, `SABR_SMILE_METHOD`, `LINEAR`, `LINEAR_SMILE_METHOD`, `CUBIC_SPLINE`, `CUBIC_SPLINE_SMILE_METHOD`。仅接受所示精确拼写。 |
| `smileExtrapMethod` | STRING | 微笑外推方法。 **有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。 |
| `timeInterpMethod` | STRING | 期限方向插值方法。 **有效性:** 可接受值：`LINEAR_IN_VARIANCE`, `LINEAR_IN_VOLATILITY`, `LINEAR_IN_PARAM`。不区分大小写。 |
| `timeExtrapMethod` | STRING | 期限方向外推方法。 **有效性:** 可接受值：`FLAT_IN_VOLATILITY`。不区分大小写。 |
| `dayCountConvention` | STRING | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 |
| `volType` | STRING | 波动率类型。 **有效性:** 识别值：`INVALID_VOLATILITY_TYPE`, `LOG_NORMAL_VOL_TYPE`, `NORMAL_VOL_TYPE`, `LOG_NORMAL`, `NORMAL`。不区分大小写。 |
| `wingStrikeType` | STRING | 翼部行权价类型。 **有效性:** 识别值：`DELTA`, `RELATIVE_RATIO_STRIKE`, `RELATIVE_SPREAD_STRIKE`, `ABOSULTE_STRIKE`, `ABSOLUTE_STRIKE`。不区分大小写。 |
| `lower` | DOUBLE | 下界参数。 **有效性:** 必须有限且严格小于 `upper`；包装器不检查此关系。 |
| `upper` | DOUBLE | 上界参数。 **有效性:** 必须有限且严格大于 `lower`；包装器不检查此关系。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolatilitySurfaceDefinition` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createVolatilitySurfaceDefinition(
    "STRIKE_VOL_SMILE", "SVI_SMILE_METHOD",
    "FLAT_EXTRAP", "LINEAR_IN_VARIANCE", "FLAT_IN_VOLATILITY",
    "ACT_365_FIXED", "LOG_NORMAL_VOL_TYPE", "DELTA",
    -1.0e-5, 1.0e-5, "EQ_VOL_DEF", true)
```

#### createVolSurfBuildSettings

##### 语法

```dolphindb
caplib::createVolSurfBuildSettings(fixedParamIndex INT, fixedParamValue DOUBLE, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存波动率曲面构建设置。 函数验证并转换字段，构造 `VolatilitySurfaceBuildSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `fixedParamIndex` | INT | 需要固定的模型参数索引。 **有效性:** 必须非负且小于对应数组长度；包装器仅检查 INT 类型。 |
| `fixedParamValue` | DOUBLE | 固定模型参数取值。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolatilitySurfaceBuildSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createVolSurfBuildSettings(1, 0.5, "EQ_VOL_BUILD", true)
```

#### createPricingModelSettings

##### 语法

```dolphindb
caplib::createPricingModelSettings(modelName STRING, asset STRING, calibrated BOOL, constantParams DOUBLE[], handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存定价模型设置。 函数验证并转换字段，构造 `PricingModelSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `modelName` | STRING | 定价模型名称。 **有效性:** 可接受值：`BLACK_SCHOLES_MERTON`, `BLACK_MODEL`, `BACHELIER_MODEL`, `HESTON_STOCH_VOL_MODEL`, `SKEW_MODEL`。仅接受所示精确拼写。 |
| `asset` | STRING | 资产收益或资产返还金额。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `calibrated` | BOOL | 模型参数是否已校准。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `constantParams` | DOUBLE[] | 模型常数参数数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingModelSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", "", 0, modelParams, "EQ_BSM_MODEL", false)
```

#### createPdeSettings

##### 语法

```dolphindb
caplib::createPdeSettings(tSize INT, xSize INT, xMin DOUBLE, xMax DOUBLE, xMinMaxType INT, ySize INT, yMin DOUBLE, yMax DOUBLE, yMinMaxType INT, zSize INT, zMin DOUBLE, zMax DOUBLE, zMinMaxType INT, xDensity DOUBLE, yDensity DOUBLE, zDensity DOUBLE, xGridType INT, yGridType INT, zGridType INT, xInterp INT, yInterp INT, zInterp INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存 PDE 网格设置。 函数验证并转换字段，构造 `PdeSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `tSize` | INT | 时间维网格点数量。 **有效性:** 必须严格为正；包装器通常仅检查类型。 |
| `xSize` | INT | X 维网格点数量。 **有效性:** 必须严格为正；包装器通常仅检查类型。 |
| `xMin` | DOUBLE | X 维网格下界。 **有效性:** 必须有限且严格小于 `xMax`；包装器不检查此关系。 |
| `xMax` | DOUBLE | X 维网格上界。 **有效性:** 必须有限且严格大于 `xMin`；包装器不检查此关系。 |
| `xMinMaxType` | INT | X 维边界解释方式。 **有效性:** 可接受的整数代码：`0=PdeSettings_MinMaxType_MMT_NUM_STDEVS`, `1=PdeSettings_MinMaxType_MMT_ABOSLUTE`. |
| `ySize` | INT | Y 维网格点数量。 **有效性:** 必须严格为正；包装器通常仅检查类型。 |
| `yMin` | DOUBLE | Y 维网格下界。 **有效性:** 必须有限且严格小于 `yMax`；包装器不检查此关系。 |
| `yMax` | DOUBLE | Y 维网格上界。 **有效性:** 必须有限且严格大于 `yMin`；包装器不检查此关系。 |
| `yMinMaxType` | INT | Y 维边界解释方式。 **有效性:** 可接受的整数代码：`0=PdeSettings_MinMaxType_MMT_NUM_STDEVS`, `1=PdeSettings_MinMaxType_MMT_ABOSLUTE`. |
| `zSize` | INT | Z 维网格点数量。 **有效性:** 必须严格为正；包装器通常仅检查类型。 |
| `zMin` | DOUBLE | Z 维网格下界。 **有效性:** 必须有限且严格小于 `zMax`；包装器不检查此关系。 |
| `zMax` | DOUBLE | Z 维网格上界。 **有效性:** 必须有限且严格大于 `zMin`；包装器不检查此关系。 |
| `zMinMaxType` | INT | Z 维边界解释方式。 **有效性:** 可接受的整数代码：`0=PdeSettings_MinMaxType_MMT_NUM_STDEVS`, `1=PdeSettings_MinMaxType_MMT_ABOSLUTE`. |
| `xDensity` | DOUBLE | X 维网格密度参数。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `yDensity` | DOUBLE | Y 维网格密度参数。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `zDensity` | DOUBLE | Z 维网格密度参数。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `xGridType` | INT | X 维网格类型。 **有效性:** 可接受的整数代码：`0=INVALID_GRID_TYPE`, `1=UNIFORM_GRID`, `2=ADAPTIVE_GRID`. |
| `yGridType` | INT | Y 维网格类型。 **有效性:** 可接受的整数代码：`0=INVALID_GRID_TYPE`, `1=UNIFORM_GRID`, `2=ADAPTIVE_GRID`. |
| `zGridType` | INT | Z 维网格类型。 **有效性:** 可接受的整数代码：`0=INVALID_GRID_TYPE`, `1=UNIFORM_GRID`, `2=ADAPTIVE_GRID`. |
| `xInterp` | INT | X 维插值方法。 **有效性:** 可接受的整数代码：`0=INVALID_INTERP_METHOD`, `1=LINEAR_INTERP`, `2=CUBIC_SPLINE_INTERP`, `3=LEFT_CONTINUOUS_FLAT_INTERP`, `4=SABR_INTERP`, `5=SVI_INTERP`, `6=LOG_MONEYNESS_CUBIC_SPLINE_INTERP`, `7=SABR_NORMAL_INTERP`, `8=QUADRATIC_POLYNOMIAL_INTERP`, `9=CUBIC_POLYNOMIAL_INTERP`, `10=CUBIC_HERMITE_SPLINE_INTERP`. |
| `yInterp` | INT | Y 维插值方法。 **有效性:** 可接受的整数代码：`0=INVALID_INTERP_METHOD`, `1=LINEAR_INTERP`, `2=CUBIC_SPLINE_INTERP`, `3=LEFT_CONTINUOUS_FLAT_INTERP`, `4=SABR_INTERP`, `5=SVI_INTERP`, `6=LOG_MONEYNESS_CUBIC_SPLINE_INTERP`, `7=SABR_NORMAL_INTERP`, `8=QUADRATIC_POLYNOMIAL_INTERP`, `9=CUBIC_POLYNOMIAL_INTERP`, `10=CUBIC_HERMITE_SPLINE_INTERP`. |
| `zInterp` | INT | Z 维插值方法。 **有效性:** 可接受的整数代码：`0=INVALID_INTERP_METHOD`, `1=LINEAR_INTERP`, `2=CUBIC_SPLINE_INTERP`, `3=LEFT_CONTINUOUS_FLAT_INTERP`, `4=SABR_INTERP`, `5=SVI_INTERP`, `6=LOG_MONEYNESS_CUBIC_SPLINE_INTERP`, `7=SABR_NORMAL_INTERP`, `8=QUADRATIC_POLYNOMIAL_INTERP`, `9=CUBIC_POLYNOMIAL_INTERP`, `10=CUBIC_HERMITE_SPLINE_INTERP`. |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PdeSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createPdeSettings(201, 401, -5.0, 5.0, 0, 0, 0.0, 0.0, 0,
    0, 0.0, 0.0, 0, 0.001, 0.001, 0.001, 2, 0, 0, 3, 0, 0, "CM_PDE_SETTINGS", false)
```

#### createMonteCarloSettings

##### 语法

```dolphindb
caplib::createMonteCarloSettings(numSimulations INT, uniformNumberType INT, seed INT, wienerBuildMethod INT, gaussianMethod INT, useAntithetic BOOL, numSteps INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存蒙特卡洛模拟设置。 函数验证并转换字段，构造 `MonteCarloSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `numSimulations` | INT | 蒙特卡洛模拟路径数量。 **有效性:** 包装器要求非空 INT 标量且严格为正。 |
| `uniformNumberType` | INT | 均匀随机数生成器类型。 **有效性:** 可接受的整数代码：`0=SOBOL_NUMBER`, `1=MERSENNE_TWIST_19937_NUMBER`. |
| `seed` | INT | 随机数种子。 **有效性:** 应为非负整数；包装器接受任意 INT。 |
| `wienerBuildMethod` | INT | 维纳过程构建方法。 **有效性:** 可接受的整数代码：`0=INVALID_WIENER_PROCESS_BUILD_METHOD`, `1=BROWNIAN_BRIDGE_METHOD`, `2=INCREMENTAL_METHOD`. |
| `gaussianMethod` | INT | 高斯随机数生成方法。 **有效性:** 可接受的整数代码：`0=INVALID_GAUSSIAN_NUMBER_METHOD`, `1=INVERSE_CUMULATIVE_METHOD`, `2=BOX_MULLER_METHOD`, `3=CENTRAL_LIMIT_METHOD`. |
| `useAntithetic` | BOOL | 是否使用反向变量。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `numSteps` | INT | 蒙特卡洛时间步数。 **有效性:** 必须严格为正；包装器通常仅检查类型。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `MonteCarloSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createMonteCarloSettings(8096, 1, 1023, 1, 1, 0, 1, "CM_MC_SETTINGS", false)
```

#### createPricingSettings

##### 语法

```dolphindb
caplib::createPricingSettings(currency STRING, pricingMethod STRING, incCurrent BOOL, cashFlows BOOL, modelHandle STRING, pdeHandle STRING, mcHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存定价设置。 函数验证并转换字段，构造 `PricingSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `pricingMethod` | STRING | 定价方法。 **有效性:** 可接受值：`ANALYTICAL`, `ANALYTICAL_SMILE_ON`, `PDE`, `MONTE_CARLO`, `BINOMIAL_TREE`, `MOMENT_MATCHING`。仅接受所示精确拼写。 |
| `incCurrent` | BOOL | 估值输出中是否包含当前现金流。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `cashFlows` | BOOL | 定价结果中是否包含详细现金流输出。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `modelHandle` | STRING | 定价模型设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pdeHandle` | STRING | PDE 设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mcHandle` | STRING | 蒙特卡洛设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createPricingSettings(
    currency, "ANALYTICAL", 0, 0, bsmModel, "", "", "EQ_BSM_ANALYTICAL", false)
```

#### createDividendCurveRiskSettings

##### 语法

```dolphindb
caplib::createDividendCurveRiskSettings(delta BOOL, gamma BOOL, shift DOUBLE, method INT, granularity INT, scaling DOUBLE, threading INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存股息曲线风险设置。 函数验证并转换字段，构造 `DividendCurveRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `delta` | BOOL | 是否计算 Delta 风险或 Delta 数值。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `gamma` | BOOL | 是否计算 Gamma 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `shift` | DOUBLE | 风险或校准计算使用的扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `method` | INT | 计算、校准或有限差分方法选择器。 **有效性:** 映射：`value =2` 为 ONE_SIDE_UP。 |
| `granularity` | INT | 风险桶或扰动粒度。 **有效性:** 映射：`value =2` 为 TERM_STRIKE。 |
| `scaling` | DOUBLE | 风险扰动缩放因子。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `threading` | INT | 线程模式选择器。 **有效性:** 仅 `1` 选择多线程；其他整数均为单线程。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `DividendCurveRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createDividendCurveRiskSettings(1, 1, 1.0e-4,
    0, 0, 1.0e-4, 0, "DIV_RISK", false)
```

#### createPriceRiskSettings

##### 语法

```dolphindb
caplib::createPriceRiskSettings(delta BOOL, gamma BOOL, curvature BOOL, shift DOUBLE, curvatureShift DOUBLE, method INT, scaling DOUBLE, threading INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存标的价格风险设置。 函数验证并转换字段，构造 `PriceRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `delta` | BOOL | 是否计算 Delta 风险或 Delta 数值。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `gamma` | BOOL | 是否计算 Gamma 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `curvature` | BOOL | 是否计算曲率风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `shift` | DOUBLE | 风险或校准计算使用的扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `curvatureShift` | DOUBLE | 曲率风险使用的扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `method` | INT | 计算、校准或有限差分方法选择器。 **有效性:** 映射：`value =2` 为 ONE_SIDE_UP。 |
| `scaling` | DOUBLE | 风险扰动缩放因子。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `threading` | INT | 线程模式选择器。 **有效性:** 仅 `1` 选择多线程；其他整数均为单线程。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PriceRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createPriceRiskSettings(
    1, 1, 0, 1.0e-2, 5.0e-1, 0, 1.0e-2, 0, "FX_PRICE_RISK", false)
```

#### createVolRiskSettings

##### 语法

```dolphindb
caplib::createVolRiskSettings(vega BOOL, volga BOOL, shift DOUBLE, method INT, granularity INT, scaling DOUBLE, threading INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存波动率风险设置。 函数验证并转换字段，构造 `VolRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `vega` | BOOL | 是否计算 Vega 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `volga` | BOOL | 是否计算 Volga 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `shift` | DOUBLE | 风险或校准计算使用的扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `method` | INT | 计算、校准或有限差分方法选择器。 **有效性:** 映射：`value =2` 为 ONE_SIDE_UP。 |
| `granularity` | INT | 风险桶或扰动粒度。 **有效性:** 映射：`value =2` 为 TERM_STRIKE。 |
| `scaling` | DOUBLE | 风险扰动缩放因子。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `threading` | INT | 线程模式选择器。 **有效性:** 仅 `1` 选择多线程；其他整数均为单线程。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createVolRiskSettings(
    1, 1, 1.0e-2, 0, 0, 1.0e-2, 0, "FX_VOL_RISK", false)
```

#### createPriceVolRiskSettings

##### 语法

```dolphindb
caplib::createPriceVolRiskSettings(vanna BOOL, priceShift DOUBLE, volShift DOUBLE, method INT, granularity INT, priceScaling DOUBLE, volScaling DOUBLE, threading INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存价格-波动率交叉风险设置。 函数验证并转换字段，构造 `PriceVolRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `vanna` | BOOL | 是否计算 Vanna 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `priceShift` | DOUBLE | 价格风险扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `volShift` | DOUBLE | 波动率风险扰动大小。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `method` | INT | 计算、校准或有限差分方法选择器。 **有效性:** 映射：`value =2` 为 ONE_SIDE_UP。 |
| `granularity` | INT | 风险桶或扰动粒度。 **有效性:** 映射：`value =2` 为 TERM_STRIKE。 |
| `priceScaling` | DOUBLE | 价格风险缩放因子。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `volScaling` | DOUBLE | 波动率风险缩放因子。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `threading` | INT | 线程模式选择器。 **有效性:** 仅 `1` 选择多线程；其他整数均为单线程。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PriceVolRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createPriceVolRiskSettings(
    1, 1.0e-2, 1.0e-2, 0, 0, 1.0e-2, 1.0e-2, 0, "FX_PRICE_VOL_RISK", false)
```

#### createThetaRiskSettings

##### 语法

```dolphindb
caplib::createThetaRiskSettings(theta BOOL, shift INT, scaling DOUBLE, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存 Theta 风险设置。 函数验证并转换字段，构造 `ThetaRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `theta` | BOOL | 是否计算 Theta 风险。 **有效性:** 必须是非空 BOOL 标量；兼容旧示例的 INT `0/1`。字符串、空值及其他整数会抛错。 |
| `shift` | INT | 风险或校准计算使用的扰动大小。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `scaling` | DOUBLE | 风险扰动缩放因子。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `ThetaRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createThetaRiskSettings(1, 1, 1.0 / 365.0, "CR_THETA_RISK", false)
```

#### createScnSettings

##### 语法

```dolphindb
caplib::createScnSettings(min DOUBLE, max DOUBLE, size INT, scnGenType INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存一维情景设置。 函数验证并转换字段，构造 `ScnSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `min` | DOUBLE | 情景网格下界。 **有效性:** 必须为有限、非空 DOUBLE 标量，且不得大于 `max`。建议使用严格递增的区间；包装器保留两端相等的兼容行为。 |
| `max` | DOUBLE | 情景网格上界。 **有效性:** 必须为有限、非空 DOUBLE 标量，且不得小于 `min`。 |
| `size` | INT | 情景网格点数量。 **有效性:** 必须严格为正；包装器通常仅检查类型。 |
| `scnGenType` | INT | 情景生成类型。 **有效性:** 定义代码为 `0` 和 `1`；包装器字段为 int32，不拒绝其他整数。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `ScnSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createScnSettings(-0.20, 0.20, 11, 1, "FX_PRICE_SCN", false)
```

#### createScnAnalysisSettings

##### 语法

```dolphindb
caplib::createScnAnalysisSettings(scnType STRING, priceHandle STRING, volHandle STRING, threading INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存情景分析设置。 函数验证并转换字段，构造 `ScnAnalysisSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `scnType` | STRING | 情景分析类型。 **有效性:** 可接受值：`NONE`, `NO_SCN_ANALYSIS`, `PRICE`, `PRICE_SCN_ANALYSIS`, `VOL`, `VOL_SCN_ANALYSIS`, `PRICE_VOL`, `PRICE_VOL_SCN_ANALYSIS`, `THETA`, `THETA_SCN_ANALYSIS`。仅接受所示精确拼写。 |
| `priceHandle` | STRING | 价格情景设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `volHandle` | STRING | 波动率设置或曲面 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `threading` | INT | 线程模式选择器。 **有效性:** 仅 `1` 选择多线程；其他整数均为单线程。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `ScnAnalysisSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createScnAnalysisSettings(
    "PRICE_VOL_SCN_ANALYSIS", priceScn, volScn, 0, "FX_SCN_ANALYSIS", false)
```

#### createFlatDividendCurve

##### 语法

```dolphindb
caplib::createFlatDividendCurve(referenceDate DATE, dividend DOUBLE, curveName STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建一条连续复利的平坦股息收益率曲线，将同一股息率用于整个期限范围。 函数验证并转换字段，构造 `DividendCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `dividend` | DOUBLE | 操作使用的数值。 **有效性:** 必须有限；还须满足业务正值与跨参数约束。 |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `DividendCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFlatDividendCurve(
    asOfDate, 0.01, "AN_FLAT_DIVIDEND_CURVE", "AN_FLAT_DIVIDEND_CURVE", false)
```

#### createFlatVolCurve

##### 语法

```dolphindb
caplib::createFlatVolCurve(referenceDate DATE, volatility DOUBLE, underlying STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建一条平坦的一维波动率曲线，其 1 日和 100 年支柱使用相同波动率。 函数验证并转换字段，构造 `VolatilityCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `volatility` | DOUBLE | 操作使用的数值。 **有效性:** 必须有限；还须满足业务正值与跨参数约束。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolatilityCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFlatVolCurve(asOfDate, 0.20, "AN_UNDERLYING", "AN_FLAT_VOL_CURVE", false)
```

#### createVolatilitySmile

##### 语法

```dolphindb
caplib::createVolatilitySmile(volSmileType STRING, referenceDate DATE, strikes DOUBLE[], vols DOUBLE[], smileMethod STRING, extrapMethod STRING, term DOUBLE, modelParams DOUBLE[], auxiliaryParams DOUBLE[], lower DOUBLE, upper DOUBLE, handle STRING[, returnJson BOOL])
```

##### 详情

根据对齐的执行价与波动率创建波动率微笑，并设置微笑模型、外推方法、边界和校准参数。 函数验证并转换字段，构造 `VolatilitySmile` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `volSmileType` | STRING | 波动率微笑类型。 **有效性:** 可接受值：`STRIKE`, `STRIKE_VOL_SMILE`, `DELTA`, `DELTA_VOL_SMILE`, `LOG_STRIKE`, `LOG_STRIKE_VOL_SMILE`。仅接受所示精确拼写。 |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `strikes` | DOUBLE[] | 操作使用的数值向量。 **有效性:** 所有值须有限且形状与配对参数一致。 |
| `vols` | DOUBLE[] | 波动率节点值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须非负且有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `smileMethod` | STRING | 微笑构建或插值方法。 **有效性:** 可接受值：`SVI`, `SVI_SMILE_METHOD`, `SABR`, `SABR_SMILE_METHOD`, `LINEAR`, `LINEAR_SMILE_METHOD`, `CUBIC_SPLINE`, `CUBIC_SPLINE_SMILE_METHOD`。仅接受所示精确拼写。 |
| `extrapMethod` | STRING | 外推方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_EXTRAP_METHOD`, `FLAT_EXTRAP`, `LINEAR_EXTRAP`, `NATURAL_EXTRAP`, `ADJ_FLAT_EXTRAP`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `term` | DOUBLE | 赋给微笑的年化期限。 **有效性:** 业务有效值须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `modelParams` | DOUBLE[] | 操作使用的数值向量。 **有效性:** 所有值须有限且形状与配对参数一致。 |
| `auxiliaryParams` | DOUBLE[] | 操作使用的数值向量。 **有效性:** 所有值须有限且形状与配对参数一致。 |
| `lower` | DOUBLE | 下界参数。 **有效性:** 必须有限且严格小于 `upper`；包装器不检查此关系。 |
| `upper` | DOUBLE | 上界参数。 **有效性:** 必须有限且严格大于 `lower`；包装器不检查此关系。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolatilitySmile` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createVolatilitySmile(
    "STRIKE_VOL_SMILE", asOfDate, [90.0, 100.0, 110.0], [0.22, 0.20, 0.21],
    "LINEAR_SMILE_METHOD", "FLAT_EXTRAP", 1.0 / 365.0,
    emptyDoubles, emptyDoubles, 90.0, 110.0, "AN_VOL_SMILE_1D", false)
```

#### createFlatVolatilitySurface

##### 语法

```dolphindb
caplib::createFlatVolatilitySurface(referenceDate DATE, volatility DOUBLE, underlying STRING, handle STRING[, returnJson BOOL])
```

##### 详情

为指定标的创建平坦波动率曲面，在所有到期日和执行价上返回同一波动率。 函数验证并转换字段，构造 `VolatilitySurface` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `volatility` | DOUBLE | 操作使用的数值。 **有效性:** 必须有限；还须满足业务正值与跨参数约束。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolatilitySurface` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFlatVolatilitySurface(
    asOfDate, 0.20, "AN_UNDERLYING", "AN_FLAT_VOL_SURFACE", true)
```

#### createProxyOptionQuoteMatrix

##### 语法

```dolphindb
caplib::createProxyOptionQuoteMatrix(underlyingName STRING, refVolSurfaceHandle STRING, refUnderlyingPrice DOUBLE, underlyingPrice DOUBLE, handle STRING[, returnJson BOOL])
```

##### 详情

将缓存的参考波动率曲面从参考现货水平缩放到目标现货水平，为另一标的创建期权报价矩阵。 函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `underlyingName` | STRING | 操作使用的字符串。 **有效性:** 除非明确标为可选，否则必须非空。 |
| `refVolSurfaceHandle` | STRING | 所引用具体类的 ObjectCache 句柄。 **有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。 |
| `refUnderlyingPrice` | DOUBLE | 参考曲面对应的现货价格。 **有效性:** 有效缩放要求严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `underlyingPrice` | DOUBLE | 当前标的价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `OptionQuoteMatrix` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createProxyOptionQuoteMatrix(
    "AN_UNDERLYING", flatVolSurface[0], 100.0, 101.0, "AN_PROXY_OPTION_QUOTES", true)
```

#### createModelFreePricingSettings

##### 语法

```dolphindb
caplib::createModelFreePricingSettings(currency STRING, incCurrent INT, cashFlows INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建分析法定价设置，内置 Black-Scholes-Merton、PDE 网格和 Sobol 蒙特卡洛默认值，无需独立设置句柄。 函数验证并转换字段，构造 `PricingSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `incCurrent` | INT | 控制是否包含当日现金流的整数标志。 **有效性:** 必须是 INT：`0` 为 false，任意非零值为 true。 |
| `cashFlows` | INT | 控制详细现金流输出的整数标志。 **有效性:** 必须是 INT：`0` 为 false，任意非零值为 true。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createModelFreePricingSettings(
    "CNY", 1, 0, "AN_MODEL_FREE_PRICING_SETTINGS", false)
```

#### getVolatility

##### 语法

```dolphindb
caplib::getVolatility(volSurfaceHandle STRING, termDates DATE[], strikes DOUBLE[])
```

##### 详情

从缓存 VolatilitySurface 计算每个到期日与执行价组合的波动率，并保留服务矩阵。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `volSurfaceHandle` | STRING | FxVolatilitySurface 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `termDates` | DATE[] | 报价期限对应的到期日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `strikes` | DOUBLE[] | 操作使用的数值向量。 **有效性:** 所有值须有限且形状与配对参数一致。 |

##### 返回值

**返回：** DOUBLE 矩阵，对应到期日/执行价网格。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::getVolatility(flatVolSurface[0], curveDates, [95.0, 105.0])
```

#### impliedVolCalculator

##### 语法

```dolphindb
caplib::impliedVolCalculator(calculationDate DATE, underlyingPrice DOUBLE, discountCurveHandle STRING, assetCurveHandle STRING, pricingSettingsHandle STRING, optionPrice DOUBLE, payoffType STRING, exerciseType STRING, expiryDate DATE, strike DOUBLE)
```

##### 详情

在所选收益与行权方式下，使用缓存贴现曲线、资产收益曲线和 PricingSettings 求解复现 optionPrice 的波动率。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calculationDate` | DATE | 执行计算的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `underlyingPrice` | DOUBLE | 当前标的价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `assetCurveHandle` | STRING | 所引用具体类的 ObjectCache 句柄。 **有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `optionPrice` | DOUBLE | 操作使用的数值。 **有效性:** 必须有限；还须满足业务正值与跨参数约束。 |
| `payoffType` | STRING | 收益类型，例如 CALL 或 PUT。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `exerciseType` | STRING | 期权行权风格。 **有效性:** 值必须是以下完整 protobuf 标签之一：`EUROPEAN`, `AMERICAN`, `BERMUDAN`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `expiryDate` | DATE | 该计算使用的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `strike` | DOUBLE | 行权价。 **有效性:** 利率行权价必须有限；允许负值、零或正值。包装器仅检查类型/形状。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::impliedVolCalculator(
    asOfDate, 100.0, flatIrCurve, flatDividendCurve, pricingSettings,
    5.0, "CALL", "EUROPEAN", 2022.09.09, 100.0)
```

### 固定收益

#### buildBondYieldCurve

##### 语法

```dolphindb
caplib::buildBondYieldCurve(referenceDate DATE, buildSettingsHandle STRING, curveName STRING, parCurveHandle STRING, dayCount STRING, compoundingType STRING, frequency STRING, buildingMethod STRING, calcJacobian BOOL, forwardCurveHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建债券收益率曲线。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrYieldCurve`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `buildSettingsHandle` | STRING | 构建设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `parCurveHandle` | STRING | 平价曲线输入对象 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 任何其他字符串均回退到函数指定的默认日计数。 |
| `compoundingType` | STRING | 复利类型。 **有效性:** 识别值：`SIMPLE`, `SIMPLE_COMPOUNDING`, `COMPOUNDED`, `DISCRETE`, `DISCRETE_COMPOUNDING`, `CONTINUOUS`, `CONTINUOUS_COMPOUNDING`。不区分大小写。 空值或其他字符串回退为 CONTINUOUS_COMPOUNDING。 |
| `frequency` | STRING | 频率。 **有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 任何其他字符串均回退到函数指定的默认频率。 |
| `buildingMethod` | STRING | 曲线或曲面构建算法名称。 **有效性:** 识别值：`BOOTSTRAP`, `BOOTSTRAPPING`, `BOOTSTRAPPING_METHOD`, `GLOBAL_OPTIMIZATION`, `GLOBAL_OPTIMIZATION_METHOD`, `HYBRID`, `HYBRID_METHOD`。不区分大小写。 空值或其他字符串回退为 BOOTSTRAPPING_METHOD。 |
| `calcJacobian` | BOOL | 是否计算并返回校准雅可比信息。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `forwardCurveHandle` | STRING | 远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrYieldCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildBondYieldCurve(
    asOfDate, cnyTreasBuildSettings[0], cnyTreasStdCfetsName, parCnyTreasStdCfets[0],
    "ACT_365_FIXED", "CONTINUOUS_COMPOUNDING", "ANNUAL",
    "BOOTSTRAPPING_METHOD", 0, "", "CNY_TREAS_STD_CFETS", true)
```

#### calcConversionFactor

##### 语法

```dolphindb
caplib::calcConversionFactor(bondCouponRate DOUBLE, bondCpnFreq STRING, nominalCpnRate DOUBLE, bondMaturity DATE, settlementDate DATE, lastCpnDate DATE)
```

##### 详情

根据票息条款、到期日、结算日、上次付息日和频率计算债券期货转换因子。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `bondCouponRate` | DOUBLE | 债券票息率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `bondCpnFreq` | STRING | 债券票息频率。 **有效性:** 识别值：`ANNUAL`, `SEMIANNUAL`, `QUARTERLY`, `MONTHLY`。不区分大小写。 |
| `nominalCpnRate` | DOUBLE | 名义票息率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `bondMaturity` | DATE | 债券到期日。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |
| `settlementDate` | DATE | 结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `lastCpnDate` | DATE | 上一票息日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::calcConversionFactor(
    0.03, "ANNUAL", 0.03, 2025.07.22, asOfDate, 2021.07.22)
```

#### calcImpliedRepoRate

##### 语法

```dolphindb
caplib::calcImpliedRepoRate(futPrice DOUBLE, conversionFactor DOUBLE, bondCleanPrice DOUBLE, bondCpnRate DOUBLE, asOfDate DATE, lastCpnDate DATE, settlementDate DATE, dayCount STRING, nextCpnDate DATE, cpnFreq STRING)
```

##### 详情

根据期货价格、转换因子、债券净价、票息现金流、日期和日计数约定计算隐含回购利率。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `futPrice` | DOUBLE | 期货价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `conversionFactor` | DOUBLE | 转换因子。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `bondCleanPrice` | DOUBLE | 债券净价。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `bondCpnRate` | DOUBLE | 债券票息率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `lastCpnDate` | DATE | 上一票息日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |
| `settlementDate` | DATE | 结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 识别值：`ACT_360`, `ACT/360`, `ACT_365`, `ACT/365`, `30/360`。不区分大小写。 |
| `nextCpnDate` | DATE | 下一票息日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |
| `cpnFreq` | STRING | 票息频率。 **有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 任何其他字符串均回退到函数指定的默认频率。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::calcImpliedRepoRate(
    98.0, 1.0, 99.0, 0.03, asOfDate, 2021.07.22, 2021.09.22,
    "ACT_365", 2022.07.22, "ANNUAL")
```

#### calcZSpread

##### 语法

```dolphindb
caplib::calcZSpread(npv DOUBLE, calculationDate DATE, bondBytes STRING, discountCurveBytes STRING, spreadCurveBytes STRING)
```

##### 详情

求解常量 Z 利差，使序列化 VanillaBond 现金流经输入曲线贴现后等于目标 NPV。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `npv` | DOUBLE | 净现值。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `calculationDate` | DATE | 执行计算的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `bondBytes` | STRING | 债券对象 protobuf 字节。 **有效性:** 必须是非空二进制 STRING，并能解析为说明中的精确 protobuf 类型。 |
| `discountCurveBytes` | STRING | 贴现曲线 protobuf 字节或 内存对象 句柄。 **有效性:** 必须是非空二进制 STRING，并能解析为说明中的精确 protobuf 类型。 |
| `spreadCurveBytes` | STRING | 利差曲线 protobuf 字节或 内存对象 句柄。 **有效性:** 必须是非空二进制 STRING，并能解析为说明中的精确 protobuf 类型。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::calcZSpread(npv, calculationDate, bondBytes, discountCurveBytes, spreadCurveBytes)
```

#### calcYieldToMaturity

##### 语法

```dolphindb
caplib::calcYieldToMaturity(calculationDate DATE, compoundingType STRING, bondHandle STRING, forwardCurveHandle STRING, price DOUBLE, priceType STRING, frequency STRING)
```

##### 详情

根据价格和报价约定求解缓存 VanillaBond 的收益率；远期曲线句柄为空时使用平坦零曲线。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calculationDate` | DATE | 执行计算的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `compoundingType` | STRING | 复利类型。 **有效性:** 识别值：`SIMPLE`, `SIMPLE_COMPOUNDING`, `COMPOUNDED`, `DISCRETE`, `DISCRETE_COMPOUNDING`, `CONTINUOUS`, `CONTINUOUS_COMPOUNDING`。不区分大小写。 空值或其他字符串回退为 DISCRETE_COMPOUNDING。 |
| `bondHandle` | STRING | 债券对象 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `forwardCurveHandle` | STRING | 远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `price` | DOUBLE | 价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `priceType` | STRING | 价格类型。 **有效性:** 识别值：`YIELD`, `YIELD_TO_MATURITY`, `YTM`, `CLEAN`, `CLEAN_PRICE`, `DIRTY`, `DIRTY_PRICE`。不区分大小写。 空值或其他字符串回退为 CLEAN_PRICE。 |
| `frequency` | STRING | 频率。 **有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 任何其他字符串均回退到函数指定的默认频率。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::calcYieldToMaturity(
    asOfDate, "DISCRETE_COMPOUNDING", vanillaBond, cnyTreasStdCfets[0], 972294.9381034705,
    "DIRTY_PRICE", "ANNUAL")
```

#### calcFixedCpnBondParRate

##### 语法

```dolphindb
caplib::calcFixedCpnBondParRate(calculationDate DATE, bondHandle STRING, discountCurveHandle STRING, spreadCurveHandle STRING)
```

##### 详情

计算使缓存 VanillaBond 平价的票息；利差曲线句柄为空时使用平坦零利差。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calculationDate` | DATE | 执行计算的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `bondHandle` | STRING | 债券对象 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `spreadCurveHandle` | STRING | 利差曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::calcFixedCpnBondParRate(
    asOfDate, vanillaBond, cnyTreasStdCfets[0], "")
```

#### priceVanillaBond

##### 语法

```dolphindb
caplib::priceVanillaBond(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价普通债券。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceVanillaBond(
    vanillaBond, asOfDate, fiMktData[0], pricingSettings, fiRisk[0], "", "", true)
```

#### buildVanillaBond

##### 语法

```dolphindb
caplib::buildVanillaBond(nominal DOUBLE, instTemplate STRING, fixings STRING, startDate DATE, tag STRING[, returnJson BOOL])
```

##### 详情

构建普通债券工具。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `VanillaBond`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `instTemplate` | STRING | 工具模板对象或模板句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `fixings` | STRING | 历史定盘值对象或数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `startDate` | DATE | 起始日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VanillaBond` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildVanillaBond(
    1000000.0, bondTemplate, "", 2020.07.22, "FI_VANILLA_BOND", false)
```

#### createBondParCurve

##### 语法

```dolphindb
caplib::createBondParCurve(referenceDate DATE, currency STRING, instrumentNames STRING[], quotes DOUBLE[], quoteType STRING, curveName STRING[, returnJson BOOL])
```

##### 详情

创建并缓存债券平价曲线输入。 函数验证并转换字段，构造 `BondParCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `instrumentNames` | STRING[] | 市场工具名称数组。 **有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `quotes` | DOUBLE[] | 市场报价值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `quoteType` | STRING | 市场报价类型。 **有效性:** 可接受值：`YIELD`, `YIELD_TO_MATURITY`, `YTM`, `CLEAN`, `CLEAN_PRICE`, `DIRTY`, `DIRTY_PRICE`。不区分大小写。 |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `BondParCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createBondParCurve(
    asOfDate, currency, cnyTreasBondNames, cnyTreasBondQuotes,
    "YIELD_TO_MATURITY", cnyTreasStdCfetsName, true)
```

#### createFixedLegDefinition

##### 语法

```dolphindb
caplib::createFixedLegDefinition(currency STRING, calendar STRING or STRING[], freq STRING, dayCount STRING, interestDayConvention STRING, stubPolicy STRING, brokenPeriodType STRING, payDayOffset INT, payDayConvention STRING, notionalExchange STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存固定利率腿定义。 函数验证并转换字段，构造 `InterestRateLegDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `calendar` | STRING or STRING[] | 业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `freq` | STRING | 支付或计息频率。 **有效性:** 可接受值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 其他字符串会回退到该函数的默认日计数，而不是报错。 |
| `interestDayConvention` | STRING | 计息日调整约定。 **有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `stubPolicy` | STRING | 短长首末期处理规则。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_STUB_POLICY`, `INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `brokenPeriodType` | STRING | 不规则首末期处理类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BROKEN_PERIOD_TYPE`, `SHORT`, `LONG`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `payDayOffset` | INT | 付款日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `payDayConvention` | STRING | 付款日调整约定。 **有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `notionalExchange` | STRING | 是否交换名义本金。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_NOTIONAL_EXCHANGE`, `INITIAL_EXCHANGE`, `INTERMEDIATE_EXCHANGE`, `INITIAL_INTERMEDIATE_EXCHANGE`, `FINAL_EXCHANGE`, `INITIAL_FINAL_EXCHANGE`, `INTERMEDIATE_FINAL_EXCHANGE`, `INITIAL_INTERMEDIATE_FINAL_EXCHANGE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestRateLegDefinition` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFixedLegDefinition(
    currency, calCfets, "QUARTERLY", "ACT_365_FIXED",
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "INVALID_NOTIONAL_EXCHANGE", "IR_FIXED_LEG", true)
```

#### createFloatingLegDefinition

##### 语法

```dolphindb
caplib::createFloatingLegDefinition(currency STRING, refIndex STRING, calendar STRING or STRING[], fixingCalendars STRING or STRING[], freq STRING, fixingFreq STRING, dayCount STRING, paymentDiscountMethod STRING, rateCalcMethod STRING, spread BOOL, interestDayConvention STRING, stubPolicy STRING, brokenPeriodType STRING, payDayOffset INT, payDayConvention STRING, fixingDayConvention STRING, fixingMode STRING, fixingDayOffset INT[, notionalExchange STRING], tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存浮动利率腿定义。 函数验证并转换字段，构造 `InterestRateLegDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `refIndex` | STRING | 参考利率指数名称或句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `calendar` | STRING or STRING[] | 业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `fixingCalendars` | STRING or STRING[] | 定盘日业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `freq` | STRING | 支付或计息频率。 **有效性:** 可接受值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `fixingFreq` | STRING | 定盘频率。 **有效性:** 可接受值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 其他字符串会回退到该函数的默认日计数，而不是报错。 |
| `paymentDiscountMethod` | STRING | 付款金额贴现方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_PAYMENT_DISCOUNT_METHOD`, `NO_DISCOUNT`, `DISCOUNT_AT_FLOATING_RATE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `rateCalcMethod` | STRING | 利率计算方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_INTEREST_RATE_CALCULATION_METHOD`, `STANDARD`, `COMPOUND_AVERAGE`, `ARITHMETIC_AVERAGE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `spread` | BOOL | 利差。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `interestDayConvention` | STRING | 计息日调整约定。 **有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `stubPolicy` | STRING | 短长首末期处理规则。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_STUB_POLICY`, `INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `brokenPeriodType` | STRING | 不规则首末期处理类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BROKEN_PERIOD_TYPE`, `SHORT`, `LONG`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `payDayOffset` | INT | 付款日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `payDayConvention` | STRING | 付款日调整约定。 **有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `fixingDayConvention` | STRING | 定盘日调整约定。 **有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `fixingMode` | STRING | 定盘值处理方式。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DATE_GENERATION_MODE`, `IN_ADVANCE`, `IN_ARREAR`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fixingDayOffset` | INT | 定盘日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `notionalExchange` | STRING, optional | 是否交换名义本金。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_NOTIONAL_EXCHANGE`, `INITIAL_EXCHANGE`, `INTERMEDIATE_EXCHANGE`, `INITIAL_INTERMEDIATE_EXCHANGE`, `FINAL_EXCHANGE`, `INITIAL_FINAL_EXCHANGE`, `INTERMEDIATE_FINAL_EXCHANGE`, `INITIAL_INTERMEDIATE_FINAL_EXCHANGE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestRateLegDefinition` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFloatingLegDefinition(
    currency, iborIndex[0], calCfets, [calCfets],
    "QUARTERLY", "QUARTERLY", "ACT_360",
    "NO_DISCOUNT", "STANDARD", false,
    "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "MODIFIED_PRECEDING",
    "IN_ADVANCE", -1, "INVALID_NOTIONAL_EXCHANGE", "IR_FLOATING_LEG", true)
```

#### createDepoTemplate

##### 语法

```dolphindb
caplib::createDepoTemplate(instName STRING, currency STRING, calendar STRING or STRING[][, startDelay INT[, dayCount STRING[, interestDayConvention STRING[, payDayOffset INT[, payDayConvention STRING[, startConvention STRING]]]]]][, returnJson BOOL])
```

##### 详情

创建并缓存存款工具模板。 函数验证并转换字段，构造 `InterestRateInstrumentTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `calendar` | STRING or STRING[] | 业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `startDelay` | INT, optional | 起息或交割延迟天数。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `dayCount` | STRING, optional | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 其他字符串会回退到该函数的默认日计数，而不是报错。 |
| `interestDayConvention` | STRING, optional | 计息日调整约定。 **有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `payDayOffset` | INT, optional | 付款日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `payDayConvention` | STRING, optional | 付款日调整约定。 **有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `startConvention` | STRING, optional | 工具起息约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_INSTRUMENT_START_CONVENTION`, `SPOTSTART`, `TODAYSTART`, `TOMORROWSTART`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestRateInstrumentTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createDepoTemplate(instName, currency, calendar)
```

#### createFraTemplate

##### 语法

```dolphindb
caplib::createFraTemplate(instName STRING, refIndex STRING, currency STRING, calendar STRING or STRING[], fixingCalendars STRING or STRING[], freq STRING[, dayCount STRING[, paymentDiscountMethod STRING[, interestDayConvention STRING[, payDayOffset INT[, payDayConvention STRING[, fixingDayConvention STRING[, fixingDayOffset INT]]]]]]][, returnJson BOOL])
```

##### 详情

创建并缓存远期利率协议模板。 函数验证并转换字段，构造 `InterestRateInstrumentTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `refIndex` | STRING | 参考利率指数名称或句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `calendar` | STRING or STRING[] | 业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `fixingCalendars` | STRING or STRING[] | 定盘日业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `freq` | STRING | 支付或计息频率。 **有效性:** 可接受值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `dayCount` | STRING, optional | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 其他字符串会回退到该函数的默认日计数，而不是报错。 |
| `paymentDiscountMethod` | STRING, optional | 付款金额贴现方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_PAYMENT_DISCOUNT_METHOD`, `NO_DISCOUNT`, `DISCOUNT_AT_FLOATING_RATE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `interestDayConvention` | STRING, optional | 计息日调整约定。 **有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `payDayOffset` | INT, optional | 付款日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `payDayConvention` | STRING, optional | 付款日调整约定。 **有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `fixingDayConvention` | STRING, optional | 定盘日调整约定。 **有效性:** 可接受值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 其他字符串会回退到该函数的默认/无效哨兵。 |
| `fixingDayOffset` | INT, optional | 定盘日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestRateInstrumentTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createFraTemplate(instName, refIndex, currency, calendar, fixingCalendars, freq)
```

#### createBondLegDefinition

##### 语法

```dolphindb
caplib::createBondLegDefinition(bondType STRING, settlementDays INT, currency STRING, dayCount STRING, calendar STRING, frequency STRING, interestDayConvention STRING, stubPolicy STRING, brokenPeriodType STRING, payDayOffset INT, payDayConvention STRING, refIndex STRING, fixingCalendars STRING, fixingFreq STRING, fixingDayConvention STRING, fixingMode STRING, fixingDayOffset INT, instName STRING[, returnJson BOOL])
```

##### 详情

创建并缓存债券现金流腿定义。 函数验证并转换字段，构造 `InterestRateLegDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `bondType` | STRING | 债券类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`FIXED_COUPON_BOND`, `FLOATING_COUPON_BOND`, `ZERO_COUPON_BOND`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 任何其他字符串均回退到函数指定的默认日计数。 |
| `calendar` | STRING | 业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `frequency` | STRING | 频率。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_FREQUENCY`, `ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `interestDayConvention` | STRING | 计息日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `stubPolicy` | STRING | 短长首末期处理规则。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_STUB_POLICY`, `INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `brokenPeriodType` | STRING | 不规则首末期处理类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BROKEN_PERIOD_TYPE`, `SHORT`, `LONG`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `payDayOffset` | INT | 付款日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `payDayConvention` | STRING | 付款日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `refIndex` | STRING | 参考利率指数名称或句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `fixingCalendars` | STRING | 定盘日业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `fixingFreq` | STRING | 定盘频率。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_FREQUENCY`, `ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fixingDayConvention` | STRING | 定盘日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fixingMode` | STRING | 定盘值处理方式。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DATE_GENERATION_MODE`, `IN_ADVANCE`, `IN_ARREAR`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fixingDayOffset` | INT | 定盘日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestRateLegDefinition` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createBondLegDefinition(
    "FIXED_COUPON_BOND", 1, currency, "ACT_365_FIXED", "CAL_CFETS",
    "ANNUAL", "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "", "", "ANNUAL",
    "MODIFIED_FOLLOWING", "IN_ADVANCE", -1, "FI_BOND_LEG", false)
```

#### createVanillaBondTemplate

##### 语法

```dolphindb
caplib::createVanillaBondTemplate(instName STRING, vanillaBondType STRING, issueDate DATE, settlementDays INT, startDate DATE, maturity STRING, rate DOUBLE, currency STRING, issuePrice DOUBLE, dayCount STRING, calendar STRING, frequency STRING, interestDayConvention STRING, stubPolicy STRING, brokenPeriodType STRING, payDayOffset INT, payDayConvention STRING, refIndex STRING, fixingCalendars STRING or STRING[], fixingFreq STRING, fixingDayConvention STRING, fixingMode STRING, fixingDayOffset INT, exCouponPeriod STRING, exCouponCalendar STRING, exCouponDayConvention STRING, exCouponEndOfMonth BOOL[, notionalType STRING[, recoveryRate DOUBLE]][, returnJson BOOL])
```

##### 详情

创建并缓存普通债券模板。 函数验证并转换字段，构造 `VanillaBondTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `vanillaBondType` | STRING | 普通债券类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`FIXED_COUPON_BOND`, `FLOATING_COUPON_BOND`, `ZERO_COUPON_BOND`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `issueDate` | DATE | 发行日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `startDate` | DATE | 起始日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `maturity` | STRING | 到期期限或到期日。 **有效性:** 值必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `rate` | DOUBLE | 利率或票息率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `issuePrice` | DOUBLE | 发行价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 任何其他字符串均回退到函数指定的默认日计数。 |
| `calendar` | STRING | 业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `frequency` | STRING | 频率。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_FREQUENCY`, `ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `interestDayConvention` | STRING | 计息日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `stubPolicy` | STRING | 短长首末期处理规则。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_STUB_POLICY`, `INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `brokenPeriodType` | STRING | 不规则首末期处理类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BROKEN_PERIOD_TYPE`, `SHORT`, `LONG`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `payDayOffset` | INT | 付款日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `payDayConvention` | STRING | 付款日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `refIndex` | STRING | 参考利率指数名称或句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `fixingCalendars` | STRING or STRING[] | 定盘日业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `fixingFreq` | STRING | 定盘频率。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_FREQUENCY`, `ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fixingDayConvention` | STRING | 定盘日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `fixingMode` | STRING | 定盘值处理方式。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DATE_GENERATION_MODE`, `IN_ADVANCE`, `IN_ARREAR`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fixingDayOffset` | INT | 定盘日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `exCouponPeriod` | STRING | 除息期长度。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `exCouponCalendar` | STRING | 除息日业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `exCouponDayConvention` | STRING | 除息日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `exCouponEndOfMonth` | BOOL | 除息期是否使用月末规则。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `notionalType` | STRING, optional | 名义本金类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`CONST_NOTIONAL`, `AMORTISING_NOTIONAL`, `ACCRETING_NOTIONAL`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `recoveryRate` | DOUBLE, optional | 回收率。 **有效性:** 必须有限且业务有效范围为 `[0,1]`；包装器仅检查类型。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VanillaBondTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createVanillaBondTemplate(
    "CNY_TREAS_CPN_BOND", "FIXED_COUPON_BOND",
    2020.07.22, 1, 2020.07.22, "5Y",
    0.03, 100.0, 0.4, bondLeg, false)
```

#### createBondYieldCurveBuildSettings

##### 语法

```dolphindb
caplib::createBondYieldCurveBuildSettings(curveName STRING, curveType STRING, interpMethod STRING, extrapMethod STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存债券收益率曲线构建设置。 函数验证并转换字段，构造 `BondYieldCurveBuildSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `curveType` | STRING | 曲线值类型，例如零利率、贴现因子或利差。 **有效性:** 值必须是以下完整 protobuf 标签之一：`ZERO_RATE`, `LOG_DISCOUNT`, `FORWARD_RATE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `interpMethod` | STRING | 插值方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_INTERP_METHOD`, `LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `SABR_INTERP`, `SVI_INTERP`, `LOG_MONEYNESS_CUBIC_SPLINE_INTERP`, `SABR_NORMAL_INTERP`, `QUADRATIC_POLYNOMIAL_INTERP`, `CUBIC_POLYNOMIAL_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `extrapMethod` | STRING | 外推方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_EXTRAP_METHOD`, `FLAT_EXTRAP`, `LINEAR_EXTRAP`, `NATURAL_EXTRAP`, `ADJ_FLAT_EXTRAP`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `BondYieldCurveBuildSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createBondYieldCurveBuildSettings(
    cnyTreasStdCfetsName, "ZERO_RATE", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CNY_TREAS_STD_CFETS_BUILD_SETTINGS", true)
```

#### createFiMktDataSet

##### 语法

```dolphindb
caplib::createFiMktDataSet(asOfDate DATE, discountCurve STRING, creditCurve STRING, underlyingDiscountCurve STRING, underlyingIncomeCurve STRING, underlyingForwardCurve STRING, name STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存固定收益市场数据集。 函数验证并转换字段，构造 `FiMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `discountCurve` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `creditCurve` | STRING | 信用曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `underlyingDiscountCurve` | STRING | 标的贴现曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `underlyingIncomeCurve` | STRING | 标的收益曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `underlyingForwardCurve` | STRING | 标的远期曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FiMktDataSet` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFiMktDataSet(
    asOfDate, discountCurve, spreadCurve, "", "", "", "FI_MKT_NAME", "FI_MKT", true)
```

#### createBondMktDataSet

##### 语法

```dolphindb
caplib::createBondMktDataSet(asOfDate DATE, discountCurve STRING, creditCurve STRING, forwardCurve STRING, name STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存债券市场数据集。 函数验证并转换字段，构造 `FiMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `discountCurve` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `creditCurve` | STRING | 信用曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `forwardCurve` | STRING | 远期曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FiMktDataSet` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createBondMktDataSet(
    asOfDate, cnyTreasStdCfets[0], cnyMtnAaaSprdStdCfets[0],
    cnyTreasStdCfets[0], "FI_BOND_MKT_NAME", "FI_BOND_MKT", true)
```

#### createFiRiskSettings

##### 语法

```dolphindb
caplib::createFiRiskSettings(irCurveSettings STRING, csCurveSettings STRING, thetaSettings STRING, name STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存固定收益风险设置。 函数验证并转换字段，构造 `FiRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `irCurveSettings` | STRING | 利率曲线风险设置 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `csCurveSettings` | STRING | 信用利差曲线风险设置 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `thetaSettings` | STRING | 设置对象的缓存句柄或配置值。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FiRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFiRiskSettings(
    irRisk, creditRisk, thetaRisk, "FI_RISK_NAME", "FI_RISK", true)
```

#### createVanillaBondRiskSettings

##### 语法

```dolphindb
caplib::createVanillaBondRiskSettings(dv01 STRING, cs01 STRING, theta BOOL, name STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存普通债券风险设置。 函数验证并转换字段，构造 `FiRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `dv01` | STRING | 是否计算 DV01 利率风险。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `cs01` | STRING | 是否计算 CS01 信用利差风险。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `theta` | BOOL | 是否计算 Theta 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FiRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createVanillaBondRiskSettings(
    "", "", 1, "FI_VANILLA_BOND_RISK_NAME", "FI_VANILLA_BOND_RISK", true)
```

#### createAssetYieldCurve

##### 语法

```dolphindb
caplib::createAssetYieldCurve(referenceDate DATE, pillarDates DATE[], pillarValues DOUBLE[], interp STRING, extrap STRING, dcc STRING, compounding STRING, pillarNames STRING[], curveName STRING, handle STRING[, returnJson BOOL])
```

##### 详情

根据对齐的日期与命名支柱以及所选插值、外推、日计数和复利方式创建资产收益率曲线。 函数验证并转换字段，构造 `AssetYieldCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `pillarDates` | DATE[] | 曲线节点日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `pillarValues` | DOUBLE[] | 曲线节点值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `interp` | STRING | 插值方法。 **有效性:** 可接受值：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。仅接受所示精确拼写。 |
| `extrap` | STRING | 外推方法。 **有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。 |
| `dcc` | STRING | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 |
| `compounding` | STRING | 复利约定。 **有效性:** 可接受值：`CONTINUOUS_COMPOUNDING`, `DISCRETE_COMPOUNDING`, `SIMPLE_COMPOUNDING`。仅接受所示精确拼写。 |
| `pillarNames` | STRING[] | 操作使用的字符串向量。 **有效性:** 元素不得为空且长度须与配对参数一致。 |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `AssetYieldCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createAssetYieldCurve(
    asOfDate, curveDates, curveValues,
    "LINEAR_INTERP", "FLAT_EXTRAP", "ACT_365_FIXED",
    "CONTINUOUS_COMPOUNDING", ["1D", "3Y"],
    "AN_ASSET_YIELD_CURVE", "AN_ASSET_YIELD_CURVE", false)
```

### 利率

#### calcIrVanillaSwapRate

##### 语法

```dolphindb
caplib::calcIrVanillaSwapRate(calculationDate DATE, swapTemplateHandle STRING, tenor STRING, discountCurveHandle STRING, forwardCurveHandle STRING)
```

##### 详情

在计算日组合缓存的掉期模板、贴现曲线和远期曲线，计算指定期限的平价固定利率。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calculationDate` | DATE | 执行计算的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `swapTemplateHandle` | STRING | 互换模板 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `tenor` | STRING | 期限字符串，例如 3M、6M、1Y 或 5Y。 **有效性:** 值必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `forwardCurveHandle` | STRING | 远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::calcIrVanillaSwapRate(calculationDate, swapTemplateHandle, tenor, discountCurveHandle, forwardCurveHandle)
```

#### calcIborIndexRate

##### 语法

```dolphindb
caplib::calcIborIndexRate(fixingDates DATE[], iborIndexHandle STRING, irYieldCurveHandle STRING)
```

##### 详情

把缓存 IborIndex 约定应用到缓存 IrYieldCurve，为每个输入日期计算 IBOR 定盘值；输出顺序与 fixingDates 一致。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `iborIndexHandle` | STRING | IBOR 指数 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `irYieldCurveHandle` | STRING | 利率收益率曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |

##### 返回值

**返回：** DOUBLE 向量，元素顺序与输入一致。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::calcIborIndexRate(fixingDates, iborIndexHandle, irYieldCurveHandle)
```

#### calcTenorBasisSwapSpread

##### 语法

```dolphindb
caplib::calcTenorBasisSwapSpread(calculationDate DATE, swapTemplateHandle STRING, tenor STRING, discountCurveHandle STRING, shortForwardCurveHandle STRING, longForwardCurveHandle STRING)
```

##### 详情

使用缓存模板、贴现曲线和两条远期曲线，计算使长短期限浮动腿平衡的利差。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calculationDate` | DATE | 执行计算的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `swapTemplateHandle` | STRING | 互换模板 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `tenor` | STRING | 期限字符串，例如 3M、6M、1Y 或 5Y。 **有效性:** 值必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `shortForwardCurveHandle` | STRING | 短期限远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `longForwardCurveHandle` | STRING | 长期限远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::calcTenorBasisSwapSpread(calculationDate, swapTemplateHandle, tenor, discountCurveHandle, shortForwardCurveHandle, longForwardCurveHandle)
```

#### buildIrSingleCurrencyCurve

##### 语法

```dolphindb
caplib::buildIrSingleCurrencyCurve(referenceDate DATE, targetCurveNames STRING[], buildSettingsHandles STRING[], parCurveHandles STRING[], dayCountConvention STRING, compoundingType STRING, frequency STRING, otherCurveHandles STRING[], buildingMethod STRING, calcJacobian BOOL, shift DOUBLE, finiteDifferenceMethod STRING, threadingMode STRING, targetCurveHandles STRING[], outputHandle STRING[, returnJson BOOL])
```

##### 详情

构建单币种利率曲线组。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrSingleCurrencyCurveBuildingOutput`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `targetCurveNames` | STRING[] | 待构建目标曲线名称数组。 **有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `buildSettingsHandles` | STRING[] | 曲线构建设置 内存对象 句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `parCurveHandles` | STRING[] | 平价曲线输入对象 内存对象 句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `dayCountConvention` | STRING | 日计数约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DAY_COUNT_CONVENTION`, `ACT_360`, `ACTUAL_360`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `ACT_ACT_ISMA`, `ACTUAL_ACTUAL_ISMA`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `THIRTY_360`, `BOND_BASIS`, `THIRTY_E_360`, `EUROBOND_BASIS`, `THIRTY_E_360_ISDA`, `ONE_ONE`, `THIRTY_U_360`, `THIRTY_U_360_EOM`, `THIRTY_360_PSA`, `THIRTY_E_360_PLUS`, `THIRTY_360_IT`, `ACT_ACT_AFB`, `ACTUAL_ACTUAL_AFB`, `ACT_364`, `ACTUAL_364`, `ACT_365_25`, `ACTUAL_365_25`, `ACT_365_ACT`, `ACTUAL_365_ACTUAL`, `ACT_365_L`, `ACTUAL_365_LONG`, `ACT_365_NL`, `ACTUAL_365_NO_LEAP`, `ACT_ACT_YEAR`, `ACTUAL_ACTUAL_YEAR`, `BUSINESS_252`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `compoundingType` | STRING | 复利类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_COMPOUNDING_TYPE`, `CONTINUOUS_COMPOUNDING`, `DISCRETE_COMPOUNDING`, `SIMPLE_COMPOUNDING`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `frequency` | STRING | 频率。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_FREQUENCY`, `ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `otherCurveHandles` | STRING[] | 构建所需的其他曲线 内存对象 句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `buildingMethod` | STRING | 曲线或曲面构建算法名称。 **有效性:** 值必须是以下完整 protobuf 标签之一：`BOOTSTRAPPING_METHOD`, `GLOBAL_OPTIMIZATION_METHOD`, `HYBRID_METHOD`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `calcJacobian` | BOOL | 是否计算并返回校准雅可比信息。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `shift` | DOUBLE | 风险或校准计算使用的扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `finiteDifferenceMethod` | STRING | 有限差分方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`CENTRAL_DIFFERENCE_METHOD`, `ONE_SIDE_DOWN_METHOD`, `ONE_SIDE_UP_METHOD`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `threadingMode` | STRING | 线程模式。 **有效性:** 值必须是以下完整 protobuf 标签之一：`SINGLE_THREADING_MODE`, `MULTI_THREADING_MODE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `targetCurveHandles` | STRING[] | 构建输出的目标曲线句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `outputHandle` | STRING | 构建输出对象的缓存句柄。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrSingleCurrencyCurveBuildingOutput` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildIrSingleCurrencyCurve(
    asOfDate,
    [curveName],
    [curveBuildSettings[0]],
    [builderParCurve[0]],
    "ACT_365_FIXED",
    "CONTINUOUS_COMPOUNDING",
    "ANNUAL",
    [],
    "BOOTSTRAPPING_METHOD",
    0,
    1.0e-4,
    "CENTRAL_DIFFERENCE_METHOD",
    "SINGLE_THREADING_MODE",
    ["IR_BUILT_CURVE"],
    "IR_SINGLE_CCY_BUILD_OUTPUT", true)
```

#### buildIrCapFloorVolatilitySurface

##### 语法

```dolphindb
caplib::buildIrCapFloorVolatilitySurface(iborIndex STRING, referenceDate DATE, quoteMatrixHandle STRING, discountCurveHandle STRING, forwardCurveHandle STRING, definitionHandle STRING, displacement DOUBLE, name STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建利率上限/下限波动率曲面。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrCapFloorVolatilitySurface`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `iborIndex` | STRING | IBOR 指数名称或句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `quoteMatrixHandle` | STRING | 期权报价矩阵 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `forwardCurveHandle` | STRING | 远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `definitionHandle` | STRING | 波动率曲面定义 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `displacement` | DOUBLE | 移位对数正态模型使用的位移参数。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrCapFloorVolatilitySurface` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::buildIrCapFloorVolatilitySurface(iborIndex, referenceDate, quoteMatrixHandle, discountCurveHandle, forwardCurveHandle, definitionHandle, displacement, name, handle)
```

#### buildIrSwaptionVolatilitySurface

##### 语法

```dolphindb
caplib::buildIrSwaptionVolatilitySurface(instName STRING, referenceDate DATE, quoteCubeHandle STRING, discountCurveHandle STRING, forwardCurveHandle STRING, definitionHandle STRING, buildSettingsHandle STRING, underlyingSwapTemplateHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建利率互换期权波动率曲面。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrSwaptionVolatilitySurface`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `quoteCubeHandle` | STRING | 报价立方体 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `forwardCurveHandle` | STRING | 远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `definitionHandle` | STRING | 波动率曲面定义 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `buildSettingsHandle` | STRING | 构建设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `underlyingSwapTemplateHandle` | STRING | 标的互换模板 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrSwaptionVolatilitySurface` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::buildIrSwaptionVolatilitySurface(instName, referenceDate, quoteCubeHandle, discountCurveHandle, forwardCurveHandle, definitionHandle, buildSettingsHandle, underlyingSwapTemplateHandle, handle)
```

#### priceIrVanillaInstrument

##### 语法

```dolphindb
caplib::priceIrVanillaInstrument(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

执行定价并返回定价结果。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceIrVanillaInstrument(
    swap, asOfDate, mktData[0], pricingSettings, irRisk[0], "", "", true)
```

#### priceIrCapFloor

##### 语法

```dolphindb
caplib::priceIrCapFloor(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

执行定价并返回定价结果。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::priceIrCapFloor(instrumentHandle, pricingDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode)
```

#### priceIrEuropeanSwaption

##### 语法

```dolphindb
caplib::priceIrEuropeanSwaption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

执行定价并返回定价结果。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::priceIrEuropeanSwaption(instrumentHandle, pricingDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode)
```

#### buildIrVanillaInstrument

##### 语法

```dolphindb
caplib::buildIrVanillaInstrument(payReceive STRING, cpnRate DOUBLE, spread DOUBLE, startDate DATE, maturityDate DATE, instTemplate STRING, nominal DOUBLE, legFixings STRING, tag STRING[, returnJson BOOL])
```

##### 详情

构建标准利率工具。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrVanillaInstrument`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `payReceive` | STRING | 支付或收取方向。 **有效性:** 值必须是以下完整 protobuf 标签之一：`PAY`, `PAYER`, `RECEIVE`, `RECEIVER`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `cpnRate` | DOUBLE | 票息率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `spread` | DOUBLE | 利差。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `startDate` | DATE | 起始日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `maturityDate` | DATE | 到期日。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `instTemplate` | STRING | 工具模板对象或模板句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `legFixings` | STRING | 各现金流腿使用的定盘值对象或数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrVanillaInstrument` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildIrVanillaInstrument(
    "PAY", 0.05, 0.0, 2022.03.07, 2023.03.07,
    swapTemplate, 1000000.0, "", "IR_SWAP", false)
```

#### buildIrCapFloor

##### 语法

```dolphindb
caplib::buildIrCapFloor(type STRING, strike DOUBLE, startDate DATE, endDate DATE, currency STRING, notionalAmount DOUBLE, instTemplateHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建利率上限/下限工具。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrCapFloor`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `type` | STRING | 对象类型或业务类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`buildIrCapFloorInput_Type_CAP`, `buildIrCapFloorInput_Type_FLOOR`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `strike` | DOUBLE | 行权价。 **有效性:** 利率行权价必须有限；允许负值、零或正值。包装器仅检查类型/形状。 |
| `startDate` | DATE | 起始日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `endDate` | DATE | 结束日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `notionalAmount` | DOUBLE | 名义本金金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `instTemplateHandle` | STRING | 工具模板 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrCapFloor` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::buildIrCapFloor(type, strike, startDate, endDate, currency, notionalAmount, instTemplateHandle, handle)
```

#### buildIrEuropeanSwaption

##### 语法

```dolphindb
caplib::buildIrEuropeanSwaption(exerciseDate DATE, settlementDate DATE, settlementType STRING, swapMaturity DATE, fixedRate DOUBLE, payReceive STRING, currency STRING, notionalAmount DOUBLE, instTemplateHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建欧式利率互换期权。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrEuropeanSwaption`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `exerciseDate` | DATE | 日期或日期数组。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |
| `settlementDate` | DATE | 结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `settlementType` | STRING | 结算类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`PHYSICAL_SETTLEMENT`, `CASH_SETTLEMENT`, `CASH_ZERO_COUPON_SETTLEMENT`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `swapMaturity` | DATE | 互换到期期限。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |
| `fixedRate` | DOUBLE | 固定利率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `payReceive` | STRING | 支付或收取方向。 **有效性:** 值必须是以下完整 protobuf 标签之一：`PAY`, `PAYER`, `RECEIVE`, `RECEIVER`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `notionalAmount` | DOUBLE | 名义本金金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `instTemplateHandle` | STRING | 工具模板 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrEuropeanSwaption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::buildIrEuropeanSwaption(exerciseDate, settlementDate, settlementType, swapMaturity, fixedRate, payReceive, currency, notionalAmount, instTemplateHandle, handle)
```

#### getDiscountFactor

##### 语法

```dolphindb
caplib::getDiscountFactor(irCurveHandle STRING, dates DATE[])
```

##### 详情

根据缓存 IrYieldCurve 计算给定日期的贴现因子或多个日期的贴现因子。单日传单元素 DATE 向量，多日传更长向量；输出保持输入顺序。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `irCurveHandle` | STRING | 所引用具体类的 ObjectCache 句柄。 **有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。 |
| `dates` | DATE[] | 请求曲线值的日期；结果第 i 个元素对应 dates[i]。 **有效性:** 必须是无空值 DATE 向量。单日使用单元素向量，多日使用更长向量；不接受 DATE 标量。 |

##### 返回值

**返回：** DOUBLE 向量，元素顺序与输入一致。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::getDiscountFactor(curve, 2025.07.15)
```

#### getZeroRate

##### 语法

```dolphindb
caplib::getZeroRate(irCurveHandle STRING, dates DATE[])
```

##### 详情

根据缓存 IrYieldCurve 为每个输入日期计算零利率；输出保持输入顺序。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `irCurveHandle` | STRING | 所引用具体类的 ObjectCache 句柄。 **有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。 |
| `dates` | DATE[] | 请求曲线值的日期；结果第 i 个元素对应 dates[i]。 **有效性:** 必须是无空值 DATE 向量。单日使用单元素向量，多日使用更长向量；不接受 DATE 标量。 |

##### 返回值

**返回：** DOUBLE 向量，元素顺序与输入一致。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::getZeroRate(curve, 2025.07.15)
```

#### getFwdRate

##### 语法

```dolphindb
caplib::getFwdRate(irCurveHandle STRING, dates DATE[], tenor DOUBLE)
```

##### 详情

计算从每个输入日期开始、对应给定年化期限的远期利率；输出保持日期顺序。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `irCurveHandle` | STRING | 所引用具体类的 ObjectCache 句柄。 **有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。 |
| `dates` | DATE[] | 请求曲线值的日期；结果第 i 个元素对应 dates[i]。 **有效性:** 必须是无空值 DATE 向量。单日使用单元素向量，多日使用更长向量；不接受 DATE 标量。 |
| `tenor` | DOUBLE | 以年化比例表示的远期间隔。 **有效性:** 业务有效值须严格为正且有限；包装器仅检查 DOUBLE 类型。 |

##### 返回值

**返回：** DOUBLE 向量，元素顺序与输入一致。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::getFwdRate(curve, 2025.01.15, 2025.07.15)
```

#### createIrYieldCurve

##### 语法

```dolphindb
caplib::createIrYieldCurve(referenceDate DATE, pillarDates DATE[], pillarValues DOUBLE[], curveType STRING, dcc STRING, interp STRING, extrap STRING, compounding STRING, currency STRING, name STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存利率收益率曲线。 函数验证并转换字段，构造 `IrYieldCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `pillarDates` | DATE[] | 曲线节点日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `pillarValues` | DOUBLE[] | 曲线节点值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `curveType` | STRING | 曲线值类型，例如零利率、贴现因子或利差。 **有效性:** 可接受值：`ZERO_RATE`, `LOG_DISCOUNT`, `FORWARD_RATE`。仅接受所示精确拼写。 |
| `dcc` | STRING | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 |
| `interp` | STRING | 插值方法。 **有效性:** 可接受值：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。仅接受所示精确拼写。 |
| `extrap` | STRING | 外推方法。 **有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。 |
| `compounding` | STRING | 复利约定。 **有效性:** 可接受值：`CONTINUOUS_COMPOUNDING`, `DISCRETE_COMPOUNDING`, `SIMPLE_COMPOUNDING`。仅接受所示精确拼写。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrYieldCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createIrYieldCurve(
    asOfDate,
    [2020.02.26, 2020.03.02, 2020.03.09, 2020.03.24],
    [0.0135486283791684, 0.0197762034605164, 0.0197686053073393, 0.0224838821372655],
    "ZERO_RATE", "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "CONTINUOUS_COMPOUNDING", "CNY", "CNY_SHIBOR_3M", "EQ_IR_CURVE", false)
```

#### createIrCurveRiskSettings

##### 语法

```dolphindb
caplib::createIrCurveRiskSettings(delta BOOL, gamma BOOL, curvature BOOL, shift DOUBLE, curvatureShift DOUBLE, method INT, granularity INT, scaling DOUBLE, threading INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存利率曲线风险设置。 函数验证并转换字段，构造 `IrCurveRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `delta` | BOOL | 是否计算 Delta 风险或 Delta 数值。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `gamma` | BOOL | 是否计算 Gamma 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `curvature` | BOOL | 是否计算曲率风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `shift` | DOUBLE | 风险或校准计算使用的扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `curvatureShift` | DOUBLE | 曲率风险使用的扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `method` | INT | 计算、校准或有限差分方法选择器。 **有效性:** 映射：`value =2` 为 ONE_SIDE_UP。 |
| `granularity` | INT | 风险桶或扰动粒度。 **有效性:** 映射：`value =2` 为 TERM_STRIKE。 |
| `scaling` | DOUBLE | 风险扰动缩放因子。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `threading` | INT | 线程模式选择器。 **有效性:** 仅 `1` 选择多线程；其他整数均为单线程。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrCurveRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createIrCurveRiskSettings(
    1, 0, 0, 1.0e-4, 5.0e-1, 0, 1, 1.0e-4, 0, "CR_IR_RISK", false)
```

#### calcCrossCurrencySwapRate

##### 语法

```dolphindb
caplib::calcCrossCurrencySwapRate(calculationDate DATE, swapTemplateHandle STRING, tenor STRING, fxRate DOUBLE, baseCcy STRING, targetCcy STRING, refDate DATE, spotDate DATE, targetDiscountCurveHandle STRING, baseDiscountCurveHandle STRING, baseForwardCurveHandle STRING)
```

##### 详情

根据模板与期限、FX 现货信息以及目标/基础币种贴现和远期曲线计算交叉货币掉期利率。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calculationDate` | DATE | 执行计算的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `swapTemplateHandle` | STRING | 互换模板 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `tenor` | STRING | 期限字符串，例如 3M、6M、1Y 或 5Y。 **有效性:** 值必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `fxRate` | DOUBLE | 外汇汇率输入值。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `baseCcy` | STRING | 外汇或跨币种计算中的基准币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `targetCcy` | STRING | 外汇或跨币种计算中的目标币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `refDate` | DATE | 参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `spotDate` | DATE | 即期结算日。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `targetDiscountCurveHandle` | STRING | 目标币种贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `baseDiscountCurveHandle` | STRING | 基准币种贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `baseForwardCurveHandle` | STRING | 基准币种远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::calcCrossCurrencySwapRate(calculationDate, swapTemplateHandle, tenor, fxRate, baseCcy, targetCcy, refDate, spotDate, targetDiscountCurveHandle, baseDiscountCurveHandle, baseForwardCurveHandle)
```

#### calcCrossCurrencyBasisSwapSpread

##### 语法

```dolphindb
caplib::calcCrossCurrencyBasisSwapSpread(calculationDate DATE, swapTemplateHandle STRING, tenor STRING, fxRate DOUBLE, baseCcy STRING, targetCcy STRING, refDate DATE, spotDate DATE, targetDiscountCurveHandle STRING, targetForwardCurveHandle STRING, baseDiscountCurveHandle STRING, baseForwardCurveHandle STRING)
```

##### 详情

根据模板、FX 现货信息、目标币种曲线和基础币种曲线计算平衡基差。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calculationDate` | DATE | 执行计算的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `swapTemplateHandle` | STRING | 互换模板 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `tenor` | STRING | 期限字符串，例如 3M、6M、1Y 或 5Y。 **有效性:** 值必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `fxRate` | DOUBLE | 外汇汇率输入值。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `baseCcy` | STRING | 外汇或跨币种计算中的基准币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `targetCcy` | STRING | 外汇或跨币种计算中的目标币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `refDate` | DATE | 参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `spotDate` | DATE | 即期结算日。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `targetDiscountCurveHandle` | STRING | 目标币种贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `targetForwardCurveHandle` | STRING | 目标币种远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `baseDiscountCurveHandle` | STRING | 基准币种贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `baseForwardCurveHandle` | STRING | 基准币种远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::calcCrossCurrencyBasisSwapSpread(calculationDate, swapTemplateHandle, tenor, fxRate, baseCcy, targetCcy, refDate, spotDate, targetDiscountCurveHandle, targetForwardCurveHandle, baseDiscountCurveHandle, baseForwardCurveHandle)
```

#### createIrParRateCurve

##### 语法

```dolphindb
caplib::createIrParRateCurve(asOfDate DATE, currency STRING, curveName STRING, instNames STRING[], instTypes STRING[], instTerms STRING[], factors DOUBLE[], quotes DOUBLE[], handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存利率平价利率曲线输入。 函数验证并转换字段，构造 `IrParRateCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `instNames` | STRING[] | 与工具类型、期限和报价对齐的工具名称。 **有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `instTypes` | STRING[] | 构建曲线使用的工具类型数组。 **有效性:** 每个元素必须是以下完整 protobuf 标签之一：`INVALID_INSTRUMENT_TYPE`, `DEPOSIT`, `FORWARD_RATE_AGREEMENT`, `IR_VANILLA_SWAP`, `OVERNIGHT_INDEX_SWAP`, `CROSS_CURRENCY_SWAP`, `MTM_CROSS_CURRENCY_SWAP`, `STD_CROSS_CURRENCY_SWAP`, `IR_BOND`, `NON_DELIVERABLE_SWAP`, `IR_EUROPEAN_SWAPTION`, `IR_CAP_FLOOR`, `IR_FUTURE`, `IR_FUTURE_IMM`, `IR_FUTURE_ASX`, `IR_VANILLA_BOND`, `IMM_FORWARD_RATE_AGREEMENT`, `IR_BOND_OPTION`, `IR_RANGEACCRUAL_SWAP`, `IR_STRUCTURED_SWAP`, `FX_SPOT`, `FX_FORWARD`, `FX_NON_DELIVERABLE_FORWARD`, `FX_SWAP`, `FX_SWAP_ON`, `FX_SWAP_TN`, `FX_EUROPEAN_OPTION`, `FX_TIME_OPTION`, `FX_DIGITAL_OPTION`, `FX_QUANTO_OPTION`, `FX_TOUCH_OPTION`, `FX_BARRIER_OPTION`, `FX_VANILLA_STRATEGY`, `FX_TOUCH_QUANTO_OPTION`, `FX_DIGITAL_QUANTO_OPTION`, `EQ_INDEX_FUTURE`, `EQ_EUROPEAN_OPTION`, `EQ_AMERICAN_OPTION`, `EQ_SPOT`, `EQ_VANILLA_OPTION`, `EQ_DIGITAL_OPTION`, `EQ_BARRIER_OPTION`, `EQ_RANGE_ACCRUAL_OPTION`, `EQ_TOUCH_OPTION`, `EQ_QUANTO_OPTION`, `CM_SPOT`, `CM_FUTURE`, `CM_EUROPEAN_OPTION`, `CM_AMERICAN_OPTION`, `CM_VANILLA_OPTION`, `CM_ASIAN_OPTION`, `CM_DIGITAL_OPTION`, `CM_SWAP`, `CM_DIGITAL_ASIAN_OPTION`, `PM_SPOT`, `PM_SWAP`, `CREDIT_DEFAULT_SWAP`, `SPOT`, `FUTURE`, `FORWARD`, `SWAP`, `EUROPEAN_OPTION`, `AMERICAN_OPTION`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `instTerms` | STRING[] | 与工具名称对齐的工具期限。 **有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `factors` | DOUBLE[] | 与工具或报价对齐的缩放因子。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `quotes` | DOUBLE[] | 市场报价值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrParRateCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createIrParRateCurve(
    asOfDate, currency, curveName,
    [iborIndex[0], curveName, curveName],
    ["DEPOSIT", "IR_VANILLA_SWAP", "IR_VANILLA_SWAP"],
    ["3M", "6M", "1Y"],
    [100.0, 100.0, 100.0],
    [0.023, 0.024, 0.026],
    "IR_PAR_CURVE", true)
```

#### createIrYieldCurveBuildSettings

##### 语法

```dolphindb
caplib::createIrYieldCurveBuildSettings(curveName STRING, useOnTnFxSwap BOOL, discountCurrencyNames STRING[], discountCurveNames STRING[], forwardIndexNames STRING[], forwardCurveNames STRING[], handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存利率收益率曲线构建设置。 函数验证并转换字段，构造 `IrYieldCurveBuildSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `useOnTnFxSwap` | BOOL | 是否使用 ON/TN 外汇掉期工具构建曲线。 **有效性:** 必须是非空 BOOL 标量；兼容旧示例的 INT `0/1`。字符串、空值及其他整数会抛错。 |
| `discountCurrencyNames` | STRING[] | 币种代码。 **有效性:** 必须具有所列元素类型和形状；元素不得为空；除明确说明外包装器不强制非空。 |
| `discountCurveNames` | STRING[] | 贴现曲线名称数组。 **有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `forwardIndexNames` | STRING[] | 远期指数名称数组。 **有效性:** 必须具有所列元素类型和形状；元素不得为空；除明确说明外包装器不强制非空。 |
| `forwardCurveNames` | STRING[] | 远期曲线名称数组。 **有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrYieldCurveBuildSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createIrYieldCurveBuildSettings(
    curveName, 0, [currency], [curveName], [iborIndex[0]], [curveName], "IR_BUILD_SETTINGS", true)
```

#### buildIrCrossCurrencyCurve

##### 语法

```dolphindb
caplib::buildIrCrossCurrencyCurve(referenceDate DATE, targetCurveNames STRING[], buildSettingsHandles STRING[], parCurveHandles STRING[], dayCountConvention STRING, compoundingType STRING, frequency STRING, otherCurveHandles STRING[], fxSpotHandle STRING, buildingMethod STRING, calcJacobian BOOL, shift DOUBLE, finiteDifferenceMethod STRING, threadingMode STRING, targetCurveHandles STRING[], outputHandle STRING[, returnJson BOOL])
```

##### 详情

构建跨币种利率曲线组。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `IrCrossCurrencyCurveBuildingOutput`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `targetCurveNames` | STRING[] | 待构建目标曲线名称数组。 **有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `buildSettingsHandles` | STRING[] | 曲线构建设置 内存对象 句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `parCurveHandles` | STRING[] | 平价曲线输入对象 内存对象 句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `dayCountConvention` | STRING | 日计数约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DAY_COUNT_CONVENTION`, `ACT_360`, `ACTUAL_360`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `ACT_ACT_ISMA`, `ACTUAL_ACTUAL_ISMA`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `THIRTY_360`, `BOND_BASIS`, `THIRTY_E_360`, `EUROBOND_BASIS`, `THIRTY_E_360_ISDA`, `ONE_ONE`, `THIRTY_U_360`, `THIRTY_U_360_EOM`, `THIRTY_360_PSA`, `THIRTY_E_360_PLUS`, `THIRTY_360_IT`, `ACT_ACT_AFB`, `ACTUAL_ACTUAL_AFB`, `ACT_364`, `ACTUAL_364`, `ACT_365_25`, `ACTUAL_365_25`, `ACT_365_ACT`, `ACTUAL_365_ACTUAL`, `ACT_365_L`, `ACTUAL_365_LONG`, `ACT_365_NL`, `ACTUAL_365_NO_LEAP`, `ACT_ACT_YEAR`, `ACTUAL_ACTUAL_YEAR`, `BUSINESS_252`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `compoundingType` | STRING | 复利类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_COMPOUNDING_TYPE`, `CONTINUOUS_COMPOUNDING`, `DISCRETE_COMPOUNDING`, `SIMPLE_COMPOUNDING`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `frequency` | STRING | 频率。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_FREQUENCY`, `ANNUAL`, `SEMIANNUAL`, `EVERY_FOURTH_MONTH`, `QUARTERLY`, `BIMONTHLY`, `MONTHLY`, `EVERY_FOURTH_WEEK`, `BIWEEKLY`, `WEEKLY`, `DAILY`, `ONCE`, `OTHER_FREQUENCY`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `otherCurveHandles` | STRING[] | 构建所需的其他曲线 内存对象 句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `fxSpotHandle` | STRING | 外汇即期汇率 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `buildingMethod` | STRING | 曲线或曲面构建算法名称。 **有效性:** 值必须是以下完整 protobuf 标签之一：`BOOTSTRAPPING_METHOD`, `GLOBAL_OPTIMIZATION_METHOD`, `HYBRID_METHOD`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `calcJacobian` | BOOL | 是否计算并返回校准雅可比信息。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `shift` | DOUBLE | 风险或校准计算使用的扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `finiteDifferenceMethod` | STRING | 有限差分方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`CENTRAL_DIFFERENCE_METHOD`, `ONE_SIDE_DOWN_METHOD`, `ONE_SIDE_UP_METHOD`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `threadingMode` | STRING | 线程模式。 **有效性:** 值必须是以下完整 protobuf 标签之一：`SINGLE_THREADING_MODE`, `MULTI_THREADING_MODE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `targetCurveHandles` | STRING[] | 构建输出的目标曲线句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `outputHandle` | STRING | 构建输出对象的缓存句柄。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrCrossCurrencyCurveBuildingOutput` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::buildIrCrossCurrencyCurve(referenceDate, targetCurveNames, buildSettingsHandles, parCurveHandles, dayCountConvention, compoundingType, frequency, otherCurveHandles, fxSpotHandle, buildingMethod, calcJacobian, shift, finiteDifferenceMethod, threadingMode, targetCurveHandles, outputHandle)
```

#### createIrCapFloorQuoteMatrix

##### 语法

```dolphindb
caplib::createIrCapFloorQuoteMatrix(asOfDate DATE, terms STRING[], strikes DOUBLE vector, vols DOUBLE matrix, instName STRING, factor DOUBLE, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存利率上限/下限报价矩阵。 函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `terms` | STRING[] | 报价期限数组。 **有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `strikes` | DOUBLE vector | 行权价数组或矩阵。 **有效性:** 利率行权价必须有限；允许负值、零或正值。包装器仅检查类型/形状。 |
| `vols` | DOUBLE matrix | 波动率节点值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须非负且有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `factor` | DOUBLE | 报价或工具缩放因子。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `OptionQuoteMatrix` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createIrCapFloorQuoteMatrix(asOfDate, terms, strikes, vols, instName, factor, handle)
```

#### createIrSwaptionQuoteCube

##### 语法

```dolphindb
caplib::createIrSwaptionQuoteCube(inputBytes STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存利率互换期权报价立方体。 函数验证并转换字段，构造 `IrSwaptionQuoteCube` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `inputBytes` | STRING | 输入对象 protobuf 字节。 **有效性:** 必须是非空二进制 STRING，并能解析为说明中的精确 protobuf 类型。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrSwaptionQuoteCube` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createIrSwaptionQuoteCube(inputBytes, handle)
```

#### createIrMktDataSet

##### 语法

```dolphindb
caplib::createIrMktDataSet(asOfDate DATE, discountCurveHandle STRING, underlyingInterestRates STRING[], forwardCurveHandles STRING[], handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存利率市场数据集。 函数验证并转换字段，构造 `IrMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `underlyingInterestRates` | STRING[] | 标的利率指数名称数组。 **有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `forwardCurveHandles` | STRING[] | 远期曲线 内存对象 句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrMktDataSet` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createIrMktDataSet(
    asOfDate, irCurve, [indexName], [irCurve], "IR_MKT", true)
```

#### createIrCrossCcyMktDataSet

##### 语法

```dolphindb
caplib::createIrCrossCcyMktDataSet(asOfDate DATE, baseDiscountCurveHandle STRING, underlyingInterestRates STRING[], forwardCurveHandles STRING[], crossCcyDiscountCurveHandle STRING, fxSpotHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存跨币种利率市场数据集。 函数验证并转换字段，构造 `IrCrossCcyMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `baseDiscountCurveHandle` | STRING | 基准币种贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `underlyingInterestRates` | STRING[] | 标的利率指数名称数组。 **有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `forwardCurveHandles` | STRING[] | 远期曲线 内存对象 句柄数组。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `crossCcyDiscountCurveHandle` | STRING | 跨币种贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `fxSpotHandle` | STRING | 外汇即期汇率 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrCrossCcyMktDataSet` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createIrCrossCcyMktDataSet(asOfDate, baseDiscountCurveHandle, underlyingInterestRates, forwardCurveHandles, crossCcyDiscountCurveHandle, fxSpotHandle, handle)
```

#### createIrRiskSettings

##### 语法

```dolphindb
caplib::createIrRiskSettings(irCurveRiskSettingsHandle STRING, thetaRiskSettingsHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存利率风险设置。 函数验证并转换字段，构造 `IrRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `irCurveRiskSettingsHandle` | STRING | 利率曲线风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `thetaRiskSettingsHandle` | STRING | Theta 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createIrRiskSettings(irCurveRisk, thetaRisk, "IR_RISK", true)
```

#### createXccyIrRiskSettings

##### 语法

```dolphindb
caplib::createXccyIrRiskSettings(irCurveRiskSettingsHandle STRING, fxRiskSettingsHandle STRING, thetaRiskSettingsHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存跨币种利率风险设置。 函数验证并转换字段，构造 `XccyIrRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `irCurveRiskSettingsHandle` | STRING | 利率曲线风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `fxRiskSettingsHandle` | STRING | 外汇风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `thetaRiskSettingsHandle` | STRING | Theta 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `XccyIrRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createXccyIrRiskSettings(irCurveRisk, priceRisk, thetaRisk, "IR_XCCY_RISK", true)
```

#### priceIrCrossCurrencySwap

##### 语法

```dolphindb
caplib::priceIrCrossCurrencySwap(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

执行定价并返回定价结果。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::priceIrCrossCurrencySwap(instrumentHandle, pricingDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode)
```

#### priceIrMtmCrossCurrencySwap

##### 语法

```dolphindb
caplib::priceIrMtmCrossCurrencySwap(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

执行定价并返回定价结果。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::priceIrMtmCrossCurrencySwap(instrumentHandle, pricingDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode)
```

#### createInterestCalcScheduleDefinition

##### 语法

```dolphindb
caplib::createInterestCalcScheduleDefinition(calendars STRING, frequency STRING, interestDayConvention STRING, stubPolicy STRING, brokenPeriodType STRING, dateRollConvention STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存计息日程定义。 函数验证并转换字段，构造 `InterestCaculationScheduleDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calendars` | STRING | 日期调整使用的业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `frequency` | STRING | 频率。 **有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 任何其他字符串均回退到函数指定的默认频率。 |
| `interestDayConvention` | STRING | 计息日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `stubPolicy` | STRING | 短长首末期处理规则。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_STUB_POLICY`, `INITIAL`, `FINAL`, `INITIAL_FINAL_FORWARD`, `INITIAL_FINAL_BACKWARD`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `brokenPeriodType` | STRING | 不规则首末期处理类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BROKEN_PERIOD_TYPE`, `SHORT`, `LONG`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `dateRollConvention` | STRING | 日期或日期数组。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DATE_ROLL_CONVENTION`, `EOM`, `FRN`, `IMM`, `IMM_CAD`, `IMM_AUD`, `IMM_NZD`, `SFE`, `NONE`, `TBILL`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestCaculationScheduleDefinition` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createInterestCalcScheduleDefinition(
    "CAL_CFETS", "QUARTERLY", "MODIFIED_FOLLOWING", "INITIAL", "LONG", "NONE", "IR_FIXED_CALC", false)
```

#### createInterestPaymentScheduleDefinition

##### 语法

```dolphindb
caplib::createInterestPaymentScheduleDefinition(calendars STRING, frequency STRING, payDayMode STRING, payDayOffset INT, payDayConvention STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存付息日程定义。 函数验证并转换字段，构造 `InterestPaymentScheduleDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calendars` | STRING | 日期调整使用的业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `frequency` | STRING | 频率。 **有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 任何其他字符串均回退到函数指定的默认频率。 |
| `payDayMode` | STRING | 付款日生成模式。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DATE_GENERATION_MODE`, `IN_ADVANCE`, `IN_ARREAR`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `payDayOffset` | INT | 付款日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `payDayConvention` | STRING | 付款日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestPaymentScheduleDefinition` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createInterestPaymentScheduleDefinition(
    "CAL_CFETS", "QUARTERLY", "IN_ARREAR", 0, "MODIFIED_FOLLOWING", "IR_FIXED_PAY", false)
```

#### createInterestRateFixingScheduleDefinition

##### 语法

```dolphindb
caplib::createInterestRateFixingScheduleDefinition(calendars STRING, frequency STRING, frequencyRatio INT, fixingDayMode STRING, fixingDayOffset INT, fixingDayConvention STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存利率定盘日程定义。 函数验证并转换字段，构造 `InterestRateFixingScheduleDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calendars` | STRING | 日期调整使用的业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `frequency` | STRING | 频率。 **有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 任何其他字符串均回退到函数指定的默认频率。 |
| `frequencyRatio` | INT | 频率换算比例。 **有效性:** 必须严格为正；包装器通常仅检查类型。 |
| `fixingDayMode` | STRING | 定盘日生成模式。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DATE_GENERATION_MODE`, `IN_ADVANCE`, `IN_ARREAR`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fixingDayOffset` | INT | 定盘日偏移天数。 **有效性:** 必须是 INT；除非另有说明，可为负、零或正。 |
| `fixingDayConvention` | STRING | 定盘日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestRateFixingScheduleDefinition` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createInterestRateFixingScheduleDefinition(
    "CAL_CFETS", "QUARTERLY", 1, "IN_ADVANCE", -1, "MODIFIED_PRECEDING", "IR_FLOAT_FIX", false)
```

#### createIborIndex

##### 语法

```dolphindb
caplib::createIborIndex(indexName STRING, indexTenor STRING, indexCcy STRING, calendarList STRING or STRING[], startDelay INT[, dayCount STRING[, interestDayConvention STRING[, dateRollConvention STRING[, iborType STRING]]]][, returnJson BOOL])
```

##### 详情

创建并缓存 IBOR 指数定义。 函数验证并转换字段，构造 `IborIndex` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `indexName` | STRING | 利率指数名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `indexTenor` | STRING | 利率指数期限。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `indexCcy` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `calendarList` | STRING or STRING[] | 业务日历名称列表。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `startDelay` | INT | 起息或交割延迟天数。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `dayCount` | STRING, optional | 日计数约定。 **有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 任何其他字符串均回退到函数指定的默认日计数。 |
| `interestDayConvention` | STRING, optional | 计息日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `dateRollConvention` | STRING, optional | 日期或日期数组。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DATE_ROLL_CONVENTION`, `EOM`, `FRN`, `IMM`, `IMM_CAD`, `IMM_AUD`, `IMM_NZD`, `SFE`, `NONE`, `TBILL`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `iborType` | STRING, optional | IBOR 指数类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`STANDARD_IBOR_INDEX`, `OVERNIGHT_INDEX`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IborIndex` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createIborIndex(
    "3M", "ACT_360", currency, 1, "CAL_CFETS",
    "MODIFIED_FOLLOWING", "NONE", "STANDARD_IBOR_INDEX",
    indexName, "IR_IBOR_INDEX", false)
```

#### createIrLegDefinition

##### 语法

```dolphindb
caplib::createIrLegDefinition(legType STRING, currency STRING, dayCount STRING, refIndex STRING, paymentDiscountMethod STRING, rateCalcMethod STRING, notionalExchange STRING, spread BOOL, fxConvert BOOL, fxReset BOOL, calendar STRING or STRING[], freq STRING, interestDayConvention STRING, stubPolicy STRING, brokenPeriodType STRING, payDayOffset INT, payDayConvention STRING, fixingCalendars STRING or STRING[], fixingFreq STRING, fixingDayConvention STRING, fixingMode STRING, fixingDayOffset INT, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存利率现金流腿定义。 函数验证并转换字段，构造 `InterestRateLegDefinition` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `legType` | STRING | 现金流腿类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_INTEREST_RATE_LEG_TYPE`, `FIXED_LEG`, `FLOATING_LEG`, `FRA_LEG`, `STRUCTURED_LEG`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 任何其他字符串均回退到函数指定的默认日计数。 |
| `refIndex` | STRING | 参考利率指数名称或句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `payDiscountMethod` | STRING | 支付现金流贴现方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_PAYMENT_DISCOUNT_METHOD`, `NO_DISCOUNT`, `DISCOUNT_AT_FLOATING_RATE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `interestCalcMethod` | STRING | 利息计算方法。 **有效性:** 旧版 16 参数签名要求 STRING 标量，但当前实现忽略此值。 |
| `interestRateCalcMethod` | STRING | 利率计算方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_INTEREST_RATE_CALCULATION_METHOD`, `STANDARD`, `COMPOUND_AVERAGE`, `ARITHMETIC_AVERAGE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `brokenRateCalcMethod` | STRING | 不规则期间利率计算方法。 **有效性:** 旧版 16 参数签名要求 STRING 标量，但当前实现忽略此值。 |
| `notionalExchange` | STRING | 是否交换名义本金。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_NOTIONAL_EXCHANGE`, `INITIAL_EXCHANGE`, `INTERMEDIATE_EXCHANGE`, `INITIAL_INTERMEDIATE_EXCHANGE`, `FINAL_EXCHANGE`, `INITIAL_FINAL_EXCHANGE`, `INTERMEDIATE_FINAL_EXCHANGE`, `INITIAL_INTERMEDIATE_FINAL_EXCHANGE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `isSpread` | BOOL | 是否将输入利率作为利差处理。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `isFxConvert` | BOOL | 是否进行外汇折算。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `isFxReset` | BOOL | 是否使用外汇重置。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `calcSched` | STRING | 计息计算日程对象或句柄。 **有效性:** 必须是相应日程定义的 ObjectCache 句柄；仅 fixingSched 可为空。 |
| `paySched` | STRING | 付款日程对象或句柄。 **有效性:** 必须是相应日程定义的 ObjectCache 句柄；仅 fixingSched 可为空。 |
| `fixingSched` | STRING | 定盘日程对象或句柄。 **有效性:** 必须是相应日程定义的 ObjectCache 句柄；仅 fixingSched 可为空。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestRateLegDefinition` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createIrLegDefinition(
    "FIXED_LEG", currency, "ACT_365_FIXED", "",
    "NO_DISCOUNT", "SIMPLE", "STANDARD", "CURRENT",
    "INVALID_NOTIONAL_EXCHANGE", 0, 0, 0,
    fixedCalcSchedule, fixedPaySchedule, "", "IR_FIXED_LEG", false)
```

#### createIrVanillaInstrumentTemplate

##### 语法

```dolphindb
caplib::createIrVanillaInstrumentTemplate(instType STRING, instName STRING, startConvention STRING, startDelay INT, legDefinitions STRING[], tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存标准利率工具模板。 函数验证并转换字段，构造 `InterestRateInstrumentTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instType` | STRING | 工具类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_INSTRUMENT_TYPE`, `DEPOSIT`, `FORWARD_RATE_AGREEMENT`, `IR_VANILLA_SWAP`, `OVERNIGHT_INDEX_SWAP`, `CROSS_CURRENCY_SWAP`, `MTM_CROSS_CURRENCY_SWAP`, `STD_CROSS_CURRENCY_SWAP`, `IR_BOND`, `NON_DELIVERABLE_SWAP`, `IR_EUROPEAN_SWAPTION`, `IR_CAP_FLOOR`, `IR_FUTURE`, `IR_FUTURE_IMM`, `IR_FUTURE_ASX`, `IR_VANILLA_BOND`, `IMM_FORWARD_RATE_AGREEMENT`, `IR_BOND_OPTION`, `IR_RANGEACCRUAL_SWAP`, `IR_STRUCTURED_SWAP`, `FX_SPOT`, `FX_FORWARD`, `FX_NON_DELIVERABLE_FORWARD`, `FX_SWAP`, `FX_SWAP_ON`, `FX_SWAP_TN`, `FX_EUROPEAN_OPTION`, `FX_TIME_OPTION`, `FX_DIGITAL_OPTION`, `FX_QUANTO_OPTION`, `FX_TOUCH_OPTION`, `FX_BARRIER_OPTION`, `FX_VANILLA_STRATEGY`, `FX_TOUCH_QUANTO_OPTION`, `FX_DIGITAL_QUANTO_OPTION`, `EQ_INDEX_FUTURE`, `EQ_EUROPEAN_OPTION`, `EQ_AMERICAN_OPTION`, `EQ_SPOT`, `EQ_VANILLA_OPTION`, `EQ_DIGITAL_OPTION`, `EQ_BARRIER_OPTION`, `EQ_RANGE_ACCRUAL_OPTION`, `EQ_TOUCH_OPTION`, `EQ_QUANTO_OPTION`, `CM_SPOT`, `CM_FUTURE`, `CM_EUROPEAN_OPTION`, `CM_AMERICAN_OPTION`, `CM_VANILLA_OPTION`, `CM_ASIAN_OPTION`, `CM_DIGITAL_OPTION`, `CM_SWAP`, `CM_DIGITAL_ASIAN_OPTION`, `PM_SPOT`, `PM_SWAP`, `CREDIT_DEFAULT_SWAP`, `SPOT`, `FUTURE`, `FORWARD`, `SWAP`, `EUROPEAN_OPTION`, `AMERICAN_OPTION`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `startConvention` | STRING | 工具起息约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_INSTRUMENT_START_CONVENTION`, `SPOTSTART`, `TODAYSTART`, `TOMORROWSTART`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `startDelay` | INT | 起息或交割延迟天数。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `legDefinitions` | STRING[] | 现金流腿定义对象或句柄数组。 **有效性:** 必须具有所列元素类型和形状；元素不得为空；除明确说明外包装器不强制非空。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestRateInstrumentTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createIrVanillaInstrumentTemplate(
    "IR_VANILLA_SWAP", curveName, "SPOTSTART", 1,
    [fixedLeg, floatingLeg], "IR_SWAP_TEMPLATE", false)
```

#### createIrVanillaSwapTemplate

##### 语法

```dolphindb
caplib::createIrVanillaSwapTemplate(instName STRING, startDelay INT or STRING, leg1Definition STRING, leg2Definition STRING, startConvention STRING[, returnJson BOOL])
```

##### 详情

创建并缓存标准利率互换模板。 函数验证并转换字段，构造 `InterestRateInstrumentTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `startDelay` | INT or STRING | 起息或交割延迟天数。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `leg1Definition` | STRING | 第一条现金流腿定义对象或句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `leg2Definition` | STRING | 第二条现金流腿定义对象或句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `startConvention` | STRING | 工具起息约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_INSTRUMENT_START_CONVENTION`, `SPOTSTART`, `TODAYSTART`, `TOMORROWSTART`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `InterestRateInstrumentTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createIrVanillaSwapTemplate(
    curveName, 1, fixedLeg[0], floatingLeg[0], "SPOTSTART", true)
```

#### createFlatIrYieldCurve

##### 语法

```dolphindb
caplib::createFlatIrYieldCurve(referenceDate DATE, currency STRING, rate DOUBLE, handle STRING[, returnJson BOOL])
```

##### 详情

创建零利率 IR 曲线，在整个期限范围应用同一连续复利年利率。 函数验证并转换字段，构造 `IrYieldCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `rate` | DOUBLE | 利率或票息率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `IrYieldCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFlatIrYieldCurve(asOfDate, "CNY", 0.02, "AN_FLAT_IR_CURVE", false)
```

### 外汇

#### calcFxForwardRate

##### 语法

```dolphindb
caplib::calcFxForwardRate(calculationDate DATE, leftCcy STRING, rightCcy STRING, deliveryDate DATE, fxSpotRateHandle STRING, domesticDiscountCurveHandle STRING, foreignDiscountCurveHandle STRING)
```

##### 详情

根据缓存现货报价以及本币和外币贴现曲线计算交割日 FX 远期汇率。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calculationDate` | DATE | 该计算使用的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `leftCcy` | STRING | 货币对的左侧币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `rightCcy` | STRING | 货币对的右侧币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `deliveryDate` | DATE | 该计算使用的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `fxSpotRateHandle` | STRING | FxSpotRate 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `domesticDiscountCurveHandle` | STRING | domestic IrYieldCurve 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `foreignDiscountCurveHandle` | STRING | foreign IrYieldCurve 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::calcFxForwardRate(
    asOfDate, "EUR", "USD", 2021.07.01, eurusdSpotRate[0], usdCurve, eurCurve)
```

#### calcFxSwapPoint

##### 语法

```dolphindb
caplib::calcFxSwapPoint(calculationDate DATE, leftCcy STRING, rightCcy STRING, deliveryDate DATE, fxSpotRateHandle STRING, domesticDiscountCurveHandle STRING, foreignDiscountCurveHandle STRING)
```

##### 详情

根据现货报价与两条贴现曲线隐含的远期相对现货调整计算交割日 FX 掉期点。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `calculationDate` | DATE | 该计算使用的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `leftCcy` | STRING | 货币对的左侧币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `rightCcy` | STRING | 货币对的右侧币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `deliveryDate` | DATE | 该计算使用的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `fxSpotRateHandle` | STRING | FxSpotRate 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `domesticDiscountCurveHandle` | STRING | domestic IrYieldCurve 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `foreignDiscountCurveHandle` | STRING | foreign IrYieldCurve 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::calcFxSwapPoint(
    asOfDate, "EUR", "USD", 2021.07.01, eurusdSpotRate[0], usdCurve, eurCurve)
```

#### calcFxPrice

##### 语法

```dolphindb
caplib::calcFxPrice(amount DOUBLE, currency STRING, destCcy STRING, fxRate DOUBLE, baseCcy STRING, targetCcy STRING)
```

##### 详情

按给定基础/目标币种 FX 汇率将金额转换为 destCcy，并返回转换金额。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `amount` | DOUBLE | 金额。 **有效性:** 必须为有限 DOUBLE；负值、零和正值均有效，可表示带符号的换算金额。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `destCcy` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `fxRate` | DOUBLE | 外汇汇率输入值。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `baseCcy` | STRING | 外汇或跨币种计算中的基准币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `targetCcy` | STRING | 外汇或跨币种计算中的目标币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::calcFxPrice(amount, currency, destCcy, fxRate, baseCcy, targetCcy)
```

#### calcFxAtmStrike

##### 语法

```dolphindb
caplib::calcFxAtmStrike(atmType STRING, expiryDate DATE, volSurfaceHandle STRING, fxSpotRateHandle STRING, domesticDiscountCurveHandle STRING, foreignDiscountCurveHandle STRING)
```

##### 详情

根据缓存 FX 波动率曲面、现货报价和两条贴现曲线计算到期日 atmType 执行价。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `atmType` | STRING | ATM 行权价约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_ATM_TYPE`, `ATM_FORWARD`, `ATM_DNS_PIPS`, `ATM_DNS_PERCENTAGE`, `ATM_SPOT`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `expiryDate` | DATE | 该计算使用的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `volSurfaceHandle` | STRING | FxVolatilitySurface 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `fxSpotRateHandle` | STRING | FxSpotRate 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `domesticDiscountCurveHandle` | STRING | domestic IrYieldCurve 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `foreignDiscountCurveHandle` | STRING | foreign IrYieldCurve 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::calcFxAtmStrike(
    "ATM_DNS_PIPS", 2021.09.26, builtVolSurface[0], eurusdSpotRate[0], usdCurve, eurCurve)
```

#### calcFxDeltaToStrike

##### 语法

```dolphindb
caplib::calcFxDeltaToStrike(deltaType STRING, delta DOUBLE, expiryDate DATE, volSurfaceHandle STRING, fxSpotRateHandle STRING, domesticDiscountCurveHandle STRING, foreignDiscountCurveHandle STRING)
```

##### 详情

反解所选 FX Delta 约定得到执行价；负 Delta 选择 PUT，非负 Delta 选择 CALL。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `deltaType` | STRING | 外汇 Delta 约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DELTA_TYPE`, `PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `delta` | DOUBLE | 带符号的期权 Delta；负值选择 PUT，非负值选择 CALL。 **有效性:** 必须为有限数，业务有效范围为 `(-1,0) ∪ (0,1)`；包装器仅检查 DOUBLE 类型。 |
| `expiryDate` | DATE | 该计算使用的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `volSurfaceHandle` | STRING | FxVolatilitySurface 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `fxSpotRateHandle` | STRING | FxSpotRate 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `domesticDiscountCurveHandle` | STRING | domestic IrYieldCurve 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `foreignDiscountCurveHandle` | STRING | foreign IrYieldCurve 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |

##### 返回值

**返回：** DOUBLE 数值。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::calcFxDeltaToStrike(
    "PIPS_SPOT_DELTA", 0.25, 2021.09.26, builtVolSurface[0], eurusdSpotRate[0], usdCurve, eurCurve)
```

#### createFxOptionQuoteMatrix

##### 语法

```dolphindb
caplib::createFxOptionQuoteMatrix(leftCcy STRING, rightCcy STRING, asOfDate DATE, terms STRING[], quoteNames STRING[], quotes DOUBLE matrix, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇期权报价矩阵。 函数验证并转换字段，构造 `FxOptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `leftCcy` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `rightCcy` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `terms` | STRING[] | 报价期限数组。 **有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `quoteNames` | STRING[] | 报价名称或微笑报价标签。 **有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `quotes` | DOUBLE matrix | 市场报价值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxOptionQuoteMatrix` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxOptionQuoteMatrix(
    "EUR", "USD", asOfDate, ["1W", "1M", "3M"], ["ATM", "D25_RR", "D25_BF"],
    matrix([0.05515, 0.06115, 0.06135], [-0.00290, -0.00248, -0.00180], [0.00135, 0.00147, 0.00205]),
    "EURUSD_OPTION_QUOTES", true)
```

#### createFlatFxVolatilitySurface

##### 语法

```dolphindb
caplib::createFlatFxVolatilitySurface(referenceDate DATE, currencyPair STRING, vol DOUBLE, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存平坦外汇波动率曲面。 函数验证并转换字段，构造 `FxVolatilitySurface` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `currencyPair` | STRING | 货币对标识，通常为基准币种/目标币种格式。 **有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。 |
| `vol` | DOUBLE | 波动率数值。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxVolatilitySurface` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFlatFxVolatilitySurface(
    asOfDate, "USDCNH", 0.0, "USDCNH_FLAT_FX_VOL_SURF", true)
```

#### createFxVolatilitySurface

##### 语法

```dolphindb
caplib::createFxVolatilitySurface(referenceDate DATE, leftCcy STRING, rightCcy STRING, termDates DATE[], strikes DOUBLE matrix/vector, volatilities DOUBLE matrix/vector, definitionHandle STRING, marketConventionsHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇波动率曲面。 函数验证并转换字段，构造 `FxVolatilitySurface` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `leftCcy` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `rightCcy` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `termDates` | DATE[] | 报价期限对应的到期日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `strikes` | DOUBLE matrix/vector | 行权价数组或矩阵。 **有效性:** 必须有限；价格型标的通常要求非负，利率型标的可为负。包装器仅检查类型/形状。 |
| `volatilities` | DOUBLE matrix/vector | 波动率数组或矩阵。 **有效性:** 必须具有所列元素类型和形状；数值必须非负且有限；除明确说明外包装器不强制非空。 |
| `definitionHandle` | STRING | 波动率曲面定义 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `marketConventionsHandle` | STRING | 市场惯例 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxVolatilitySurface` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxVolatilitySurface(
    asOfDate, "EUR", "USD", volTermDates, volStrikes, volValues,
    linearVolSurfDefinition[0], fxMktConventions[0], "EURUSD_VOL_SURF", true)
```

#### buildFxVolatilitySurface

##### 语法

```dolphindb
caplib::buildFxVolatilitySurface(referenceDate DATE, leftCcy STRING, rightCcy STRING, marketConventionsHandle STRING, quoteMatrixHandle STRING, spotRate DOUBLE, spotRefDate DATE, spotDate DATE, domesticDiscountCurveHandle STRING, foreignDiscountCurveHandle STRING, definitionHandle STRING, buildSettingsHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建外汇波动率曲面。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `FxVolatilitySurface`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 该计算使用的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `leftCcy` | STRING | 货币对的左侧币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `rightCcy` | STRING | 货币对的右侧币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `marketConventionsHandle` | STRING | FxMarketConventions 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `quoteMatrixHandle` | STRING | OptionQuoteMatrix 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `spotRate` | DOUBLE | 外汇即期汇率。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `spotRefDate` | DATE | 该计算使用的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `spotDate` | DATE | 该计算使用的日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `domesticDiscountCurveHandle` | STRING | domestic IrYieldCurve 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `foreignDiscountCurveHandle` | STRING | foreign IrYieldCurve 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `definitionHandle` | STRING | VolatilitySurfaceDefinition 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `buildSettingsHandle` | STRING | VolatilitySurfaceBuildSettings 的 ObjectCache 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 所构建曲面的 ObjectCache 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选返回形状标志。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxVolatilitySurface` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildFxVolatilitySurface(
    asOfDate, "EUR", "USD", fxMktConventions[0], optionQuotes[0],
    eurusdSpot, asOfDate, 2021.04.01, usdCurve, eurCurve,
    volSurfDefinition[0], "EURUSD_BUILT_VOL_SURF", true)
```

#### priceFxForward

##### 语法

```dolphindb
caplib::priceFxForward(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇远期工具。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxForward(
    fxForward, asOfDate, eurusdMktData[0], bsmSettings, fxRisk[0], "", "", true)
```

#### priceFxSwap

##### 语法

```dolphindb
caplib::priceFxSwap(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇掉期工具。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxSwap(
    fxSwap, asOfDate, eurusdMktData[0], cashAnalyticalSettings, fxRisk[0], "", "", true)
```

#### priceFxNonDeliverableForward

##### 语法

```dolphindb
caplib::priceFxNonDeliverableForward(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇无本金交割远期工具。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxNonDeliverableForward(
    fxNdf, asOfDate, usdcnhMktData[0], cashAnalyticalSettings, fxRisk[0], "", "", true)
```

#### priceFxTimeOption

##### 语法

```dolphindb
caplib::priceFxTimeOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇时间期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::priceFxTimeOption(instrumentHandle, pricingDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode)
```

#### priceFxEuropeanOption

##### 语法

```dolphindb
caplib::priceFxEuropeanOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇欧式期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxEuropeanOption(
    fxEuropean, asOfDate, eurusdMktData[0], bsmSettings, fxRisk[0], scnAnalysis, "", true)
```

#### priceFxAmericanOption

##### 语法

```dolphindb
caplib::priceFxAmericanOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇美式期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxAmericanOption(
    americanOption, asOfDate, eurusdMktData[0], bsmAnalyticalSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxAsianOption

##### 语法

```dolphindb
caplib::priceFxAsianOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇亚式期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxAsianOption(
    asianOption, asOfDate, eurusdMktData[0], bsmMcSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxDigitalOption

##### 语法

```dolphindb
caplib::priceFxDigitalOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇数字期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxDigitalOption(
    digitalOption, asOfDate, eurusdMktData[0], bsmAnalyticalSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxOneTouchOption

##### 语法

```dolphindb
caplib::priceFxOneTouchOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇单触碰期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxOneTouchOption(
    oneTouchOption, asOfDate, eurusdMktData[0], bsmAnalyticalSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxDoubleTouchOption

##### 语法

```dolphindb
caplib::priceFxDoubleTouchOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇双触碰期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxDoubleTouchOption(
    doubleTouchOption, asOfDate, eurusdMktData[0], bsmAnalyticalSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxSingleBarrierOption

##### 语法

```dolphindb
caplib::priceFxSingleBarrierOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇单障碍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxSingleBarrierOption(
    singleBarrierOption, asOfDate, eurusdMktData[0], bsmAnalyticalSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxDoubleBarrierOption

##### 语法

```dolphindb
caplib::priceFxDoubleBarrierOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇双障碍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxDoubleBarrierOption(
    doubleBarrierOption, asOfDate, eurusdMktData[0], bsmAnalyticalSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxSingleSharkFinOption

##### 语法

```dolphindb
caplib::priceFxSingleSharkFinOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇单鲨鱼鳍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxSingleSharkFinOption(
    singleSharkFinOption, asOfDate, eurusdMktData[0], bsmPdeSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxDoubleSharkFinOption

##### 语法

```dolphindb
caplib::priceFxDoubleSharkFinOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇双鲨鱼鳍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxDoubleSharkFinOption(
    doubleSharkFinOption, asOfDate, eurusdMktData[0], bsmPdeSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxPingPongOption

##### 语法

```dolphindb
caplib::priceFxPingPongOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇乒乓期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxPingPongOption(
    pingPongOption, asOfDate, eurusdMktData[0], bsmMcSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxAirbagOption

##### 语法

```dolphindb
caplib::priceFxAirbagOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇安全气囊期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxAirbagOption(
    airbagOption, asOfDate, eurusdMktData[0], bsmPdeSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxRangeAccrualOption

##### 语法

```dolphindb
caplib::priceFxRangeAccrualOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇区间累计期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceFxRangeAccrualOption(
    rangeAccrualOption, asOfDate, eurusdMktData[0], bsmAnalyticalSettings, fxOptionRisk[0], "", "", true)
```

#### priceFxPhoenixAutoCallableNote

##### 语法

```dolphindb
caplib::priceFxPhoenixAutoCallableNote(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇凤凰自动赎回票据。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::priceFxPhoenixAutoCallableNote(instrumentHandle, pricingDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode)
```

#### priceFxSnowballAutoCallableNote

##### 语法

```dolphindb
caplib::priceFxSnowballAutoCallableNote(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价外汇雪球自动赎回票据。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::priceFxSnowballAutoCallableNote(instrumentHandle, pricingDate, mktDataHandle, pricingSettingsHandle, riskSettingsHandle, scnSettingsHandle, mode)
```

#### createFxSpotTemplate

##### 语法

```dolphindb
caplib::createFxSpotTemplate(instName STRING, currencyPair STRING, spotDayConvention STRING, calendars STRING or STRING[], spotDelay STRING or INT[, handle STRING][, returnJson BOOL])
```

##### 详情

创建并缓存外汇即期模板。 函数验证并转换字段，构造 `FxSpotTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `currencyPair` | STRING | 货币对标识，通常为基准币种/目标币种格式。 **有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。 |
| `spotDayConvention` | STRING | 即期日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `calendars` | STRING or STRING[] | 日期调整使用的业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `spotDelay` | STRING or INT | 即期结算延迟。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxSpotTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxSpotTemplate(
    "EURUSD_SPOT_TPL", "EURUSD", "FOLLOWING", [calEuta, calGblo], "2d", true)
```

#### createFxSpotRate

##### 语法

```dolphindb
caplib::createFxSpotRate(value DOUBLE, baseCurrency STRING, targetCurrency STRING, refDate DATE, spotDate DATE, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇即期汇率。 函数验证并转换字段，构造 `FxSpotRate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `value` | DOUBLE | 报价、利率或即期汇率数值。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `baseCurrency` | STRING | 外汇货币对中的基准币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `targetCurrency` | STRING | 外汇货币对中的目标币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `refDate` | DATE | 参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `spotDate` | DATE | 即期结算日。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxSpotRate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxSpotRate(
    eurusdSpot, "EUR", "USD", asOfDate, 2021.04.01, "EURUSD_SPOT_RATE", true)
```

#### createFxForwardTemplate

##### 语法

```dolphindb
caplib::createFxForwardTemplate(instName STRING, fixingOffset STRING or INT, currencyPair STRING, deliveryDayConvention STRING, fixingDayConvention STRING, calendars STRING or STRING[][, returnJson BOOL])
```

##### 详情

创建并缓存外汇远期模板。 函数验证并转换字段，构造 `FxForwardTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `fixingOffset` | STRING or INT | 定盘偏移期限。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `currencyPair` | STRING | 货币对标识，通常为基准币种/目标币种格式。 **有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。 |
| `deliveryDayConvention` | STRING | 交割日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fixingDayConvention` | STRING | 定盘日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `calendars` | STRING or STRING[] | 日期调整使用的业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxForwardTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxForwardTemplate(
    "EURUSD_FWD_TPL", "-2d", "EURUSD", "FOLLOWING", "PRECEDING", [calEuta, calGblo], true)
```

#### createFxSwapTemplate

##### 语法

```dolphindb
caplib::createFxSwapTemplate(instName STRING, startConvention STRING, currencyPair STRING, calendars STRING or STRING[], startDayConvention STRING, endDayConvention STRING, fixingOffset STRING or INT, fixingDayConvention STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇掉期模板。 函数验证并转换字段，构造 `FxSwapTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `startConvention` | STRING | 工具起息约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_INSTRUMENT_START_CONVENTION`, `SPOTSTART`, `TODAYSTART`, `TOMORROWSTART`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `currencyPair` | STRING | 货币对标识，通常为基准币种/目标币种格式。 **有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。 |
| `calendars` | STRING or STRING[] | 日期调整使用的业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `startDayConvention` | STRING | 起始日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `endDayConvention` | STRING | 结束日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fixingOffset` | STRING or INT | 定盘偏移期限。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `fixingDayConvention` | STRING | 定盘日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxSwapTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxSwapTemplate(
    "EURUSD_SWP_TPL", "SPOTSTART", "EURUSD", [calEuta, calGblo],
    "FOLLOWING", "FOLLOWING", "-2d", "PRECEDING", true)
```

#### createFxNdfTemplate

##### 语法

```dolphindb
caplib::createFxNdfTemplate(instName STRING, fixingOffset STRING or INT, currencyPair STRING, deliveryDayConvention STRING, fixingDayConvention STRING, calendars STRING or STRING[], settlementCurrency STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇无本金交割远期模板。 函数验证并转换字段，构造 `FxNdfTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `fixingOffset` | STRING or INT | 定盘偏移期限。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `currencyPair` | STRING | 货币对标识，通常为基准币种/目标币种格式。 **有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。 |
| `deliveryDayConvention` | STRING | 交割日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fixingDayConvention` | STRING | 定盘日调整约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_BUSINESS_DAY_CONVENTION`, `FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `calendars` | STRING or STRING[] | 日期调整使用的业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `settlementCurrency` | STRING | 结算币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxNdfTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxNdfTemplate(
    "USDCNH_NDF_TPL", "-2d", "USDCNH", "FOLLOWING", "PRECEDING",
    [calHkhk, calGblo], "USD", true)
```

#### createFxForward

##### 语法

```dolphindb
caplib::createFxForward(buyCurrency STRING, buyAmount DOUBLE, sellCurrency STRING, sellAmount DOUBLE, deliveryDate DATE, expiryDate DATE, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇远期工具。 函数验证并转换字段，构造 `FxForward` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `buyCurrency` | STRING | 买入币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `buyAmount` | DOUBLE | 买入金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `sellCurrency` | STRING | 卖出币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `sellAmount` | DOUBLE | 卖出金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `deliveryDate` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `expiryDate` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxForward` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxForward(
    "EUR", 1000000.0, "USD", 1176100.0,
    2021.07.01, 2021.06.30, "FX_FWD", false)
```

#### createFxSwap

##### 语法

```dolphindb
caplib::createFxSwap(nearBuyCurrency STRING, nearBuyAmount DOUBLE, nearSellCurrency STRING, nearSellAmount DOUBLE, nearDeliveryDate DATE, nearExpiryDate DATE, farBuyCurrency STRING, farBuyAmount DOUBLE, farSellCurrency STRING, farSellAmount DOUBLE, farDeliveryDate DATE, farExpiryDate DATE, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇掉期工具。 函数验证并转换字段，构造 `FxSwap` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `nearBuyCurrency` | STRING | 近端买入币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `nearBuyAmount` | DOUBLE | 近端买入金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `nearSellCurrency` | STRING | 近端卖出币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `nearSellAmount` | DOUBLE | 近端卖出金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `nearDeliveryDate` | DATE | 日期或日期数组。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |
| `nearExpiryDate` | DATE | 日期或日期数组。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |
| `farBuyCurrency` | STRING | 远端买入币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `farBuyAmount` | DOUBLE | 远端买入金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `farSellCurrency` | STRING | 远端卖出币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `farSellAmount` | DOUBLE | 远端卖出金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `farDeliveryDate` | DATE | 日期或日期数组。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |
| `farExpiryDate` | DATE | 日期或日期数组。 **有效性:** 必须是非空 DolphinDB DATE 标量。必须满足函数所述的业务日期关系；包装器不检查先后顺序。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxSwap` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxSwap(
    "EUR", 1000000.0, "USD", 1176100.0, 2021.04.01, 2021.03.31,
    "USD", 1000000.0, "EUR", 1176100.0, 2021.07.01, 2021.06.30,
    "FX_SWAP_INST", false)
```

#### createFxNonDeliverableForward

##### 语法

```dolphindb
caplib::createFxNonDeliverableForward(buyCurrency STRING, buyAmount DOUBLE, sellCurrency STRING, sellAmount DOUBLE, settlementCurrency STRING, deliveryDate DATE, expiryDate DATE, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇无本金交割远期工具。 函数验证并转换字段，构造 `FxNonDeliverableForward` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `buyCurrency` | STRING | 买入币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `buyAmount` | DOUBLE | 买入金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `sellCurrency` | STRING | 卖出币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `sellAmount` | DOUBLE | 卖出金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `settlementCurrency` | STRING | 结算币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `deliveryDate` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `expiryDate` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxNonDeliverableForward` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxNonDeliverableForward(
    "USD", 10000.0, "CNH", 66916.0, "USD",
    2021.07.01, 2021.06.30, "FX_NDF_INST", false)
```

#### createFxMktConventions

##### 语法

```dolphindb
caplib::createFxMktConventions(ccyPair STRING, atmType STRING, shortDeltaType STRING, longDeltaType STRING, deltaCutoff STRING, riskReversal STRING, smileQuoteType STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇市场惯例。 函数验证并转换字段，构造 `FxMarketConventions` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `ccyPair` | STRING | 货币对标识。 **有效性:** 必须标识两个非空且不同的币种；包装器不验证 ISO 代码。 |
| `atmType` | STRING | ATM 报价类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_ATM_TYPE`, `ATM_FORWARD`, `ATM_DNS_PIPS`, `ATM_DNS_PERCENTAGE`, `ATM_SPOT`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `shortDeltaType` | STRING | 短期限 Delta 报价类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DELTA_TYPE`, `PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `longDeltaType` | STRING | 长期限 Delta 报价类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DELTA_TYPE`, `PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `deltaCutoff` | STRING | Delta 报价切换阈值。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DELTA_TYPE`, `PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `riskReversal` | STRING | 设置对象的缓存句柄或配置值。 **有效性:** 值必须是以下完整 protobuf 标签之一：`RR_CALL_PUT`, `RR_PUT_CALL`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `smileQuoteType` | STRING | 波动率微笑报价类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`BUTTERFLY_QUOTE`, `MARKET_STRANGLE_QUOTE`, `WINGS_RATIO_BF_QUOTE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxMarketConventions` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxMktConventions(
    underlying, "ATM_DNS_PIPS", "PIPS_SPOT_DELTA", "PIPS_FORWARD_DELTA",
    "1Y", "RR_CALL_PUT", "BUTTERFLY_QUOTE", "EURUSD_MKT_CONV", true)
```

#### createFxMktDataSet

##### 语法

```dolphindb
caplib::createFxMktDataSet(asOfDate DATE, domDiscountCurve STRING, forDiscountCurve STRING, spot STRING, volSurface STRING, name STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇市场数据集。 函数验证并转换字段，构造 `FxMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `domDiscountCurve` | STRING | 本币贴现曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `forDiscountCurve` | STRING | 外币贴现曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `spot` | STRING | 当前现货价格。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `volSurface` | STRING | 波动率曲面 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxMktDataSet` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxMktDataSet(
    asOfDate, usdCurve, eurCurve, eurusdSpotRate[0], volSurface[0], "", "EURUSD_MKT", true)
```

#### createFxRiskSettings

##### 语法

```dolphindb
caplib::createFxRiskSettings(irCurveSettings STRING, priceSettings STRING, volSettings STRING, priceVolSettings STRING, thetaSettings STRING, name STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存外汇风险设置。 函数验证并转换字段，构造 `FxRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `irCurveSettings` | STRING | 利率曲线风险设置 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `priceSettings` | STRING | 价格风险设置 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `volSettings` | STRING | 波动率风险设置 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `priceVolSettings` | STRING | 价格-波动率联合风险设置 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `thetaSettings` | STRING | 设置对象的缓存句柄或配置值。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `FxRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFxRiskSettings(
    irCurveRisk, priceRisk, volRisk, priceVolRisk, thetaRisk, "", "FX_RISK", true)
```

### 权益

#### buildEqIndexDividendCurve

##### 语法

```dolphindb
caplib::buildEqIndexDividendCurve(asOfDate DATE, termDates DATE[], futurePrices DOUBLE[], optionPrices TABLE, spot DOUBLE, discountCurveHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建股指股息收益率曲线。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `DividendCurve`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `termDates` | DATE[] | 报价期限对应的到期日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `futurePrices` | DOUBLE[] | 期货价格数组。 **有效性:** 所有元素必须有限并与配对日期等长；通常应为正，但可出现负价格的市场由下游业务规则决定。 |
| `optionPrices` | TABLE | 期权价格矩阵或表。 **有效性:** 所有元素必须非负且有限，并与配对行权价/期限参数形状一致；包装器主要检查类型/形状。 |
| `spot` | DOUBLE | 当前现货价格。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `DividendCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildEqIndexDividendCurve(
    asOfDate, quoteTermDates, emptyFuturePrices, idxOptionPrices,
    underlyingPrice, irCurve, "IDX_DIV_CURVE", true)
```

#### buildEqVolatilitySurface

##### 语法

```dolphindb
caplib::buildEqVolatilitySurface(referenceDate DATE, underlying STRING, definitionHandle STRING, quoteMatrixHandle STRING, underlyingPrices DOUBLE[], discountCurveHandle STRING, dividendCurveHandle STRING, buildSettingsHandle STRING, pricingSettingsHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建权益波动率曲面。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `VolatilitySurface`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `definitionHandle` | STRING | 波动率曲面定义 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `quoteMatrixHandle` | STRING | 期权报价矩阵 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `underlyingPrices` | DOUBLE[] | 与报价期限或校准行对齐的标的价格数组。 **有效性:** 所有元素必须有限并与配对日期等长；通常应为正，但可出现负价格的市场由下游业务规则决定。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `dividendCurveHandle` | STRING | 股息曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `buildSettingsHandle` | STRING | 构建设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolatilitySurface` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildEqVolatilitySurface(
    asOfDate, underlying, volDef[0], quoteMatrix[0],
    [2.958, 2.960, 2.962],
    irCurve, divCurve, volBuildSettings[0], bsmSettings, "EQ_VOL_SURFACE", true)
```

#### createEqOptionQuoteMatrix

##### 语法

```dolphindb
caplib::createEqOptionQuoteMatrix(exerciseType STRING, underlyingType STRING, asOfDate DATE, termDates DATE[], payoffTypes STRING matrix/vector, optionPrices DOUBLE matrix/vector, optionStrikes DOUBLE matrix/vector, underlying STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存权益期权报价矩阵。 函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `exerciseType` | STRING | 期权行权风格。 **有效性:** 值必须是以下完整 protobuf 标签之一：`EUROPEAN`, `AMERICAN`, `BERMUDAN`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 值必须是以下完整 protobuf 标签之一：`SPOT_UNDERLYING_TYPE`, `FUTURE_UNDERLYING_TYPE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `termDates` | DATE[] | 报价期限对应的到期日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `payoffTypes` | STRING matrix/vector | 与报价值对齐的收益类型矩阵或向量。 **有效性:** 每个元素必须是以下完整 protobuf 标签之一：`CALL`, `PUT`, `STRADDLE`, `STRANGLE`, `RISK_REVERSAL`, `BUTTERFLY`, `ATM_STRADDLE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `optionPrices` | DOUBLE matrix/vector | 期权价格矩阵或表。 **有效性:** 所有元素必须非负且有限，并与配对行权价/期限参数形状一致；包装器主要检查类型/形状。 |
| `optionStrikes` | DOUBLE matrix/vector | 期权行权价矩阵或向量。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `OptionQuoteMatrix` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

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

##### 语法

```dolphindb
caplib::priceEqEuropeanOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益欧式期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqEuropeanOption(
    europeanOption, asOfDate, mktData[0], bsmSettings, eqRisk[0], "", "", true)
```

#### createEqMktDataSet

##### 语法

```dolphindb
caplib::createEqMktDataSet(asOfDate DATE, underlying STRING, underlyingPrice DOUBLE, dcHandle STRING, divHandle STRING, volHandle STRING, quantoDcHandle STRING, quantoFxVolHandle STRING, quantoCorrelation DOUBLE, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存权益市场数据集。 函数验证并转换字段，构造 `EqMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `underlyingPrice` | DOUBLE | 当前标的价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `dcHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `divHandle` | STRING | 股息曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `volHandle` | STRING | 波动率设置或曲面 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `quantoDcHandle` | STRING | Quanto 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `quantoFxVolHandle` | STRING | Quanto 外汇波动率曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `quantoCorrelation` | DOUBLE | Quanto 调整相关系数。 **有效性:** 必须有限且业务有效范围为 `[-1,1]`；包装器仅检查类型。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `EqMktDataSet` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createEqMktDataSet(
    asOfDate, underlying, underlyingPrice, irCurve, divCurve, volSurface[0], "", "", 0.0, "EQ_MKT", true)
```

#### createEqRiskSettings

##### 语法

```dolphindb
caplib::createEqRiskSettings(irDelta BOOL, priceDelta BOOL, volVega BOOL, theta BOOL, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存权益风险设置。 函数验证并转换字段，构造 `EqRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `irDelta` | BOOL | 是否计算利率 Delta 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `priceDelta` | BOOL | 是否计算标的价格 Delta 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `volVega` | BOOL | 是否计算波动率 Vega 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `theta` | BOOL | 是否计算 Theta 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `EqRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createEqRiskSettings(1, 1, 1, 1, "EQ_RISK", true)
```

#### createEuropeanOption

##### 语法

```dolphindb
caplib::createEuropeanOption(payoffType STRING, strike DOUBLE, expiry DATE, delivery DATE, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存欧式期权。 函数验证并转换字段，构造 `EuropeanOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `payoffType` | STRING | 收益类型，例如 CALL 或 PUT。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `strike` | DOUBLE | 行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `EuropeanOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createEuropeanOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    1000000.0, currency, "SPOT", currency, underlying, "EQ_EO", false)
```

#### createAmericanOption

##### 语法

```dolphindb
caplib::createAmericanOption(payoffType STRING, strike DOUBLE, expiry DATE, delivery DATE, settlementDays INT, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存美式期权。 函数验证并转换字段，构造 `AmericanOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `payoffType` | STRING | 收益类型，例如 CALL 或 PUT。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `strike` | DOUBLE | 行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `AmericanOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createAmericanOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20, 1,
    1000000.0, currency, "FUTURE", currency, underlying, "CM_AM_INST", false)
```

#### createDigitalOption

##### 语法

```dolphindb
caplib::createDigitalOption(payoffType STRING, strike DOUBLE, expiry DATE, delivery DATE, cash DOUBLE, asset DOUBLE, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存数字期权。 函数验证并转换字段，构造 `DigitalOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `payoffType` | STRING | 收益类型，例如 CALL 或 PUT。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `strike` | DOUBLE | 行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `cash` | DOUBLE | 现金收益或现金返还金额。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `asset` | DOUBLE | 资产收益或资产返还金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `DigitalOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createDigitalOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    0.0, 1.0, 1000000.0, currency, "FUTURE", currency, underlying, "CM_DG_INST", false)
```

#### createAsianOption

##### 语法

```dolphindb
caplib::createAsianOption(payoffType STRING, strike DOUBLE, expiry DATE, delivery DATE, strikeType STRING, avgMethod STRING, obsType STRING, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, fixingDates DATE[], fixingValues DOUBLE[], fixingWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存亚式期权。 函数验证并转换字段，构造 `AsianOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `payoffType` | STRING | 收益类型，例如 CALL 或 PUT。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `strike` | DOUBLE | 行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `strikeType` | STRING | 行权价类型。 **有效性:** 可接受值：`FIXED`, `FIXED_STRIKE`, `FLOATING`, `FLOATING_STRIKE`。仅接受所示精确拼写。 |
| `avgMethod` | STRING | 平均价格或平均观察值计算方法。 **有效性:** 可接受值：``, `ARITHMETIC`, `ARITHMETIC_AVERAGE_METHOD`, `GEOMETRIC`, `GEOMETRIC_AVERAGE_METHOD`。仅接受所示精确拼写。 |
| `obsType` | STRING | 观察方式。 **有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `fixingValues` | DOUBLE[] | 与观察日期对齐的定盘值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `fixingWeights` | DOUBLE[] | 观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `AsianOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createAsianOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    "FIXED_STRIKE", "ARITHMETIC_AVERAGE_METHOD", "DISCRETE_OBSERVATION_TYPE",
    1000000.0, "SPOT", currency, underlying, "EQ_ASIAN",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createOneTouchOption

##### 语法

```dolphindb
caplib::createOneTouchOption(expiry DATE, delivery DATE, barrierType STRING, barrierValue DOUBLE, barrierObsType STRING, paymentType STRING, cash DOUBLE, asset DOUBLE, settlementDays INT, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, fixingDates DATE[], fixingValues DOUBLE[], fixingWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存单触碰期权。 函数验证并转换字段，构造 `OneTouchOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `barrierType` | STRING | 障碍方向或类型枚举。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `barrierValue` | DOUBLE | 障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `barrierObsType` | STRING | 障碍观察约定。 **有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。 |
| `paymentType` | STRING | 返还或障碍支付时点类型。 **有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。 |
| `cash` | DOUBLE | 现金收益或现金返还金额。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `asset` | DOUBLE | 资产收益或资产返还金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `fixingValues` | DOUBLE[] | 与观察日期对齐的定盘值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `fixingWeights` | DOUBLE[] | 观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `OneTouchOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createOneTouchOption(
    2020.08.19, 2020.08.20, "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    1.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_OT_INST", false)
```

#### createDoubleTouchOption

##### 语法

```dolphindb
caplib::createDoubleTouchOption(expiry DATE, delivery DATE, lowerBarrierType STRING, lowerBarrierValue DOUBLE, upperBarrierType STRING, upperBarrierValue DOUBLE, barrierObsType STRING, paymentType STRING, cash DOUBLE, asset DOUBLE, settlementDays INT, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, fixingDates DATE[], fixingValues DOUBLE[], fixingWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存双触碰期权。 函数验证并转换字段，构造 `DoubleTouchOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `lowerBarrierType` | STRING | 下障碍类型。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `lowerBarrierValue` | DOUBLE | 下障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `upperBarrierType` | STRING | 上障碍类型。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `upperBarrierValue` | DOUBLE | 上障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `barrierObsType` | STRING | 障碍观察约定。 **有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。 |
| `paymentType` | STRING | 返还或障碍支付时点类型。 **有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。 |
| `cash` | DOUBLE | 现金收益或现金返还金额。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `asset` | DOUBLE | 资产收益或资产返还金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `fixingValues` | DOUBLE[] | 与观察日期对齐的定盘值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `fixingWeights` | DOUBLE[] | 观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `DoubleTouchOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createDoubleTouchOption(
    2020.08.19, 2020.08.20, "DOWN_IN", underlyingPrice * 0.95,
    "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    1.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_DT_INST", false)
```

#### createSingleBarrierOption

##### 语法

```dolphindb
caplib::createSingleBarrierOption(payoffType STRING, strike DOUBLE, expiry DATE, delivery DATE, barrierType STRING, barrierValue DOUBLE, barrierObsType STRING, paymentType STRING, cashRebate DOUBLE, assetRebate DOUBLE, settlementDays INT, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, fixingDates DATE[], fixingValues DOUBLE[], fixingWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存单障碍期权。 函数验证并转换字段，构造 `SingleBarrierOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `payoffType` | STRING | 收益类型，例如 CALL 或 PUT。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `strike` | DOUBLE | 行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `barrierType` | STRING | 障碍方向或类型枚举。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `barrierValue` | DOUBLE | 障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `barrierObsType` | STRING | 障碍观察约定。 **有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。 |
| `paymentType` | STRING | 返还或障碍支付时点类型。 **有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。 |
| `cashRebate` | DOUBLE | 现金返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `assetRebate` | DOUBLE | 资产返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `fixingValues` | DOUBLE[] | 与观察日期对齐的定盘值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `fixingWeights` | DOUBLE[] | 观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `SingleBarrierOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createSingleBarrierOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_SB_INST", false)
```

#### createDoubleBarrierOption

##### 语法

```dolphindb
caplib::createDoubleBarrierOption(payoffType STRING, strike DOUBLE, expiry DATE, delivery DATE, lowerBarrierType STRING, lowerBarrierValue DOUBLE, upperBarrierType STRING, upperBarrierValue DOUBLE, barrierObsType STRING, paymentType STRING, lowerCashRebate DOUBLE, lowerAssetRebate DOUBLE, upperCashRebate DOUBLE, upperAssetRebate DOUBLE, settlementDays INT, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, fixingDates DATE[], fixingValues DOUBLE[], fixingWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存双障碍期权。 函数验证并转换字段，构造 `DoubleBarrierOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `payoffType` | STRING | 收益类型，例如 CALL 或 PUT。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `strike` | DOUBLE | 行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `lowerBarrierType` | STRING | 下障碍类型。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `lowerBarrierValue` | DOUBLE | 下障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `upperBarrierType` | STRING | 上障碍类型。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `upperBarrierValue` | DOUBLE | 上障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `barrierObsType` | STRING | 障碍观察约定。 **有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。 |
| `paymentType` | STRING | 返还或障碍支付时点类型。 **有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。 |
| `lowerCashRebate` | DOUBLE | 下障碍现金返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `lowerAssetRebate` | DOUBLE | 下障碍资产返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `upperCashRebate` | DOUBLE | 上障碍现金返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `upperAssetRebate` | DOUBLE | 上障碍资产返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `fixingValues` | DOUBLE[] | 与观察日期对齐的定盘值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `fixingWeights` | DOUBLE[] | 观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `DoubleBarrierOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createDoubleBarrierOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20,
    "DOWN_IN", underlyingPrice * 0.95, "UP_IN", underlyingPrice * 1.05,
    "CONTINUOUS_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 0.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_DB_INST", false)
```

#### createCollarOption

##### 语法

```dolphindb
caplib::createCollarOption(payoffType STRING, lowerGearing DOUBLE, upperGearing DOUBLE, lowerStrike DOUBLE, upperStrike DOUBLE, expiry DATE, delivery DATE, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存领口期权。 函数验证并转换字段，构造 `CollarOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `payoffType` | STRING | 收益类型，例如 CALL 或 PUT。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `lowerGearing` | DOUBLE | 下行收益杠杆。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `upperGearing` | DOUBLE | 上行收益杠杆。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `lowerStrike` | DOUBLE | 下行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `upperStrike` | DOUBLE | 上行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CollarOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createCollarOption(payoffType, lowerGearing, upperGearing, lowerStrike, upperStrike, expiry, delivery, nominal, payoffCurrency, underlyingType, underlyingCurrency, underlying, handle)
```

#### createSingleSharkFinOption

##### 语法

```dolphindb
caplib::createSingleSharkFinOption(payoffType STRING, strike DOUBLE, expiry DATE, delivery DATE, gearing DOUBLE, performanceType STRING, barrierType STRING, barrierValue DOUBLE, barrierObsType STRING, paymentType STRING, cashRebate DOUBLE, assetRebate DOUBLE, settlementDays INT, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, fixingDates DATE[], fixingValues DOUBLE[], fixingWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存单鲨鱼鳍期权。 函数验证并转换字段，构造 `SingleSharkFinOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `payoffType` | STRING | 收益类型，例如 CALL 或 PUT。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `strike` | DOUBLE | 行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `gearing` | DOUBLE | 收益杠杆。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `performanceType` | STRING | 收益表现计算类型。 **有效性:** 可接受值：``, `RELATIVE`, `RELATIVE_PERFORM_TYPE`, `ABSOLUTE`, `ABSOLUTE_PERFORM_TYPE`。仅接受所示精确拼写。 |
| `barrierType` | STRING | 障碍方向或类型枚举。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `barrierValue` | DOUBLE | 障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `barrierObsType` | STRING | 障碍观察约定。 **有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。 |
| `paymentType` | STRING | 返还或障碍支付时点类型。 **有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。 |
| `cashRebate` | DOUBLE | 现金返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `assetRebate` | DOUBLE | 资产返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `fixingValues` | DOUBLE[] | 与观察日期对齐的定盘值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `fixingWeights` | DOUBLE[] | 观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `SingleSharkFinOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createSingleSharkFinOption(
    "CALL", underlyingPrice, 2020.08.19, 2020.08.20, 1.0,
    "RELATIVE_PERFORM_TYPE", "UP_OUT", underlyingPrice * 1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_SF_INST",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createDoubleSharkFinOption

##### 语法

```dolphindb
caplib::createDoubleSharkFinOption(lowerStrike DOUBLE, upperStrike DOUBLE, expiry DATE, delivery DATE, lowerParticipation DOUBLE, upperParticipation DOUBLE, performanceType STRING, lowerBarrier DOUBLE, upperBarrier DOUBLE, barrierObsType STRING, paymentType STRING, lowerCashRebate DOUBLE, lowerAssetRebate DOUBLE, upperCashRebate DOUBLE, upperAssetRebate DOUBLE, settlementDays INT, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, fixingDates DATE[], fixingValues DOUBLE[], fixingWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存双鲨鱼鳍期权。 函数验证并转换字段，构造 `DoubleSharkFinOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `lowerStrike` | DOUBLE | 下行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `upperStrike` | DOUBLE | 上行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `lowerParticipation` | DOUBLE | 下行参与率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `upperParticipation` | DOUBLE | 上行参与率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `performanceType` | STRING | 收益表现计算类型。 **有效性:** 可接受值：``, `RELATIVE`, `RELATIVE_PERFORM_TYPE`, `ABSOLUTE`, `ABSOLUTE_PERFORM_TYPE`。仅接受所示精确拼写。 |
| `lowerBarrier` | DOUBLE | 下障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `upperBarrier` | DOUBLE | 上障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `barrierObsType` | STRING | 障碍观察约定。 **有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。 |
| `paymentType` | STRING | 返还或障碍支付时点类型。 **有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。 |
| `lowerCashRebate` | DOUBLE | 下障碍现金返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `lowerAssetRebate` | DOUBLE | 下障碍资产返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `upperCashRebate` | DOUBLE | 上障碍现金返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `upperAssetRebate` | DOUBLE | 上障碍资产返还金额。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `fixingValues` | DOUBLE[] | 与观察日期对齐的定盘值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `fixingWeights` | DOUBLE[] | 观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `DoubleSharkFinOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createDoubleSharkFinOption(
    underlyingPrice, underlyingPrice, 2020.08.19, 2020.08.20, 1.0, 1.0,
    "ABSOLUTE_PERFORM_TYPE", underlyingPrice * 0.95, underlyingPrice * 1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.0, 0.0, 0.0, 0.0, 1, 1000000.0,
    currency, "FUTURE", currency, underlying, "CM_DS_INST",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createRangeAccrualOption

##### 语法

```dolphindb
caplib::createRangeAccrualOption(expiry DATE, delivery DATE, asset DOUBLE, cash DOUBLE, lowerBarrier DOUBLE, upperBarrier DOUBLE, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, fixingDates DATE[], fixingValues DOUBLE[], fixingWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存区间累计期权。 函数验证并转换字段，构造 `RangeAccrualOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `asset` | DOUBLE | 资产收益或资产返还金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `cash` | DOUBLE | 现金收益或现金返还金额。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `lowerBarrier` | DOUBLE | 下障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `upperBarrier` | DOUBLE | 上障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `fixingValues` | DOUBLE[] | 与观察日期对齐的定盘值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `fixingWeights` | DOUBLE[] | 观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `RangeAccrualOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createRangeAccrualOption(
    2020.08.19, 2020.08.20, 0.0, 0.01,
    underlyingPrice * 0.95, underlyingPrice * 1.05,
    1000000.0, currency, "FUTURE", currency, underlying, "CM_RA_INST",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createAirbagOption

##### 语法

```dolphindb
caplib::createAirbagOption(payoffType STRING, expiry DATE, delivery DATE, lowerStrike DOUBLE, upperStrike DOUBLE, lowerGearing DOUBLE, upperGearing DOUBLE, knockInStrike DOUBLE, barrierType STRING, barrierValue DOUBLE, barrierObsType STRING, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, fixingDates DATE[], fixingValues DOUBLE[], fixingWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存安全气囊期权。 函数验证并转换字段，构造 `AirbagOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `payoffType` | STRING | 收益类型，例如 CALL 或 PUT。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `lowerStrike` | DOUBLE | 下行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `upperStrike` | DOUBLE | 上行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `lowerGearing` | DOUBLE | 下行收益杠杆。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `upperGearing` | DOUBLE | 上行收益杠杆。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `knockInStrike` | DOUBLE | 敲入后使用的行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `barrierType` | STRING | 障碍方向或类型枚举。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `barrierValue` | DOUBLE | 障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `barrierObsType` | STRING | 障碍观察约定。 **有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `fixingValues` | DOUBLE[] | 与观察日期对齐的定盘值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `fixingWeights` | DOUBLE[] | 观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `AirbagOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createAirbagOption(
    "CALL", 2020.08.19, 2020.08.20,
    underlyingPrice, underlyingPrice * 1.05, 1.0, 1.0, underlyingPrice,
    "DOWN_IN", underlyingPrice * 0.8, "DISCRETE_OBSERVATION_TYPE",
    1000000.0, currency, "FUTURE", currency, underlying, "CM_AB_INST",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createPingPongOption

##### 语法

```dolphindb
caplib::createPingPongOption(expiry DATE, delivery DATE, lowerBarrierType STRING, lowerBarrierValue DOUBLE, upperBarrierType STRING, upperBarrierValue DOUBLE, barrierObsType STRING, paymentType STRING, cash DOUBLE, asset DOUBLE, settlementDays INT, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, fixingDates DATE[], fixingValues DOUBLE[], fixingWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存乒乓期权。 函数验证并转换字段，构造 `PingPongOption` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `lowerBarrierType` | STRING | 下障碍类型。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `lowerBarrierValue` | DOUBLE | 下障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `upperBarrierType` | STRING | 上障碍类型。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `upperBarrierValue` | DOUBLE | 上障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `barrierObsType` | STRING | 障碍观察约定。 **有效性:** 可接受值：``, `CONTINUOUS`, `CONTINUOUS_OBSERVATION_TYPE`, `DISCRETE`, `DISCRETE_OBSERVATION_TYPE`。仅接受所示精确拼写。 |
| `paymentType` | STRING | 返还或障碍支付时点类型。 **有效性:** 可接受值：``, `PAY_AT_HIT`, `PAH`, `PAY_AT_MATURITY`, `PAM`。仅接受所示精确拼写。 |
| `cash` | DOUBLE | 现金收益或现金返还金额。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `asset` | DOUBLE | 资产收益或资产返还金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `fixingDates` | DATE[] | 观察或定盘日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `fixingValues` | DOUBLE[] | 与观察日期对齐的定盘值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `fixingWeights` | DOUBLE[] | 观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PingPongOption` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createPingPongOption(
    2020.08.19, 2020.08.20, "DOWN_IN", underlyingPrice * 0.95,
    "UP_IN", underlyingPrice * 1.05,
    "DISCRETE_OBSERVATION_TYPE", "PAY_AT_MATURITY",
    0.015, 0.0, 1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_PP_INST",
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createPhoenixAutoCallableNote

##### 语法

```dolphindb
caplib::createPhoenixAutoCallableNote(couponPayoffType STRING, couponStrike DOUBLE, couponRate DOUBLE, dayCount STRING, startDate DATE, couponDates DATE[], knockOutBarrierType STRING, knockOutBarrierValue DOUBLE, knockInBarrierType STRING, knockInBarrierValue DOUBLE, longShort STRING, knockInPayoffType STRING, knockInPayoffStrike DOUBLE, expiry DATE, delivery DATE, settlementDays INT, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, knockOutDates DATE[], knockOutValues DOUBLE[], knockOutWeights DOUBLE[], knockInDates DATE[], knockInValues DOUBLE[], knockInWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存凤凰自动赎回票据。 函数验证并转换字段，构造 `PhoenixAutoCallableNote` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `couponPayoffType` | STRING | 票息收益类型。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `couponStrike` | DOUBLE | 票息条件使用的行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `couponRate` | DOUBLE | 票息率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DAY_COUNT_CONVENTION`, `ACT_360`, `ACTUAL_360`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `ACT_ACT_ISMA`, `ACTUAL_ACTUAL_ISMA`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `THIRTY_360`, `BOND_BASIS`, `THIRTY_E_360`, `EUROBOND_BASIS`, `THIRTY_E_360_ISDA`, `ONE_ONE`, `THIRTY_U_360`, `THIRTY_U_360_EOM`, `THIRTY_360_PSA`, `THIRTY_E_360_PLUS`, `THIRTY_360_IT`, `ACT_ACT_AFB`, `ACTUAL_ACTUAL_AFB`, `ACT_364`, `ACTUAL_364`, `ACT_365_25`, `ACTUAL_365_25`, `ACT_365_ACT`, `ACTUAL_365_ACTUAL`, `ACT_365_L`, `ACTUAL_365_LONG`, `ACT_365_NL`, `ACTUAL_365_NO_LEAP`, `ACT_ACT_YEAR`, `ACTUAL_ACTUAL_YEAR`, `BUSINESS_252`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `startDate` | DATE | 起始日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `couponDates` | DATE[] | 票息支付日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `knockOutBarrierType` | STRING | 敲出障碍类型。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `knockOutBarrierValue` | DOUBLE | 敲出障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `knockInBarrierType` | STRING | 敲入障碍类型。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `knockInBarrierValue` | DOUBLE | 敲入障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `longShort` | STRING | 多空方向。 **有效性:** 可接受值：`BUY`, `Buy`, `buy`, `SELL`, `Sell`, `sell`。仅接受所示精确拼写。 |
| `knockInPayoffType` | STRING | 敲入后收益类型。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `knockInPayoffStrike` | DOUBLE | 敲入后收益使用的行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `knockOutDates` | DATE[] | 敲出观察日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `knockOutValues` | DOUBLE[] | 与敲出日期对齐的敲出观察值数组。 **有效性:** 所有障碍水平必须非负且有限，并与对应日期/权重向量等长。 |
| `knockOutWeights` | DOUBLE[] | 敲出观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `knockInDates` | DATE[] | 敲入观察日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `knockInValues` | DOUBLE[] | 与敲入日期对齐的敲入观察值数组。 **有效性:** 所有障碍水平必须非负且有限，并与对应日期/权重向量等长。 |
| `knockInWeights` | DOUBLE[] | 敲入观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PhoenixAutoCallableNote` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createPhoenixAutoCallableNote(
    "CALL", underlyingPrice, 0.12, "ACT_365_FIXED", 2020.02.22,
    couponDates, "UP_OUT", underlyingPrice * 1.1, "DOWN_IN", underlyingPrice * 0.9,
    "SELL", "PUT", underlyingPrice * 0.85, 2020.08.19, 2020.08.20,
    1, 1000000.0, currency, "FUTURE", currency, underlying, "CM_PH_INST",
    couponDates, couponObsValues, couponObsWeights,
    dailyObsDates, dailyObsValues, dailyObsWeights, false)
```

#### createSnowballAutoCallableNote

##### 语法

```dolphindb
caplib::createSnowballAutoCallableNote(couponRate DOUBLE, startDate DATE, couponDates DATE[], dayCount STRING, knockOutBarrierType STRING, knockOutBarrierValue DOUBLE, knockInBarrierType STRING, knockInBarrierValue DOUBLE, longShort STRING, knockInPayoffType STRING, knockInPayoffStrike DOUBLE, knockInPayoffGearing DOUBLE, referencePrice DOUBLE, expiry DATE, delivery DATE, settlementDays INT, nominal DOUBLE, payoffCurrency STRING, underlyingType STRING, underlyingCurrency STRING, underlying STRING, handle STRING, knockOutDates DATE[], knockOutValues DOUBLE[], knockOutWeights DOUBLE[], knockInDates DATE[], knockInValues DOUBLE[], knockInWeights DOUBLE[][, returnJson BOOL])
```

##### 详情

创建并缓存雪球自动赎回票据。 函数验证并转换字段，构造 `SnowballAutoCallableNote` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `couponRate` | DOUBLE | 票息率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `startDate` | DATE | 起始日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `couponDates` | DATE[] | 票息支付日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DAY_COUNT_CONVENTION`, `ACT_360`, `ACTUAL_360`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `ACT_ACT_ISMA`, `ACTUAL_ACTUAL_ISMA`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `THIRTY_360`, `BOND_BASIS`, `THIRTY_E_360`, `EUROBOND_BASIS`, `THIRTY_E_360_ISDA`, `ONE_ONE`, `THIRTY_U_360`, `THIRTY_U_360_EOM`, `THIRTY_360_PSA`, `THIRTY_E_360_PLUS`, `THIRTY_360_IT`, `ACT_ACT_AFB`, `ACTUAL_ACTUAL_AFB`, `ACT_364`, `ACTUAL_364`, `ACT_365_25`, `ACTUAL_365_25`, `ACT_365_ACT`, `ACTUAL_365_ACTUAL`, `ACT_365_L`, `ACTUAL_365_LONG`, `ACT_365_NL`, `ACTUAL_365_NO_LEAP`, `ACT_ACT_YEAR`, `ACTUAL_ACTUAL_YEAR`, `BUSINESS_252`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `knockOutBarrierType` | STRING | 敲出障碍类型。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `knockOutBarrierValue` | DOUBLE | 敲出障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `knockInBarrierType` | STRING | 敲入障碍类型。 **有效性:** 可接受值：`DOWN_IN`, `UAI`, `DOWN_AND_IN`, `UP_IN`, `DAO`, `UP_AND_IN`, `DOWN_OUT`, `DAI`, `DOWN_AND_OUT`, `UP_OUT`, `UAO`, `UP_AND_OUT`。仅接受所示精确拼写。 |
| `knockInBarrierValue` | DOUBLE | 敲入障碍水平。 **有效性:** 必须非负且有限；包装器通常仅检查类型。 |
| `longShort` | STRING | 多空方向。 **有效性:** 可接受值：`BUY`, `Buy`, `buy`, `SELL`, `Sell`, `sell`。仅接受所示精确拼写。 |
| `knockInPayoffType` | STRING | 敲入后收益类型。 **有效性:** 可接受值：`CALL`, `call`, `PUT`, `put`。仅接受所示精确拼写。 |
| `knockInPayoffStrike` | DOUBLE | 敲入后收益使用的行权价。 **有效性:** 必须非负且有限；包装器仅检查类型/形状。 |
| `knockInPayoffGearing` | DOUBLE | 敲入收益杠杆。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `referencePrice` | DOUBLE | 收益结构使用的参考价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `expiry` | DATE | 到期日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `delivery` | DATE | 交割或结算日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关交易、参考或到期日；包装器不检查此关系。 |
| `settlementDays` | INT | 交易或行权到结算的工作日天数。 **有效性:** 必须非负；包装器通常仅检查类型。 |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `payoffCurrency` | STRING | 收益支付币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 可接受值：`SPOT`、`FUTURE`、`FORWARD`。仅接受这三个大写精确拼写；空字符串和别名均无效。 |
| `underlyingCurrency` | STRING | 标的资产币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `knockOutDates` | DATE[] | 敲出观察日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `knockOutValues` | DOUBLE[] | 与敲出日期对齐的敲出观察值数组。 **有效性:** 所有障碍水平必须非负且有限，并与对应日期/权重向量等长。 |
| `knockOutWeights` | DOUBLE[] | 敲出观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `knockInDates` | DATE[] | 敲入观察日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `knockInValues` | DOUBLE[] | 与敲入日期对齐的敲入观察值数组。 **有效性:** 所有障碍水平必须非负且有限，并与对应日期/权重向量等长。 |
| `knockInWeights` | DOUBLE[] | 敲入观察权重数组。 **有效性:** 所有权重必须非负且有限，向量须与配对日期/数值等长，并且总权重必须大于零；包装器不强制归一化。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `SnowballAutoCallableNote` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

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

##### 语法

```dolphindb
caplib::priceEqAmericanOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益美式期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqAmericanOption(
        am, asOfDate, mktData[0],
        bsmAnalyticalSettings, eqNoRisk[0], "", "", true)
```

#### priceEqAsianOption

##### 语法

```dolphindb
caplib::priceEqAsianOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益亚式期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqAsianOption(
    asianOption, asOfDate, mktData[0], bsmSettings, eqRisk[0], "", "", true)
```

#### priceEqDigitalOption

##### 语法

```dolphindb
caplib::priceEqDigitalOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益数字期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqDigitalOption(
        dg, asOfDate, mktData[0],
        bsmAnalyticalSettings, eqNoRisk[0], "", "", true)
```

#### priceEqOneTouchOption

##### 语法

```dolphindb
caplib::priceEqOneTouchOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益单触碰期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqOneTouchOption(
        ot, asOfDate, mktData[0],
        bsmAnalyticalSettings, eqNoRisk[0], "", "", true)
```

#### priceEqDoubleTouchOption

##### 语法

```dolphindb
caplib::priceEqDoubleTouchOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益双触碰期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqDoubleTouchOption(
        dt, asOfDate, mktData[0],
        bsmAnalyticalSettings, eqNoRisk[0], "", "", true)
```

#### priceEqSingleBarrierOption

##### 语法

```dolphindb
caplib::priceEqSingleBarrierOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益单障碍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqSingleBarrierOption(
        sb, asOfDate, mktData[0],
        bsmAnalyticalSettings, eqNoRisk[0], "", "", true)
```

#### priceEqDoubleBarrierOption

##### 语法

```dolphindb
caplib::priceEqDoubleBarrierOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益双障碍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqDoubleBarrierOption(
        dblB, asOfDate, mktData[0],
        bsmAnalyticalSettings, eqNoRisk[0], "", "", true)
```

#### priceEqSingleSharkFinOption

##### 语法

```dolphindb
caplib::priceEqSingleSharkFinOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益单鲨鱼鳍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqSingleSharkFinOption(
        sf, asOfDate, mktData[0],
        bsmPdeSettings, eqNoRisk[0], "", "", true)
```

#### priceEqDoubleSharkFinOption

##### 语法

```dolphindb
caplib::priceEqDoubleSharkFinOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益双鲨鱼鳍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqDoubleSharkFinOption(
        ds, asOfDate, mktData[0],
        bsmPdeSettings, eqNoRisk[0], "", "", true)
```

#### priceEqPingPongOption

##### 语法

```dolphindb
caplib::priceEqPingPongOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益乒乓期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqPingPongOption(
        pp, asOfDate, mktData[0],
        bsmMcSettings, eqNoRisk[0], "", "", true)
```

#### priceEqAirbagOption

##### 语法

```dolphindb
caplib::priceEqAirbagOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益安全气囊期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqAirbagOption(
        ab, asOfDate, mktData[0],
        bsmPdeSettings, eqNoRisk[0], "", "", true)
```

#### priceEqRangeAccrualOption

##### 语法

```dolphindb
caplib::priceEqRangeAccrualOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益区间累计期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqRangeAccrualOption(
        ra, asOfDate, mktData[0],
        bsmAnalyticalSettings, eqNoRisk[0], "", "", true)
```

#### priceEqPhoenixAutoCallableNote

##### 语法

```dolphindb
caplib::priceEqPhoenixAutoCallableNote(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益凤凰自动赎回票据。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqPhoenixAutoCallableNote(
        ph, asOfDate, mktData[0],
        bsmMcSettings, eqNoRisk[0], "", "", true)
```

#### priceEqSnowballAutoCallableNote

##### 语法

```dolphindb
caplib::priceEqSnowballAutoCallableNote(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价权益雪球自动赎回票据。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceEqSnowballAutoCallableNote(
        sn, asOfDate, mktData[0],
        bsmMcSettings, eqNoRisk[0], "", "", true)
```

### 商品

#### buildCmVolatilitySurface

##### 语法

```dolphindb
caplib::buildCmVolatilitySurface(referenceDate DATE, underlying STRING, definitionHandle STRING, quoteMatrixHandle STRING, underlyingPrices DOUBLE[], discountCurveHandle STRING, fwdCurveHandle STRING, buildSettingsHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建商品波动率曲面。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `VolatilitySurface`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `definitionHandle` | STRING | 波动率曲面定义 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `quoteMatrixHandle` | STRING | 期权报价矩阵 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `underlyingPrices` | DOUBLE[] | 与报价期限或校准行对齐的标的价格数组。 **有效性:** 所有元素必须有限并与配对日期等长；通常应为正，但可出现负价格的市场由下游业务规则决定。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `fwdCurveHandle` | STRING | 远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `buildSettingsHandle` | STRING | 构建设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolatilitySurface` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildCmVolatilitySurface(
    asOfDate, underlying, volDef[0], optionQuotes[0],
    [66380.00, 66400.00, 66420.00], irCurve, fwdCurve,
    volBuildSettings[0], "CM_VOL_SURF", true)
```

#### buildPmYieldCurve

##### 语法

```dolphindb
caplib::buildPmYieldCurve(referenceDate DATE, parCurveHandle STRING, discountCurveHandle STRING, pmTemplateHandle STRING, spotPrice DOUBLE, calcJacobian BOOL, dayCount STRING, interpMethod STRING, extrapMethod STRING, curveType STRING, curveName STRING, shift DOUBLE, method STRING, mode STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建贵金属收益率曲线。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `DividendCurve`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `parCurveHandle` | STRING | 平价曲线输入对象 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pmTemplateHandle` | STRING | 贵金属模板 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `spotPrice` | DOUBLE | 标的或贵金属的即期价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `calcJacobian` | BOOL | 是否计算并返回校准雅可比信息。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DAY_COUNT_CONVENTION`, `ACT_360`, `ACTUAL_360`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `ACT_ACT_ISMA`, `ACTUAL_ACTUAL_ISMA`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `THIRTY_360`, `BOND_BASIS`, `THIRTY_E_360`, `EUROBOND_BASIS`, `THIRTY_E_360_ISDA`, `ONE_ONE`, `THIRTY_U_360`, `THIRTY_U_360_EOM`, `THIRTY_360_PSA`, `THIRTY_E_360_PLUS`, `THIRTY_360_IT`, `ACT_ACT_AFB`, `ACTUAL_ACTUAL_AFB`, `ACT_364`, `ACTUAL_364`, `ACT_365_25`, `ACTUAL_365_25`, `ACT_365_ACT`, `ACTUAL_365_ACTUAL`, `ACT_365_L`, `ACTUAL_365_LONG`, `ACT_365_NL`, `ACTUAL_365_NO_LEAP`, `ACT_ACT_YEAR`, `ACTUAL_ACTUAL_YEAR`, `BUSINESS_252`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `interpMethod` | STRING | 插值方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_INTERP_METHOD`, `LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `SABR_INTERP`, `SVI_INTERP`, `LOG_MONEYNESS_CUBIC_SPLINE_INTERP`, `SABR_NORMAL_INTERP`, `QUADRATIC_POLYNOMIAL_INTERP`, `CUBIC_POLYNOMIAL_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `extrapMethod` | STRING | 外推方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_EXTRAP_METHOD`, `FLAT_EXTRAP`, `LINEAR_EXTRAP`, `NATURAL_EXTRAP`, `ADJ_FLAT_EXTRAP`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `curveType` | STRING | 曲线值类型，例如零利率、贴现因子或利差。 **有效性:** 值必须是以下完整 protobuf 标签之一：`ZERO_RATE`, `LOG_DISCOUNT`, `FORWARD_RATE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `shift` | DOUBLE | 风险或校准计算使用的扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `method` | STRING | 计算、校准或有限差分方法选择器。 **有效性:** 值必须是以下完整 protobuf 标签之一：`CENTRAL_DIFFERENCE_METHOD`, `ONE_SIDE_DOWN_METHOD`, `ONE_SIDE_UP_METHOD`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 值必须是以下完整 protobuf 标签之一：`SINGLE_THREADING_MODE`, `MULTI_THREADING_MODE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `DividendCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::buildPmYieldCurve(referenceDate, parCurveHandle, discountCurveHandle, pmTemplateHandle, spotPrice, calcJacobian, dayCount, interpMethod, extrapMethod, curveType, curveName, shift, method, mode, handle)
```

#### buildPmVolatilitySurface

##### 语法

```dolphindb
caplib::buildPmVolatilitySurface(referenceDate DATE, underlying STRING, definitionHandle STRING, quoteMatrixHandle STRING, underlyingPrice DOUBLE, discountCurveHandle STRING, fwdCurveHandle STRING, buildSettingsHandle STRING, marketConventionsHandle STRING, spotTemplateHandle STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建贵金属波动率曲面。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `VolatilitySurface`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `definitionHandle` | STRING | 波动率曲面定义 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `quoteMatrixHandle` | STRING | 期权报价矩阵 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `underlyingPrice` | DOUBLE | 当前标的价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `fwdCurveHandle` | STRING | 远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `buildSettingsHandle` | STRING | 构建设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `marketConventionsHandle` | STRING | 市场惯例 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `spotTemplateHandle` | STRING | 即期模板 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `VolatilitySurface` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::buildPmVolatilitySurface(referenceDate, underlying, definitionHandle, quoteMatrixHandle, underlyingPrice, discountCurveHandle, fwdCurveHandle, buildSettingsHandle, marketConventionsHandle, spotTemplateHandle, handle)
```

#### createCmMktDataSet

##### 语法

```dolphindb
caplib::createCmMktDataSet(asOfDate DATE, underlying STRING, underlyingPrice DOUBLE, discountCurve STRING, dividendCurve STRING, volSurface STRING, quantoDiscountCurve STRING, quantoFxVolCurve STRING, quantoCorrelation DOUBLE, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存商品市场数据集。 函数验证并转换字段，构造 `CmMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `underlyingPrice` | DOUBLE | 当前标的价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `discountCurve` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `dividendCurve` | STRING | 股息或远期收益曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `volSurface` | STRING | 波动率曲面 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `quantoDiscountCurve` | STRING | Quanto 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `quantoFxVolCurve` | STRING | Quanto 外汇波动率曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `quantoCorrelation` | DOUBLE | Quanto 调整相关系数。 **有效性:** 必须有限且业务有效范围为 `[-1,1]`；包装器仅检查类型。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CmMktDataSet` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createCmMktDataSet(
    asOfDate, underlying, underlyingPrice, irCurve, fwdCurve, volSurface[0], "", "", 0.0, "CM_MKT", true)
```

#### createCmRiskSettings

##### 语法

```dolphindb
caplib::createCmRiskSettings(irDelta BOOL, priceDelta BOOL, volVega BOOL, theta BOOL, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存商品风险设置。 函数验证并转换字段，构造 `CmRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `irDelta` | BOOL | 是否计算利率 Delta 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `priceDelta` | BOOL | 是否计算标的价格 Delta 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `volVega` | BOOL | 是否计算波动率 Vega 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `theta` | BOOL | 是否计算 Theta 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CmRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createCmRiskSettings(1, 1, 1, 1, "CM_RISK", true)
```

#### priceCmEuropeanOption

##### 语法

```dolphindb
caplib::priceCmEuropeanOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品欧式期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmEuropeanOption(
    europeanOption, asOfDate, mktData[0], bsmSettings, cmRisk[0], "", "", true)
```

#### priceCmAmericanOption

##### 语法

```dolphindb
caplib::priceCmAmericanOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品美式期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmAmericanOption(
    americanOption, asOfDate, mktData[0], bsmAnalyticalSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmAsianOption

##### 语法

```dolphindb
caplib::priceCmAsianOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品亚式期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmAsianOption(
    asianOption, asOfDate, mktData[0], bsmMcSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmDigitalOption

##### 语法

```dolphindb
caplib::priceCmDigitalOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品数字期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmDigitalOption(
    digitalOption, asOfDate, mktData[0], bsmAnalyticalSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmOneTouchOption

##### 语法

```dolphindb
caplib::priceCmOneTouchOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品单触碰期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmOneTouchOption(
    oneTouchOption, asOfDate, mktData[0], bsmAnalyticalSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmDoubleTouchOption

##### 语法

```dolphindb
caplib::priceCmDoubleTouchOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品双触碰期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmDoubleTouchOption(
    doubleTouchOption, asOfDate, mktData[0], bsmAnalyticalSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmSingleBarrierOption

##### 语法

```dolphindb
caplib::priceCmSingleBarrierOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品单障碍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmSingleBarrierOption(
    singleBarrierOption, asOfDate, mktData[0], bsmAnalyticalSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmDoubleBarrierOption

##### 语法

```dolphindb
caplib::priceCmDoubleBarrierOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品双障碍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmDoubleBarrierOption(
    doubleBarrierOption, asOfDate, mktData[0], bsmAnalyticalSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmSingleSharkFinOption

##### 语法

```dolphindb
caplib::priceCmSingleSharkFinOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品单鲨鱼鳍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmSingleSharkFinOption(
    singleSharkFinOption, asOfDate, mktData[0], bsmPdeSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmDoubleSharkFinOption

##### 语法

```dolphindb
caplib::priceCmDoubleSharkFinOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品双鲨鱼鳍期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmDoubleSharkFinOption(
    doubleSharkFinOption, asOfDate, mktData[0], bsmPdeSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmPingPongOption

##### 语法

```dolphindb
caplib::priceCmPingPongOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品乒乓期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmPingPongOption(
    pingPongOption, asOfDate, mktData[0], bsmMcSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmAirbagOption

##### 语法

```dolphindb
caplib::priceCmAirbagOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品安全气囊期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmAirbagOption(
    airbagOption, asOfDate, mktData[0], bsmPdeSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmRangeAccrualOption

##### 语法

```dolphindb
caplib::priceCmRangeAccrualOption(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品区间累计期权。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmRangeAccrualOption(
    rangeAccrualOption, asOfDate, mktData[0], bsmAnalyticalSettings, cmRisk[0], scnAnalysis, "", true)
```

#### priceCmPhoenixAutoCallableNote

##### 语法

```dolphindb
caplib::priceCmPhoenixAutoCallableNote(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品凤凰自动赎回票据。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmPhoenixAutoCallableNote(
    phoenixNote, asOfDate, mktData[0], bsmMcSettings, cmNoRisk[0], "", "", true)
```

#### priceCmSnowballAutoCallableNote

##### 语法

```dolphindb
caplib::priceCmSnowballAutoCallableNote(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价商品雪球自动赎回票据。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCmSnowballAutoCallableNote(
    snowballNote, asOfDate, mktData[0], bsmMcSettings, cmNoRisk[0], "", "", true)
```

#### createPmCashTemplate

##### 语法

```dolphindb
caplib::createPmCashTemplate(instName STRING, startDelay INT, deliveryDayConvention STRING, calendars STRING or STRING[], dayCount STRING[, returnJson BOOL])
```

##### 详情

创建并缓存贵金属现金工具模板。 函数验证并转换字段，构造 `PmCashTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `startDelay` | INT | 起息或交割延迟天数。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `deliveryDayConvention` | STRING | 交割日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `calendars` | STRING or STRING[] | 日期调整使用的业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 任何其他字符串均回退到函数指定的默认日计数。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PmCashTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createPmCashTemplate(instName, startDelay, deliveryDayConvention, calendars, dayCount)
```

#### createPmParRateCurve

##### 语法

```dolphindb
caplib::createPmParRateCurve(asOfDate DATE, currency STRING, curveName STRING, pillarsTable MATRIX/TABLE, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存贵金属平价利率曲线输入。 函数验证并转换字段，构造 `PmParRateCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `pillarsTable` | MATRIX/TABLE | 曲线节点输入表。 **有效性:** 必须具有所列元素类型和形状；元素不得为空；除明确说明外包装器不强制非空。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PmParRateCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createPmParRateCurve(asOfDate, currency, curveName, pillarsTable, tag)
```

#### createPmMktConventions

##### 语法

```dolphindb
caplib::createPmMktConventions(atmType STRING, shortDeltaType STRING, longDeltaType STRING, deltaCutoff STRING, riskReversal STRING, smileQuoteType STRING, underlying STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存贵金属市场惯例。 函数验证并转换字段，构造 `PmMarketConventions` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `atmType` | STRING | ATM 报价类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_ATM_TYPE`, `ATM_FORWARD`, `ATM_DNS_PIPS`, `ATM_DNS_PERCENTAGE`, `ATM_SPOT`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `shortDeltaType` | STRING | 短期限 Delta 报价类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DELTA_TYPE`, `PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `longDeltaType` | STRING | 长期限 Delta 报价类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DELTA_TYPE`, `PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `deltaCutoff` | STRING | Delta 报价切换阈值。 **有效性:** 值必须是以下完整 protobuf 标签之一：`INVALID_DELTA_TYPE`, `PIPS_SPOT_DELTA`, `PERCENTAGE_SPOT_DELTA`, `PIPS_FORWARD_DELTA`, `PERCENTAGE_FORWARD_DELTA`, `SIMPLE_DELTA`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `riskReversal` | STRING | 设置对象的缓存句柄或配置值。 **有效性:** 值必须是以下完整 protobuf 标签之一：`RR_CALL_PUT`, `RR_PUT_CALL`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `smileQuoteType` | STRING | 波动率微笑报价类型。 **有效性:** 值必须是以下完整 protobuf 标签之一：`BUTTERFLY_QUOTE`, `MARKET_STRANGLE_QUOTE`, `WINGS_RATIO_BF_QUOTE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PmMarketConventions` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createPmMktConventions(atmType, shortDeltaType, longDeltaType, deltaCutoff, riskReversal, smileQuoteType, underlying, tag)
```

#### createPmOptionQuoteMatrix

##### 语法

```dolphindb
caplib::createPmOptionQuoteMatrix(underlying STRING, asOfDate DATE, terms STRING[], payoffTypes STRING matrix/vector, deltas DOUBLE matrix/vector, quotes DOUBLE matrix/vector, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存贵金属期权报价矩阵。 函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `terms` | STRING[] | 报价期限数组。 **有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `payoffTypes` | STRING matrix/vector | 与报价值对齐的收益类型矩阵或向量。 **有效性:** 每个元素必须是以下完整 protobuf 标签之一：`CALL`, `PUT`, `STRADDLE`, `STRANGLE`, `RISK_REVERSAL`, `BUTTERFLY`, `ATM_STRADDLE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `deltas` | DOUBLE matrix/vector | Delta 行权价矩阵或向量。 **有效性:** 所有元素必须有限且位于 `[-1,1]`，形状须与配对报价矩阵一致；包装器仅强制形状/类型。 |
| `quotes` | DOUBLE matrix/vector | 市场报价值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `OptionQuoteMatrix` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

result = caplib::createPmOptionQuoteMatrix(underlying, asOfDate, terms, payoffTypes, deltas, quotes, handle)
```

#### createCmOptionQuoteMatrix

##### 语法

```dolphindb
caplib::createCmOptionQuoteMatrix(exerciseType STRING, underlyingType STRING, asOfDate DATE, termDates DATE[], payoffTypes STRING matrix/vector, strikes DOUBLE matrix/vector, prices DOUBLE matrix/vector, underlying STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存商品期权报价矩阵。 函数验证并转换字段，构造 `OptionQuoteMatrix` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `exerciseType` | STRING | 期权行权风格。 **有效性:** 值必须是以下完整 protobuf 标签之一：`EUROPEAN`, `AMERICAN`, `BERMUDAN`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `underlyingType` | STRING | 标的类型枚举。 **有效性:** 值必须是以下完整 protobuf 标签之一：`SPOT_UNDERLYING_TYPE`, `FUTURE_UNDERLYING_TYPE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `termDates` | DATE[] | 报价期限对应的到期日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `payoffTypes` | STRING matrix/vector | 与报价值对齐的收益类型矩阵或向量。 **有效性:** 每个元素必须是以下完整 protobuf 标签之一：`CALL`, `PUT`, `STRADDLE`, `STRANGLE`, `RISK_REVERSAL`, `BUTTERFLY`, `ATM_STRADDLE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `strikes` | DOUBLE matrix/vector | 行权价数组或矩阵。 **有效性:** 必须有限；价格型标的通常要求非负，利率型标的可为负。包装器仅检查类型/形状。 |
| `prices` | DOUBLE matrix/vector | 期权价格矩阵或报价数组。 **有效性:** 所有元素必须非负且有限，并与配对行权价/期限参数形状一致；包装器主要检查类型/形状。 |
| `underlying` | STRING | 标的资产、指数、商品或货币对标识。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `OptionQuoteMatrix` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createCmOptionQuoteMatrix(
    "AMERICAN", "FUTURE_UNDERLYING_TYPE", asOfDate,
    termDates, payoffTypes, strikes, prices, underlying, "CM_OPTION_QUOTES", true)
```

### 信用

#### createCreditCurve

##### 语法

```dolphindb
caplib::createCreditCurve(referenceDate DATE, pillarDates DATE[], spreads DOUBLE[], dcc STRING, interp STRING, extrap STRING, name STRING, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存信用曲线。 函数验证并转换字段，构造 `CreditCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `pillarDates` | DATE[] | 曲线节点日期数组。 **有效性:** 必须是不含空值的 DATE/INT 日期向量，长度须与配对参数一致。表示日程或期限序列时通常应严格递增；包装器不检查排序或日期先后关系。 |
| `spreads` | DOUBLE[] | 信用利差或曲线利差数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限；除明确说明外包装器不强制非空。 |
| `dcc` | STRING | 日计数约定。 **有效性:** 可接受值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `ACT_ACT`, `ACT_ACT_ISDA`, `ACTUAL_ACTUAL_ISDA`, `ACT_ACT_ICMA`, `ACTUAL_ACTUAL_ICMA`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 |
| `interp` | STRING | 插值方法。 **有效性:** 可接受值：`LINEAR_INTERP`, `CUBIC_SPLINE_INTERP`, `LEFT_CONTINUOUS_FLAT_INTERP`, `CUBIC_HERMITE_SPLINE_INTERP`。仅接受所示精确拼写。 |
| `extrap` | STRING | 外推方法。 **有效性:** 可接受值：`FLAT_EXTRAP`, `LINEAR_EXTRAP`。仅接受所示精确拼写。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CreditCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createCreditCurve(
    asOfDate,
    [2020.03.01, 2020.03.22, 2020.05.21, 2020.08.22],
    [0.0012, 0.0018, 0.0024, 0.0030],
    "ACT_365_FIXED", "LINEAR_INTERP", "FLAT_EXTRAP",
    "BOND_CREDIT", "CR_BASE_CREDIT_CURVE", false)
```

#### createCreditCurveRiskSettings

##### 语法

```dolphindb
caplib::createCreditCurveRiskSettings(delta BOOL, gamma BOOL, shift DOUBLE, method INT, granularity INT, scaling DOUBLE, threading INT, handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存信用曲线风险设置。 函数验证并转换字段，构造 `CreditCurveRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `delta` | BOOL | 是否计算 Delta 风险或 Delta 数值。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `gamma` | BOOL | 是否计算 Gamma 风险。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `shift` | DOUBLE | 风险或校准计算使用的扰动大小。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `method` | INT | 计算、校准或有限差分方法选择器。 **有效性:** 映射：`value =2` 为 ONE_SIDE_UP。 |
| `granularity` | INT | 风险桶或扰动粒度。 **有效性:** 映射：`value =2` 为 TERM_STRIKE。 |
| `scaling` | DOUBLE | 风险扰动缩放因子。 **有效性:** 必须严格为正且有限；包装器仅检查 DOUBLE 类型。 |
| `threading` | INT | 线程模式选择器。 **有效性:** 仅 `1` 选择多线程；其他整数均为单线程。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CreditCurveRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createCreditCurveRiskSettings(
    1, 0, 1.0e-4, 0, 1, 1.0e-4, 0, "CR_CREDIT_RISK", false)
```

#### buildBondCreditSpreadCurve

##### 语法

```dolphindb
caplib::buildBondCreditSpreadCurve(referenceDate DATE, curveName STRING, parCurveHandle STRING, discountCurveHandle STRING, forwardCurveHandle STRING, buildingMethod STRING, calcJacobian BOOL, handle STRING[, returnJson BOOL])
```

##### 详情

构建债券信用利差曲线。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `CreditCurve`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `parCurveHandle` | STRING | 平价曲线输入对象 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `forwardCurveHandle` | STRING | 远期曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `buildingMethod` | STRING | 曲线或曲面构建算法名称。 **有效性:** 识别值：`BOOTSTRAP`, `BOOTSTRAPPING`, `BOOTSTRAPPING_METHOD`, `GLOBAL_OPTIMIZATION`, `GLOBAL_OPTIMIZATION_METHOD`, `HYBRID`, `HYBRID_METHOD`。不区分大小写。 空值或其他字符串回退为 BOOTSTRAPPING_METHOD。 |
| `calcJacobian` | BOOL | 是否计算并返回校准雅可比信息。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CreditCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildBondCreditSpreadCurve(
    asOfDate, cnyMtnAaaSprdStdCfetsName, parCnyMtnAaaSprdStdCfets[0],
    cnyTreasStdCfets[0], "", "BOOTSTRAPPING_METHOD", 0,
    "CNY_MTN_AAA_SPRD_STD_CFETS", true)
```

#### createCreditParCurve

##### 语法

```dolphindb
caplib::createCreditParCurve(asOfDate DATE, currency STRING, curveName STRING, instrumentNames STRING[], instrumentTypes STRING[], maturities STRING[], quotes DOUBLE[], startConventions STRING[], handle STRING[, returnJson BOOL])
```

##### 详情

创建并缓存信用平价曲线输入。 函数验证并转换字段，构造 `CreditParCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `instrumentNames` | STRING[] | 市场工具名称数组。 **有效性:** 必须具有所列元素类型和形状；元素不得为空，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `instrumentTypes` | STRING[] | 市场工具类型数组。 **有效性:** 每个元素必须是以下完整 protobuf 标签之一：`INVALID_INSTRUMENT_TYPE`, `DEPOSIT`, `FORWARD_RATE_AGREEMENT`, `IR_VANILLA_SWAP`, `OVERNIGHT_INDEX_SWAP`, `CROSS_CURRENCY_SWAP`, `MTM_CROSS_CURRENCY_SWAP`, `STD_CROSS_CURRENCY_SWAP`, `IR_BOND`, `NON_DELIVERABLE_SWAP`, `IR_EUROPEAN_SWAPTION`, `IR_CAP_FLOOR`, `IR_FUTURE`, `IR_FUTURE_IMM`, `IR_FUTURE_ASX`, `IR_VANILLA_BOND`, `IMM_FORWARD_RATE_AGREEMENT`, `IR_BOND_OPTION`, `IR_RANGEACCRUAL_SWAP`, `IR_STRUCTURED_SWAP`, `FX_SPOT`, `FX_FORWARD`, `FX_NON_DELIVERABLE_FORWARD`, `FX_SWAP`, `FX_SWAP_ON`, `FX_SWAP_TN`, `FX_EUROPEAN_OPTION`, `FX_TIME_OPTION`, `FX_DIGITAL_OPTION`, `FX_QUANTO_OPTION`, `FX_TOUCH_OPTION`, `FX_BARRIER_OPTION`, `FX_VANILLA_STRATEGY`, `FX_TOUCH_QUANTO_OPTION`, `FX_DIGITAL_QUANTO_OPTION`, `EQ_INDEX_FUTURE`, `EQ_EUROPEAN_OPTION`, `EQ_AMERICAN_OPTION`, `EQ_SPOT`, `EQ_VANILLA_OPTION`, `EQ_DIGITAL_OPTION`, `EQ_BARRIER_OPTION`, `EQ_RANGE_ACCRUAL_OPTION`, `EQ_TOUCH_OPTION`, `EQ_QUANTO_OPTION`, `CM_SPOT`, `CM_FUTURE`, `CM_EUROPEAN_OPTION`, `CM_AMERICAN_OPTION`, `CM_VANILLA_OPTION`, `CM_ASIAN_OPTION`, `CM_DIGITAL_OPTION`, `CM_SWAP`, `CM_DIGITAL_ASIAN_OPTION`, `PM_SPOT`, `PM_SWAP`, `CREDIT_DEFAULT_SWAP`, `SPOT`, `FUTURE`, `FORWARD`, `SWAP`, `EUROPEAN_OPTION`, `AMERICAN_OPTION`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `maturities` | STRING[] | 工具到期期限数组。 **有效性:** 每个元素必须使用正整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `quotes` | DOUBLE[] | 市场报价值数组。 **有效性:** 必须具有所列元素类型和形状；数值必须有限，长度/维度须与配对参数一致；除明确说明外包装器不强制非空。 |
| `startConventions` | STRING[] | 工具起息日约定数组。 **有效性:** 每个元素必须是以下完整 protobuf 标签之一：`INVALID_INSTRUMENT_START_CONVENTION`, `SPOTSTART`, `TODAYSTART`, `TOMORROWSTART`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CreditParCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

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

##### 语法

```dolphindb
caplib::buildCreditCurve(asOfDate DATE, parCurveHandle STRING, discountCurveHandle STRING, curveName STRING, method STRING, handle STRING[, returnJson BOOL])
```

##### 详情

构建信用曲线。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `CreditCurve`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `parCurveHandle` | STRING | 平价曲线输入对象 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `discountCurveHandle` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `curveName` | STRING | 曲线业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `method` | STRING | 计算、校准或有限差分方法选择器。 **有效性:** 必须为非空 STRING；值会原样传给信用曲线服务，插件未定义本地枚举。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CreditCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildCreditCurve(
    asOfDate, creditParCurve[0], discountCurve, "BOND_CREDIT",
    "BOOTSTRAPPING_METHOD", "CR_CREDIT_CURVE", true)
```

#### priceCreditDefaultSwap

##### 语法

```dolphindb
caplib::priceCreditDefaultSwap(instrumentHandle STRING, pricingDate DATE, mktDataHandle STRING, pricingSettingsHandle STRING, riskSettingsHandle STRING, scnSettingsHandle STRING, mode STRING[, returnJson BOOL])
```

##### 详情

定价信用违约互换。 函数组装工具、市场数据、定价、风险和可选情景输入，调用相应定价服务并缓存返回的 `PricingResults`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instrumentHandle` | STRING | 被定价工具的 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingDate` | DATE | 定价请求使用的估值日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `mktDataHandle` | STRING | 定价使用的市场数据集 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `pricingSettingsHandle` | STRING | 定价设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `riskSettingsHandle` | STRING | 风险设置 内存对象 句柄。 **有效性:** 必须是非空、已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `scnSettingsHandle` | STRING | 情景分析设置 内存对象 句柄；未使用时传空字符串。 **有效性:** 可为空以省略；非空时必须是已存在且 protobuf 类型匹配的 ObjectCache 键。 |
| `mode` | STRING | 远程执行模式或服务端点；传空字符串使用默认模式。 **有效性:** 可为空以使用默认模式；非空值会原样传给下游服务，插件未定义本地枚举或字符范围。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingResults` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::priceCreditDefaultSwap(
    cds, asOfDate, mktData[0], pricingSettings[0], crRisk[0], "", "", true)
```

#### createCdsTemplate

##### 语法

```dolphindb
caplib::createCdsTemplate(instName STRING, startDelay STRING or INT, settlementType STRING, referencePrice DOUBLE, leverage DOUBLE, creditProtectionType STRING, recoveryRate DOUBLE, creditPremiumType STRING, dayCount STRING, frequency STRING, businessDayConvention STRING, calendars STRING or STRING[], rebateAccrual BOOL or INT[, returnJson BOOL])
```

##### 详情

创建并缓存信用违约互换模板。 函数验证并转换字段，构造 `CreditInstrumentTemplate` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `instName` | STRING | 工具或模板名称，通常也作为缓存句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `startDelay` | STRING or INT | 起息或交割延迟天数。 **有效性:** 值必须使用非负整数加 `Y/M/W/D`（或完整英文单位）；不支持小数，字符串解析不保留负号。 |
| `settlementType` | STRING | 结算类型。 **有效性:** 可接受值：`PHYSICAL`, `PHYSICAL_SETTLEMENT`, `CASH`, `CASH_SETTLEMENT`, `CASH_ZERO_COUPON_SETTLEMENT`。不区分大小写。 空字符串或 NAN 回退为 PHYSICAL_SETTLEMENT；其他未知值报错。 |
| `referencePrice` | DOUBLE | 收益结构使用的参考价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `leverage` | DOUBLE | 保护腿或收益结构杠杆。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `creditProtectionType` | STRING | 信用保护类型。 **有效性:** 可接受值：`PAY_PROTECTION_AT_DEFAULT`, `PAY_PROTECTION_AT_MATURITY`。不区分大小写。 空字符串或 NAN 回退为 PAY_PROTECTION_AT_DEFAULT；其他未知值报错。 |
| `recoveryRate` | DOUBLE | 回收率。 **有效性:** 必须有限且业务有效范围为 `[0,1]`；包装器仅检查类型。 |
| `creditPremiumType` | STRING | 信用产品溢价支付类型。 **有效性:** 可接受值：`PAY_PREMIUM_AT_DEFAULT`, `PAY_PREMIUM_UPTO_CURRENT_PERIOD`, `PAY_PREMIUM_UPTO_MATURITY`, `PAY_NOTHING_AFTER_DEFAULT`。不区分大小写。 空字符串或 NAN 回退为 PAY_PREMIUM_AT_DEFAULT；其他未知值报错。 |
| `dayCount` | STRING | 日计数约定。 **有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 任何其他字符串均回退到函数指定的默认日计数。 |
| `frequency` | STRING | 频率。 **有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 任何其他字符串均回退到函数指定的默认频率。 |
| `businessDayConvention` | STRING | 营业日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `calendars` | STRING or STRING[] | 日期调整使用的业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `rebateAccrual` | BOOL or INT | 是否返还应计利息。 **有效性:** 接受 BOOL 或 INT；0 为 false，非零为 true。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CreditInstrumentTemplate` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createCdsTemplate(
    "CFETS-SHCH-GTJA", 0, "CASH", 1.0,
    1.0, "SENIOR", 0.4, "FLAT_SPREAD",
    "ACT_360", "QUARTERLY", "MODIFIED_FOLLOWING", "CAL_CFETS", 0, false)
```

#### buildCreditDefaultSwap

##### 语法

```dolphindb
caplib::buildCreditDefaultSwap(nominal DOUBLE, currency STRING, issueDate DATE, maturity DATE, protectionLegPayReceive STRING, protectionLegSettlementType STRING, protectionLegReferencePrice DOUBLE, protectionLegLeverage DOUBLE, creditProtectionType STRING, protectionLegRecoveryRate DOUBLE, couponRate DOUBLE, creditPremiumType STRING, dayCountConvention STRING, frequency STRING, businessDayConvention STRING, calendars STRING, upfrontRate DOUBLE, rebateAccrual BOOL, name STRING, tag STRING[, returnJson BOOL])
```

##### 详情

构建信用违约互换工具。 函数解析引用的 ObjectCache 条目，调用相关构建服务并缓存返回的 `CreditDefaultSwap`。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `nominal` | DOUBLE | 工具名义金额。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `currency` | STRING | 币种代码。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `issueDate` | DATE | 发行日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `maturity` | DATE | 到期期限或到期日。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得早于相关开始、发行或参考日；包装器不检查此关系。 |
| `protectionLegPayReceive` | STRING | 保护腿支付或收取方向。 **有效性:** 仅接受精确值 `PAY` 或 `RECEIVE`。 |
| `protectionLegSettlementType` | STRING | 保护腿结算类型。 **有效性:** 仅接受精确值 `PHYSICAL` 或 `CASH`。 |
| `protectionLegReferencePrice` | DOUBLE | 保护腿参考价格。 **有效性:** 必须严格为正且有限；包装器通常仅检查类型。 |
| `protectionLegLeverage` | DOUBLE | 保护腿杠杆。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `creditProtectionType` | STRING | 信用保护类型。 **有效性:** 精确值 `PAY_PROTECTION_AT_MATURITY` 选择到期赔付；任何其他 STRING（包括空值或未知值）均回退为 PAY_PROTECTION_AT_DEFAULT。 |
| `protectionLegRecoveryRate` | DOUBLE | 保护腿回收率。 **有效性:** 必须有限且业务有效范围为 `[0,1]`；包装器仅检查类型。 |
| `couponRate` | DOUBLE | 票息率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `creditPremiumType` | STRING | 信用产品溢价支付类型。 **有效性:** 精确值 `PAY_PREMIUM_UPTO_CURRENT_PERIOD` 选择当前期间；`PAY_PREMIUM_UPTO_MATURITY` 及任何其他 STRING 均选择到期。 |
| `dayCountConvention` | STRING | 日计数约定。 **有效性:** 识别值：`ACT_360`, `ACTUAL_360`, `ACT/360`, `ACT_365`, `ACT_365_FIXED`, `ACTUAL_365_FIXED`, `ACT/365`, `THIRTY_360`, `30_360`, `30/360`, `BOND_BASIS`。不区分大小写。 任何其他字符串均回退到函数指定的默认日计数。 |
| `frequency` | STRING | 频率。 **有效性:** 识别值：`MONTHLY`, `QUARTERLY`, `SEMIANNUAL`, `SEMI_ANNUAL`, `ANNUAL`。不区分大小写。 任何其他字符串均回退到函数指定的默认频率。 |
| `businessDayConvention` | STRING | 营业日调整约定。 **有效性:** 识别值：`FOLLOWING`, `MODIFIED_FOLLOWING`, `PRECEDING`, `MODIFIED_PRECEDING`, `UNADJUSTED`。不区分大小写。 任何其他字符串均回退到函数指定的默认营业日约定。 |
| `calendars` | STRING | 日期调整使用的业务日历名称。 **有效性:** 每个名称必须是已注册的非空日历标识。 |
| `upfrontRate` | DOUBLE | 前端费用率。 **有效性:** 必须是有限 DOUBLE；除非另有说明，可为负、零或正，包装器不拒绝 NaN/无穷。 |
| `rebateAccrual` | BOOL | 是否返还应计利息。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CreditDefaultSwap` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::buildCreditDefaultSwap(
    1000000.0, currency, 2019.06.20, 2024.06.20,
    "PAY", "CASH", 1.0, 1.0, "SENIOR", 0.4,
    0.01, "FLAT_SPREAD", "ACT_360", "QUARTERLY",
    "MODIFIED_FOLLOWING", "CAL_CFETS", 0.01, 0,
    "CR_CDS_NAME", "CR_CDS", false)
```

#### createCdsPricingSettings

##### 语法

```dolphindb
caplib::createCdsPricingSettings(pricingCurrency STRING, includeCurrentFlow BOOL, cashFlows BOOL, includeSettlementFlow BOOL, numericalFix STRING, accrualBias STRING, fwdsInCpnPeriod STRING, name STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存 CDS 定价设置。 函数验证并转换字段，构造 `PricingSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `pricingCurrency` | STRING | 定价输出使用的币种。 **有效性:** 必须是非空币种标识，通常为三个大写 ISO 字母；包装器不验证 ISO 成员资格。 |
| `includeCurrentFlow` | BOOL | 估值输出中是否包含当前现金流。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `cashFlows` | BOOL | 定价结果中是否包含详细现金流输出。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `includeSettlementFlow` | BOOL | 估值输出中是否包含结算现金流。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |
| `numericalFix` | STRING | 数值稳定性修正方法。 **有效性:** 值必须是以下完整 protobuf 标签之一：`NONE_FIX`, `TAYLOR`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `accrualBias` | STRING | 应计利息偏差处理方式。 **有效性:** 值必须是以下完整 protobuf 标签之一：`HALFDAYBIAS`, `NOBIAS`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `fwdsInCpnPeriod` | STRING | 控制票息期间内远期利率处理方式的约定。 **有效性:** 值必须是以下完整 protobuf 标签之一：`FLAT`, `PIECEWISE`。这些是规范拼写；为保证兼容性请按所示使用。包含 `INVALID` 的标签是解析器可识别的哨兵，通常不是有效业务输入。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `PricingSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createCdsPricingSettings(
    currency, 0, 1, 0, "TAYLOR", "HALFDAYBIAS", "PIECEWISE",
    "CR_PRICING_NAME", "CR_PRICING", true)
```

#### createCrMktDataSet

##### 语法

```dolphindb
caplib::createCrMktDataSet(asOfDate DATE, discountCurve STRING, creditCurve STRING, name STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存信用市场数据集。 函数验证并转换字段，构造 `CrMktDataSet` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `asOfDate` | DATE | 市场数据基准日或估值参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `discountCurve` | STRING | 贴现曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `creditCurve` | STRING | 信用曲线 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CrMktDataSet` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createCrMktDataSet(
    asOfDate, discountCurve, creditCurve[0], "CR_MKT_NAME", "CR_MKT", true)
```

#### createCrRiskSettings

##### 语法

```dolphindb
caplib::createCrRiskSettings(irCurveSettings STRING, csCurveSettings STRING, thetaSettings STRING, name STRING, tag STRING[, returnJson BOOL])
```

##### 详情

创建并缓存信用风险设置。 函数验证并转换字段，构造 `CrRiskSettings` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `irCurveSettings` | STRING | 利率曲线风险设置 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `csCurveSettings` | STRING | 信用利差曲线风险设置 内存对象 句柄。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `thetaSettings` | STRING | 设置对象的缓存句柄或配置值。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `name` | STRING | 写入创建对象的业务名称。 **有效性:** 必须是非空 STRING；包装器不验证业务标识的字符集或成员资格。 |
| `tag` | STRING | 用于后续获取创建对象的 内存对象 键或标签。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CrRiskSettings` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createCrRiskSettings(
    irRisk, creditRisk, thetaRisk, "CR_RISK_NAME", "CR_RISK", true)
```

#### createFlatCreditCurve

##### 语法

```dolphindb
caplib::createFlatCreditCurve(referenceDate DATE, hazardRate DOUBLE, handle STRING[, returnJson BOOL])
```

##### 详情

在生成期限结构的两端应用同一风险率/利差值，创建平坦 CreditCurve。 函数验证并转换字段，构造 `CreditCurve` protobuf 并存入 ObjectCache，供后续分析使用。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `referenceDate` | DATE | 曲线、曲面或构建请求的参考日期。 **有效性:** 必须是非空 DolphinDB DATE 标量。不得晚于相关结束、到期、交割或结算日；包装器不检查此关系。 |
| `hazardRate` | DOUBLE | 平坦 CreditCurve 的常量风险率/利差。 **有效性:** 业务有效值须有限且非负；包装器仅检查 DOUBLE 类型。 |
| `handle` | STRING | 分配给创建对象并由函数返回的 内存对象 键。 **有效性:** 必须是非空 ObjectCache 键。 |
| `returnJson` | BOOL | 可选。省略或为 false 时仅返回 内存对象 句柄；为 true 时返回 [handle, protobufJson]。 **有效性:** 必须是 BOOL 标量，仅可为 false 或 true。 |

##### 返回值

**返回：** 成功时创建 `CreditCurve` 对象。CAPLIB 返回其 ObjectCache 句柄；`returnJson=true` 时返回 `[handle, protobufJson]`。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::createFlatCreditCurve(asOfDate, 0.002, "AN_FLAT_CREDIT_CURVE", false)
```

#### getSurvivalProbability

##### 语法

```dolphindb
caplib::getSurvivalProbability(creditCurveHandle STRING, dates DATE[])
```

##### 详情

根据缓存 CreditCurve 为每个输入日期计算存活概率；输出保持输入顺序。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `creditCurveHandle` | STRING | 所引用具体类的 ObjectCache 句柄。 **有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。 |
| `dates` | DATE[] | 请求曲线值的日期；结果第 i 个元素对应 dates[i]。 **有效性:** 必须是无空值 DATE 向量。单日使用单元素向量，多日使用更长向量；不接受 DATE 标量。 |

##### 返回值

**返回：** DOUBLE 向量，元素顺序与输入一致。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::getSurvivalProbability(flatCreditCurve, curveDates)
```

#### getCreditSpread

##### 语法

```dolphindb
caplib::getCreditSpread(creditCurveHandle STRING, dates DATE[])
```

##### 详情

根据缓存 CreditCurve 为每个输入日期计算信用利差；输出保持输入顺序。

##### 参数

| 参数 | 类型 / 形状 | 说明 |
| --- | --- | --- |
| `creditCurveHandle` | STRING | 所引用具体类的 ObjectCache 句柄。 **有效性:** 必须非空并解析为所需 protobuf 类的现有 ObjectCache 条目。 |
| `dates` | DATE[] | 请求曲线值的日期；结果第 i 个元素对应 dates[i]。 **有效性:** 必须是无空值 DATE 向量。单日使用单元素向量，多日使用更长向量；不接受 DATE 标量。 |

##### 返回值

**返回：** DOUBLE 向量，元素顺序与输入一致。 **状态/错误行为：** 对于服务调用，`success=true` 表示已生成上述结果；`success=false` 表示没有有效结果，服务 `err_msg` 会写入 DolphinDB `RuntimeException`。仅包装器执行的操作不提供状态标量。参数验证、缓存类/句柄、解析和序列化错误也会抛出异常，因此所有错误都表现为异常，而不是备用标量或部分对象。

##### 示例

```dolphindb
loadPlugin("PluginCaplib")

caplib::getCreditSpread(flatCreditCurve, curveDates)
```

## 使用示例

以下示例展示固定收益债券定价的完整流程：加载插件、创建曲线和债券、配置定价与风险设置、组装市场数据、执行定价并输出结果。

```dolphindb
// =============================================================================
// DolphinDB caplib Plugin Example: FI Analytics
// =============================================================================
// This script is stripped from test/test_fianalytics.dos and shows the main
// fixed-income curve and bond pricing flow.

loadPlugin("PluginCaplib")

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

// Create the bond leg definition for the sample bond.
bondLeg = caplib::createBondLegDefinition(
    "FIXED_COUPON_BOND", 1, currency, "ACT_365_FIXED", "CAL_CFETS",
    "ANNUAL", "MODIFIED_FOLLOWING", "INITIAL", "LONG",
    0, "MODIFIED_FOLLOWING", "", "", "ANNUAL",
    "MODIFIED_FOLLOWING", "IN_ADVANCE", -1, "FI_BOND_LEG", false)

// Create the bond template used to build a vanilla bond.
bondTemplate = caplib::createVanillaBondTemplate(
    "CNY_TREAS_CPN_BOND", "FIXED_COUPON_BOND",
    2020.07.22, 1, 2020.07.22, "5Y",
    0.03, 100.0, 0.4, bondLeg, false)

// Build the vanilla bond instrument from its template.
vanillaBond = caplib::buildVanillaBond(
    1000000.0, bondTemplate, "", 2020.07.22, "FI_VANILLA_BOND", false)

// Create pricing settings for bond valuation.
pricingModel = caplib::createPricingModelSettings(
    "BLACK_SCHOLES_MERTON", "", 0, [0.0], "FI_MODEL", false)
pricingSettings = caplib::createPricingSettings(
    currency, "ANALYTICAL", 1, 1, pricingModel, "", "", "FI_PRICING", false)

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

## 附录

### Docker 部署

Docker 镜像构建、目录布局、启动、健康检查和故障排查见 [`docker/README.md`](../docker/README.md)。

```bash
bash docker/build.sh --test
```

### 编译说明

源码编译所需的 DolphinDB Plugin SDK、ABI0 版本 `dqlibc`、Boost、log4cplus、Protobuf、CMake 和 GCC 版本及命令见 [`BUILD_REQUIREMENTS.md`](../BUILD_REQUIREMENTS.md)。

### License 说明

Caplib 和 `dqlibc` 为专有软件。请通过 [caprisktech.com](https://caprisktech.com) 申请许可证。插件在服务调用前校验许可证，并缓存校验结果 3600 秒。

### 常见问题

| 现象 | 原因 | 处理方式 |
| --- | --- | --- |
| `Invalid plugin file` | 使用了包含 CMake 变量的源模板，或描述文件版本与 Server 不匹配 | 使用本仓库发行包内的 `PluginCaplib.txt`，并确保版本一致 |
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
