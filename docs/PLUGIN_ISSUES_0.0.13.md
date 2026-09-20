# 插件未决问题清单（0.0.13 实测，2026-09-18）

> 本清单为 `PLUGIN_ISSUES_0.0.13.md` 的收敛版：**已修复章节全部删除**（A 数值边界、B 空值/空容器、
> C 类型/句柄/枚举、D 业务规则、E 枚举集文档不一致、G 多曲线容器查询——145 处 lenient 用例已翻转为
> `exception=1` 负例，处理明细见文末"已修复归档说明"与 git 历史版本）。
> 本文仅保留**尚未解决**的问题与按实测保留的宽松行为记录。

- **验证环境**：全新容器 `caplibdolphin-test`（删除旧容器与全部插件缓存后重建，镜像内插件与
  `caplib-plugin-dolphindb-0.0.13.tar.gz` 5 个文件逐字节比对一致；BUILD_INFO：source_commit
  `f3e0fc14aa2882eba4b986b5bfdfac8e18a33e1d`）
- **验证结果**：冒烟 7/7；全量回归 180 文件 / 2685 用例（含 145 条翻转负例）多次执行通过
- **测试套件**：`test/` 下 180 个接口测试文件、2685 个用例（DolphinDB `test()` 框架）

---

## F. priceCreditDefaultSwap 疑似非确定性（唯一未决项）

**现象**：满负载下偶现**相同输入两次定价结果差异超过 1e-9 相对容差**。

用例（`test/cr/test_priceCreditDefaultSwap.dos`）：

```dolphin
@testing:case="priceCreditDefaultSwap deterministic repeat -> identical result"
r1 = caplib::priceCreditDefaultSwap(cds, asOfDate, mktData[0], pricingSettings[0], crRisk[0], "", "", true);
r2 = caplib::priceCreditDefaultSwap(cds, asOfDate, mktData[0], pricingSettings[0], crRisk[0], "", "", true);
assert 1, abs(presentValue(r1) - presentValue(r2)) <= 1.0e-9 * (abs(presentValue(r1)) + 1)
```

**证据汇总（截至 2026-09-18）**：

| 试验 | 结果 |
|---|---|
| 全量回归（旧容器） | 3 次中 1 次失败 |
| 全量回归（全新容器，无跨运行缓存） | 2 次中 1 次失败 |
| 单文件连续 5 次 | 全部通过 |
| cr 域单独 3 次 | 全部通过 |

- 失败时 PV≈-4324，两次结果差值超过 4e-6，**远超浮点噪声量级**，更像状态依赖的计算路径差异。
- 失败条件为**容器内多文件连续执行的负载/调度顺序**（全新容器排除了跨运行共享状态归因）。
- 用例已加 `FLAKE-DEBUG` 打印（pv1/pv2/差值）并保留，复现时全量回归日志可直接给出两个 PV 数值。

**当前定性**：插件侧 `priceCreditDefaultSwap` 为纯服务透传、无浮点全局状态；差异定性为
dqlib 服务端/共享环境的并行归约顺序问题，建议由**服务端侧**排查（超出插件可修范围）。
独立复验补充：范围可收窄到"容器内多文件连续执行"场景。

**建议排查方向**：dqlib 服务端在连续调用下的全局状态、并行归约顺序、未排序容器遍历。

---

### F 复现与排查实验（2026-09-20）

> 本轮实验在**当前 0.0.13 构建**（f3e0fc14 + 全部校验修复）上完成。两个探针均为一次性构造
> （未入库，方法可按本描述重建）：① 容器内探针：复刻 `test/cr/test_priceCreditDefaultSwap.dos`
> fixture 后对同一 CDS 连续定价 2000 次并按 1e-9 相对容差比对 PV；② 纯 Python 探针：用 caplib
> 参考客户端复刻 fixture 直连 dqlib gRPC 服务，循环定价并比较序列化结果（纯重复 300 次、
> 每 10 次插入独立句柄对象作负载 2000 次两种模式）。需要时可据此重新生成并交付 dqlab。

| 实验 | 结果 |
|---|---|
| 容器内满 ObjectCache 状态，同一 CDS 连续定价 **2000 次** | **0 漂移**（firstPV=-4324.565959039959125，与失败记录 PV≈-4324 同源） |
| 远端 gRPC 服务（同一 dqlibc 代码）纯重复 **300 次** | 字节级完全一致（1 个 distinct 序列化结果） |
| 远端 gRPC 服务含缓存对象 churn 负载 **2000 次** | 字节级完全一致，PV=24471.59400631445 零漂移（不同 fixture 数值，另一曲线组） |
| 全量回归 **3 次**（180 文件 / 2685 用例，FLAKE-DEBUG 埋点） | 3/3 通过，三次均为 `pv1 == pv2 == -4324.565959039959125, diff=0` |

