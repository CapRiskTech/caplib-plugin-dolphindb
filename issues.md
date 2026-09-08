# Caplib 插件测试问题清单（2026-09-03）

> 本文档整理自 `test/` 目录测试套件（DolphinDB 原生 `@testing:case` 框架）在开发与回归过程中**实测发现**的插件校验问题。
> **#1–#20 为 0.0.10 验证结论，0.0.11 已全部修复**（回归确认，对应校验已在按函数测试文件中作为 exception=1 用例覆盖）。
> **#21 起为 0.0.11 新发现**，每条已在 docker 容器（DolphinDB 3.00.5 + caplib 0.0.11）中验证。

---

## 一、类型校验缺失（INT/BOOL 参数接受字符串/空值）

| # | 函数 · 参数 | 喂入 | 插件行为 | 期望 |
|---|---|---|---|---|
| 1 | createIrCurveRiskSettings / createCreditCurveRiskSettings / createDividendCurveRiskSettings / createPriceRiskSettings / createVolRiskSettings / createPriceVolRiskSettings / createThetaRiskSettings 的 `method` | `"1"` | 接受 | 抛错（应为 INT 枚举） |
| 2 | createIrCurveRiskSettings `method` | `int()` | 接受 | 抛错 |
| 3 | createPdeSettings `tSize` | `"101"` | 接受 | 抛错 |
| 4 | createMonteCarloSettings `numSimulations` | `"8096"` / `int()` | 接受 | 抛错 |
| 5 | createScnSettings `numPoints` | `int()` | 接受 | 抛错 |
| 6 | createIrYieldCurveBuildSettings `useOnTnFxSwap` | `"0"`（字符串 BOOL） | 接受 | 抛错 |

## 二、数值边界校验缺失（负数 / 区间倒置 / 零）

| # | 函数 · 参数 | 喂入 | 插件行为 | 期望 |
|---|---|---|---|---|
| 7 | createEuropeanOption `nominal` | 负数 | 接受 | 抛错 |
| 8 | createFxForward `notional` | 负数 | 接受 | 抛错 |
| 9 | createFxSpotRate `spotRate` | 负数 | 接受 | 抛错 |
| 10 | buildCreditDefaultSwap `notional` | 负数 | 接受 | 抛错 |
| 11 | createScnSettings `lower` > `upper` | 倒置区间 | 接受 | 抛错 |
| 12 | createVolatilitySmile `lower` ≥ `upper` | 倒置区间 | 接受 | 抛错 |
| 13 | createMonteCarloSettings `numSimulations` | 0 | 接受 | 抛错 |

## 三、长度一致性校验缺失

| # | 函数 | 喂入 | 插件行为 | 期望 |
|---|---|---|---|---|
| 14 | createVolatilityCurve `pillarDates` / `vols` | 长度不一致 | 接受 | 抛错（createIrYieldCurve 同场景会抛错） |

## 四、向量空值校验缺失

| # | 函数 · 参数 | 喂入 | 插件行为 | 期望 |
|---|---|---|---|---|
| 15 | createCalendar `holidays`（INT[]） | `take(int(),0)` 零长度 / `[int(),int(),int()]` 全空 / `[44654,int(),44656]` 部分空 | 全部接受 | 抛错 |

## 五、非法枚举校验缺失

| # | 函数 · 参数 | 喂入 | 插件行为 | 期望 |
|---|---|---|---|---|
| 16 | createBondYieldCurveBuildSettings `curveType` | `"NOT_A_CURVE_TYPE"` | 接受 | 抛错（createIrYieldCurve 同场景会抛错） |

## 六、矩阵空值/形状校验不一致

| # | 函数 | 喂入 | 插件行为 | 期望 |
|---|---|---|---|---|
| 17 | createOptionQuoteMatrix | 部分空值矩阵 `matrix([10.5,double()],...)` | 接受 | 与 createIrCapFloorQuoteMatrix 一致（抛错） |

> 注：createIrCapFloorQuoteMatrix 对 0 行/0 列/部分空/全空矩阵**严格校验**，但 createOptionQuoteMatrix 对部分空值矩阵**不校验** —— 同类功能校验严格度不一致。

## 七、同类函数校验严格度不一致（建议优先处理）

