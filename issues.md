# Caplib 插件测试问题清单（待处理）

> 已修复项已从清单中删除：**#1–#20（0.0.10 校验缺失，0.0.11 修复）、#32（测试侧 bug，已改纯 swap parCurve）、#34（SDT_* 标签有效）、#39/#40/#43（0.0.12 修复）**。
> 下表仅保留插件侧仍待处理的问题，按 0.0.11/0.0.12 实测记录。

## 一、正向调用服务端报错（ProcessRequest -1 / std::exception）

| # | 函数 | 输入 | 插件行为 | 备注 |
|---|---|---|---|---|
| 1 | createIrCapFloorQuoteMatrix | 有效 1×1 CAP 报价（1 期限 × 1 行权价） | ProcessRequest -1 | 负向校验正常；正向从未有成功案例 |
| 2 | buildIrCapFloor | 有效 swap/capfloor 模板 + CAP | ProcessRequest -1 | type 全标签形式反而报 Unknown type |
| 3 | buildIrEuropeanSwaption | CASH_SETTLEMENT / PHYSICAL_SETTLEMENT + 有效模板 | ProcessRequest -1 | PHYSICAL/CASH 报 Unknown settlementType |
| 4 | priceIrCapFloor / priceIrEuropeanSwaption | 依赖 #22/#23 的工具 | 无法构建工具 | 阻塞链 |
| 5 | buildIrCapFloorVolatilitySurface | 依赖 #21 报价矩阵 + 有效定义/曲线 | ProcessRequest -1 | 即使跳过 #21 也独立复现 |
| 6 | calcIrVanillaSwapRate | 有效 swap 模板 + 曲线（含先建互换工具） | ProcessRequest -1 | 真缺陷：2026-09-11 重新探测 正确初始化全部产品仍 -1，非前置缺失 |
| 7 | calcIborIndexRate | 有效 iborIndex + 曲线 | ProcessRequest -1 | 真缺陷：产品全 init 仍 -1 |
| 8 | calcTenorBasisSwapSpread | 有效模板 + 三条曲线 | ProcessRequest -1 | 真缺陷：产品全 init 仍 -1 |
| 9 | calcCrossCurrencySwapRate / calcCrossCurrencyBasisSwapSpread | 有效模板 + 双币种曲线 | ProcessRequest -1 | 真缺陷：产品全 init 仍 -1 |
| 10 | buildPmYieldCurve（根因 #10a） | createPmParRateCurve 的 Pillar 列表在 DolphinDB 侧解析不出 | empty par rate curve | 见 #10a |
| 10a | createPmParRateCurve pillarsTable | 无论传 table（2 列/4 列且列名匹配 instrument_name/type/term/rate）、tuple、matrix、嵌套 tuple，返回 JSON 均显示"pillars":[]；Python 侧同数据可正确生成带 pillar 对象并跑通 buildPmYieldCurve | 疑似 DolphinDB 适配层 pillarsTable→Pillar 列表解析缺陷，需插件侧确认 | 测试侧已穷举 6 种形态均空 |
| 11 | buildPmVolatilitySurface | 有效 PM 报价矩阵/定义/惯例/模板 | std::exception | PM 阻塞链 |
| 12 | priceIrCrossCurrencySwap / priceIrMtmCrossCurrencySwap | createIrVanillaInstrumentTemplate(CROSS_CURRENCY_SWAP/MTM) 构建的工具 | std::exception | 模板与工具均构建成功 |

## 二、需序列化 bytes / 产品初始化（脚本不可测正向）

| # | 函数 | 说明 |
|---|---|---|
| 13 | buildIrCrossCurrencyCurve | 需先 createStaticData(SDT_FX_SPOT, bytes) 注册 —— 待 bytes 样例 |
| 14 | createIrSwaptionQuoteCube | X 输入 ProcessRequest -1 —— 连带阻塞 buildIrSwaptionVolatilitySurface 正向 |
| 15 | calcZSpread | 喂占位串报 vector::_M_range_check —— 待 bytes 样例 |
| 16 | priceFxTimeOption | createIrVanillaInstrumentTemplate(FX_TIME_OPTION) 报 not find value —— 正向不可达 |

## 三、其他记录（设计/文档/稳定性）

| # | 现象 | 说明 |
|---|---|---|
| 17 | 服务器段错误 | 重启后全量可绿 —— 0.0.12 运行未复现 |
| 18 | calcFxPrice 语义存疑 | 参数含义与文档描述对不上 —— 建议插件团队确认 |
| 19 | 文档 vs 注册 arity 不一致 | 建议文档侧核对 —— | |
| 20 | createCalendar 返回 BOOL | 调用方无法通过返回值引用新建日历 —— 设计约定，记录备查 |

当前测试套件：180 个按函数测试文件按 7 个域子目录组织（0.0.12 相对 0.0.11 移除 23 个接口、重新加入 calcFixedCpnBondParRate），`python run_tests.py` 全量绿（0.0.12 新构建：1874 用例 0 失败，2026-09-15 全量实测）。