**结论更新：**
1. dqlibc 的 CDS 定价路径在**重复调用下是确定的**——无论容器内进程环境还是独立 gRPC 服务，
   无论有无对象缓存负载，都未复现漂移。排除"每次调用随机并行归约"假设。
2. 历史失败需要**特定的多文件执行序列 + 环境状态**才触发，本轮（5+ 次全量）未能复现。
3. FLAKE-DEBUG 打印保留在用例中：**后续任何一次全量回归若复现，日志将直接给出 pv1/pv2**——
   届时对比 pv1/pv2 与基线值 -4324.565959039959125 即可判断"两次都偏"还是"单次偏离"，
   这是下一步定位的关键分叉。
4. 若 pv1/pv2 均等于基线但用例失败，则漂移发生在 `presentValue` 解析或结果序列化层（插件侧可查）；
   若其中一个偏离基线，则该次调用的输入或服务路径与另一次不同（服务端状态依赖）。

**当前维持**：插件侧无可修点；继续以 FLAKE-DEBUG 埋点在全量回归中守候复现。

---

## 附：按实测保持宽松的 10 处记录（非缺陷，存档备查）

以下行为经确认具有业务合理性或用例推导有误，用例保留 lenient 记录并注明理由，**无需插件修改**：

1. `calcFxDeltaToStrike` 负 delta：有业务语义（对应 PUT），插件按符号区分期权类型。
2. `getVolatility` termDates vs strikes 长度不等：矩阵请求的行列维度，本就不要求相等。
3. `createCalendar` holidays vs specialBusinessDays：两个独立清单，无配对语义。
4. `createFloatingLegDefinition` / `createIrLegDefinition` / `createFraTemplate` 的 calendars vs
   fixingCalendars：付款日程与定盘日程相互独立，套件含独立长度的正向用例。
5. `createPingPongOption` / `createRangeAccrualOption` asset=0：纯现金支付合法（FX 定价 fixture 在用）。
6. `createVolatilityCurve` / `createVolatilitySmile` vols=0：CM quanto 调整使用零波动率曲线。
7. `createCdsTemplate` referencePrice=0：CDS 市场惯例（负值仍拒绝）。
8. `buildEqIndexDividendCurve` 空 futurePrices：空 + 有效 optionPrices 即文档签名的期权价模式。
9. `createScnAnalysisSettings` / `calcFxDeltaToStrike` 两条 wrong-object-type 用例：fixture 传入的
   本就是正确类型的句柄，原用例推导有误，已注明恢复宽松。

---

## 已修复归档说明

0.0.13 后续构建已修复以下问题（原清单章节随之删除，明细见 git 历史版本与本文件的前一版本）：

- **A 数值边界**（约 60 处）：nominal/asset/buyAmount/barrier/rebate/strike/vols/hazardRate/spotPrice/
  underlyingPrice/scaling/term 拒绝 0 或负值。
- **B 空值/空容器/长度配对**（约 30 处）：标量 null、全空/部分空向量、成对数组长度校验。
- **C 类型/句柄/枚举**（约 25 处）：错误子类型句柄显式报错、标量位拒绝向量、proto 枚举全量解析。
- **D 业务规则**：`createFxForward`/`createFxSwap`（两腿）/`createFxNonDeliverableForward` 拒绝
  expiry 晚于 delivery，swap 另拒绝 far 腿早于 near 腿。
- **E1**：`buildPmYieldCurve` dayCount 改用共享解析，`ONE_ONE`/`BUSINESS_252` 可用。
- **E2**：文档 instType 清单删除 25 个被拒跨资产类型与全部 `INVALID_*` 哨兵标签。
- **G**：无需新接口——`buildIrSingleCurrencyCurve`/`buildIrCrossCurrencyCurve` 的 `targetCurveHandles`
  参数即逐条输出句柄，构建后的每条目标曲线可直接传给 `getZeroRate` 等访问器（用法已补入 md/html）。

验证：发行仓库全量套件 `PASSED 2685/2685`；源仓库回归 161/161、官方镜像冒烟 7/7 全绿。