| # | 不一致点 | 严格 | 宽松 |
|---|---|---|---|
| 18 | Risk settings 的 `method` 类型校验 | createCmRiskSettings / createEqRiskSettings 喂 `"1"` 抛错 | 其余 6 个 risk settings（ir/credit/div/price/vol/priceVol/theta）喂 `"1"` 接受 |
| 19 | 曲线 `pillarDates/pillarValues` 长度校验 | createIrYieldCurve 抛错 | createVolatilityCurve 接受 |
| 20 | 矩阵空值校验 | createIrCapFloorQuoteMatrix 抛错 | createOptionQuoteMatrix 接受 |

---

## 附：文档声明的设计行为（不算缺陷，勿改）

以下经 `docs/DQLIB_DOCUMENTATION.md` 确认是**有意设计**，不在上表问题范围内：

- **标量自动包装成向量**：createIborIndex / createFxSpotTemplate 的 `calendars`、createIrYieldCurveBuildSettings 的 `currency` 喂标量会**自动包装成单元素向量**（文档标注这些参数「可标量或向量」）。测试侧已作为正向「标量/向量组合」覆盖。
- **日期先后关系**：文档多处标注「包装器不检查此关系」（如 createIrYieldCurve 的 referenceDate 与 pillarDates 先后、calcYearFraction 的日期先后）。测试侧将这些作为「文档声明的宽松行为」记录，未写成期望抛错用例。

---

## 测试覆盖状态说明（0.0.10 部分）

- **#1–#20 已在 0.0.11 全部修复**，对应校验已在 `test/<域>/test_<函数名>.dos` 中作为 `exception=1` 用例覆盖。
- 当前测试套件运行方式：`python run_tests.py`（按子目录逐个 `test()` 并汇总）。

---

# 0.0.11 新发现问题（2026-09-08，按函数拆分测试时发现）

> 以下问题在为 202 个函数逐一建立 `test_<函数名>.dos` 时实测发现（Docker 3.00.5 + caplib 0.0.11）。
> 测试侧以「正向调用 + try/catch 记录实际行为」的方式覆盖（插件修复后自动转为真实正向断言）。

## 一、正向调用服务端报错（ProcessRequest failed with code: -1 / std::exception）

| # | 函数 | 输入 | 插件行为 | 备注 |
|---|---|---|---|---|
| 21 | createIrCapFloorQuoteMatrix | 有效 1×1 CAP 报价（1 期限 × 1 行权价） | ProcessRequest -1 | 负向校验正常；正向从未有成功案例 |
| 22 | buildIrCapFloor | 有效 swap/capfloor 模板 + "CAP" | ProcessRequest -1 | type 全标签形式 `buildIrCapFloorInput_Type_CAP` 反而报 Unknown type |
| 23 | buildIrEuropeanSwaption | CASH_SETTLEMENT / PHYSICAL_SETTLEMENT + 有效模板 | ProcessRequest -1 | "PHYSICAL"/"CASH" 报 Unknown settlementType |
| 24 | priceIrCapFloor / priceIrEuropeanSwaption | 依赖 #22/#23 的工具 | 无法构建工具 | 阻塞链 |
| 24a | buildIrCapFloorVolatilitySurface | 依赖 #21 的报价矩阵 + 有效定义/曲线 | ProcessRequest -1 | 即使跳过 #21 也独立复现 |
| 25 | calcIrVanillaSwapRate | 有效 swap 模板 + 曲线 | ProcessRequest -1 | 疑似依赖内部静态数据键（见二） |
| 26 | calcIborIndexRate | 有效 iborIndex + 曲线 | ProcessRequest -1 | 同上 |
| 27 | calcTenorBasisSwapSpread | 有效模板 + 三条曲线 | ProcessRequest -1 | 同上 |
| 28 | calcCrossCurrencySwapRate / calcCrossCurrencyBasisSwapSpread | 有效模板 + 双币种曲线 | ProcessRequest -1 | 同上 |
| 29 | buildPmYieldCurve | createPmParRateCurve（DATE 节点表/期限表均试） | "empty par rate curve" | PM 平价曲线对象本身创建成功 |
| 30 | buildPmVolatilitySurface | 有效 PM 报价矩阵/定义/惯例/模板 | std::exception | PM 阻塞链 |
| 31 | priceIrCrossCurrencySwap / priceIrMtmCrossCurrencySwap | createIrVanillaInstrumentTemplate(CROSS_CURRENCY_SWAP/MTM) 构建的工具 | std::exception | 模板与工具均构建成功 |

## 二、内部键查找与句柄脱节（设计缺陷）

| # | 函数 | 行为 |
|---|---|---|
| 32 | buildIrSingleCurrencyCurve | 报 "can not find DEPOSIT/CNY_SHIBOR_3M in the object cache" —— 按币种+指数名拼内部键查找，与传入的 iborIndex 句柄不关联 |
| 33 | buildIrCrossCurrencyCurve | 报 "can not find FX_SPOT/CNYUSD" —— 按货币对拼内部键查找；即便把句柄命名为 `FX_SPOT/CNYUSD` 也找不到（疑似走静态数据注册表而非 ObjectCache） |
| 34 | createStaticData | 字节输入是序列化 protobuf，DolphinDB 脚本内无法构造；`staticDataType` 合法值为 `SDT_CALENDAR` 等 SDT_* 标签（文档示例外的 "CALENDAR" 报 Unknown） |

## 三、bytes/序列化输入类（脚本不可测正向）

| # | 函数 | 说明 |
|---|---|---|
| 35 | createIrSwaptionQuoteCube | inputBytes 为 IrSwaptionQuoteCube protobuf；"X" 输入 ProcessRequest -1。**连带阻塞 buildIrSwaptionVolatilitySurface 的正向覆盖**（其 quoteCubeHandle 只能来自 #35） |
| 36 | calcZSpread | bondBytes/curveBytes 为序列化对象；喂占位串报 vector::_M_range_check |
| 37 | priceFxTimeOption | FX_TIME_OPTION 工具只能经序列化字节创建（createIrVanillaInstrumentTemplate("FX_TIME_OPTION") 报 not find value），正向不可达 |

## 四、其他不一致 / 稳定性

| # | 现象 |
|---|---|
| 38 | **服务器段错误**：单会话顺序跑全部 202 个 per-function 文件时观察到一次 DDB 进程 SIGSEGV（容器 exit 139），复现率低（约 1/5 次），疑似重度用例内存压力或某个 PM/句柄缺失调用触发；重启后全量可绿。 |
| 39 | dcc 枚举不一致：calcImpliedRepoRate 只接受 `ACT_360` / `ACT/365` 等短/斜杠形式，`ACT_365_FIXED`/`ACTUAL_*` 报 Unknown day count；而 createIrYieldCurve 接受全部 16 种别名。 |
| 40 | INT 参数宽松程度不一致：createMonteCarloSettings 的 `seed`/`uniformNumberType`/`wienerBuildMethod`/`gaussianMethod`/`numSteps`、create*RiskSettings 的 `granularity`、createPdeSettings 的 `xSize` 接受 STRING/"1" 等错误类型（强转成功即过），而同函数的 `numSimulations`/`method` 严格拒绝。 |
| 41 | calcFxPrice 语义存疑：`calcFxPrice(1000.0, "USD", "CNY", 6.9, "USD", "CNY")` 返回 144.93（按汇率相除），预期按 USDCNY 折算应为 6900；`("CNY","USD",6.9,"USD","CNY")` 返回 6900。参数含义与文档描述对不上，建议插件团队确认。 |
| 42 | 文档 vs 注册 arity 不一致（16 个函数）：如 createVanillaBondTemplate 文档列 27 个必填但注册 minArgs=10；createIborIndex 文档 10 参上限 vs 注册 11；多个期权工厂 docs-required 比 minArgs 多 3。建议文档侧核对。 |
| 43 | createFxSwapTemplate | 文档列 8 个必填但注册 minArgs=6；按 6 参调用（省略 fixingOffset/fixingDayConvention）报 `Parameter startDelay must be a scalar` —— 6 参形式的参数绑定错位，实参被错配到 startDelay 位置 |
| 44 | createCalendar | 返回 BOOL（成功 true），与其它 create* 工厂返回 ObjectCache 句柄的约定不一致；调用方无法通过返回值引用新建的日历 |

> #21–#37 均已在对应 `test_<函数名>.dos` 中以「try/catch 记录实际行为」覆盖；插件修复后这些文件的正向断言自动生效。

---

## 测试覆盖状态说明（0.0.11 部分）

- **#21–#37（正向不可达）**：在对应 `test_<域>/test_<函数名>.dos` 中以「try/catch 记录实际行为」覆盖（18 个 try/catch + 4 个 bytes 待补注记）；插件修复后正向断言自动生效。
- **#38–#44（不一致/稳定性）**：记录备查。
- 当前测试套件：202 个按函数文件按 7 个域子目录组织，共 499 用例，`python run_tests.py` 全量绿。
