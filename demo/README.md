# caplib-dol

基于 DolphinDB + caplib 插件的债券定价、估值与市场风险（VaR / ES）计算工程。

库结构与全部基础数据都由 `sql/` 目录中的脚本提供。

---

## 快速开始（完整流程）

**1) 初始化数据库**（建库 + 全部表 + 加载基础数据）：

```bash
python bootstrap.py            # 仅重建库 + 基础数据
python bootstrap.py --deploy   # 同时把业务脚本写到服务端 scripts 目录
```

默认连接本地 8849，可用 `--host/--port/--user/--pass/--db` 覆盖；
加 `--keep` 可保留现有库、仅重载数据；`--deploy` 才会部署业务脚本（默认不部署），
服务端目标目录可用 `--server-scripts` 修改（默认 `/data/ddb/server/scripts`）。

**2) 在 DolphinDB GUI / Web 会话中加载业务脚本**（顺序敏感，必须按此序 run；
若上一步已 `--deploy`，这些文件即在服务端 `scripts` 目录中）：

```text
run "/data/ddb/server/scripts/create_calendar.dos"
run "/data/ddb/server/scripts/create_bond_templates.dos"
run "/data/ddb/server/scripts/build_yield_curve.dos"
run "/data/ddb/server/scripts/bond_pricing.dos"
run "/data/ddb/server/scripts/bond_risk.dos"
run "/data/ddb/server/scripts/pricing_batch.dos"
```

> 注：DolphinDB 的函数定义是会话级的，每个新工作会话开头都需 run 一次上述脚本。

**3) 定价 + 估值**（单日 或 区间）：

```text
computeOneDay(2025.01.27, 20)
computeRange(2025.01.02, 2025.02.28, 20)
```

**4) 市场风险**：情景曲线 -> 情景估值 -> VaR/ES（见下文「市场风险」）。

> ⚠️ 初始化默认会重建数据库（内含 dropDatabase，清空同名库）；
> 不想清空时使用 `python bootstrap.py --keep`。

---

## 目录结构

```
caplib-dol/
├── bootstrap.py              数据库初始化入口（建库 + 基础数据；--deploy 部署业务脚本）
│
├── create_calendar.dos           日历工具 + CFETS 日历初始化
├── create_bond_templates.dos     债券模板构建（非标 + 标准债）
├── build_yield_curve.dos         流动性(LIX)选债 + 收益率曲线构建
├── bond_pricing.dos              定价 / 估值（标准债 + 非标债）
├── bond_risk.dos                 情景曲线、情景估值、VaR/ES
├── pricing_batch.dos             批量驱动（单日 / 日期区间）
│
└── sql/                          数据库与基础数据
    ├── 00_create_database.dos        建库 + 全部表定义
    ├── t_calendar.dos                日历信息
    ├── t_bond_info.dos               债券信息
    ├── t_bond_day_kline.dos          债券日 K 线
    └── t_bond_yield_curve_def.dos    收益率曲线定义
```

---

## 数据库

- 路径：`dfs://caplib-bond`
- 存储引擎：`TSDB`
- 分区方式：`RANGE`，按自然年分区（边界 2000-01-01 ~ 2040-01-01）
- 维度表（DIMENSION）：`t_calendar`、`t_bond_yield_curve_def`、`t_bond_info`
- 事实表（分区表）：K 线、收益率曲线、定价、估值、情景曲线、情景估值、VaR
- 主键去重：`sortColumns` + `keepDuplicates=LAST`；单键维度表受 DolphinDB 限制
  （LAST/FIRST 要求至少 2 个 sort key）只能用 `ALL`，改由数据脚本插入前清空来保证
  「数据还原」幂等——因此重复执行 `bootstrap.py --keep` 不会让 `t_bond_info`、
  `t_bond_yield_curve_def` 累积重复行

### 表清单

| 表名 | 内容 |
|---|---|
| `t_calendar` | CFETS 节假日 + 调休营业日 |
| `t_bond_yield_curve_def` | 收益率曲线定义（MKT 市场 / STD 基准） |
| `t_bond_info` | 债券信息（标准债 + 非标准债） |
| `t_bond_day_kline` | 债券日 K 线（OHLCV） |
| `t_bond_yield_curve` | 每次构建的收益率曲线（par + zero rate） |
| `t_bond_pricing` | 债券定价结果 |
| `t_bond_valuation` | 债券估值结果 |
| `t_bond_yield_sim_curve` | 情景收益率曲线 |
| `t_bond_sim_valuation` | 情景估值 |
| `t_bond_var` | 损益、VaR / ES |

---

## 定价 / 估值

业务脚本必须按序 `run`（DolphinDB 在解析期校验函数名，后定义的函数不能在前面的脚本内调用）：

```text
run "create_calendar.dos"
run "create_bond_templates.dos"
run "build_yield_curve.dos"
run "bond_pricing.dos"
run "bond_risk.dos"
run "pricing_batch.dos"
```

单日完整链路（MKT 曲线 → 标准债定价 → STD 曲线 → 非标债定价 → 标准/非标债估值）：

```text
computeOneDay(2025.01.27, 20)
```

批量（区间内每个 CFETS 交易日逐日计算，`periods=20` 为 LIX 流动性窗口的交易日数）：

```text
computeRange(startDate, endDate, 20)              // 区间内全部交易日
computeByDates([2025.01.27, 2025.01.28], 20)      // 显式日期列表
```

> 上例的日期仅为示例，可按需要的交易日范围传参；基础数据实际覆盖范围以
> `t_bond_day_kline` 与 `t_bond_info` 中的日期为准。

### 标准债与非标债的区别

- **标准债（`std_flag=true`，CN_TREAS_*）**：每个基准日按当天曲线校准票面利率
  （par rate），按面值 100 发行，因此 `present_value` 恒≈100；期限信息体现在**票面利率**里。
- **非标债（存量债）**：票面利率在发行时即固定，估值日按当前曲线重新折现，
  `present_value` 反映价格涨跌（票息高于当前市场利率则溢价，低于则折价）。

---

## 市场风险（VaR / ES）

以基准日 `2025.01.27`、情景日 `2025.02.05` 为例，三步严格按序执行：

```text
// 1) 情景曲线：取基准日及之前的 STD 曲线，相邻日期两两配对，构建 N 个情景
buildSimYieldCurve(2025.01.27, "CN_TREAS_STD", 3)

// 2) 情景估值：幂等删除必须在函数【外】单独执行，然后调用
delete from loadTable("dfs://caplib-bond","t_bond_sim_valuation")
  where sim_date = timestamp(2025.02.05)
simValuationNonStdBonds(2025.02.05, 100, "CN_TREAS_STD")

// 3) VaR / ES
calcBondVarEs(2025.01.27)
```

依赖关系：`calcBondVarEs` 读取前两步产出的情景估值与当日估值，缺一不可。

- 损益 `PnL = 情景估值 present_value − 基准日估值 present_value`，按 `end_date` 倒序；
- VaR / ES 由插件 `calcVaR` / `calcExpectedShortfall` 计算（历史模拟法，样本不排序、原样传入）；
- `risk_value95` / `risk_value99` 各为：

```json
{
  "value_at_risk": …,
  "value_at_risk_mirrored": …,
  "expected_shortfall": …,
  "expected_shortfall_mirrored": …
}
```

---

## 主要函数

### 对外入口（业务调用）

| 函数 | 说明 |
|---|---|
| `computeOneDay / computeRange / computeByDates` | 批量定价估值驱动（单日 / 区间 / 显式日期列表） |
| `priceStdBonds(date)` / `valuationStdBonds(date)` | 标准债定价 / 估值 |
| `priceNonStdBonds(date)` / `valuationNonStdBonds(date)` | 非标债定价 / 估值 |
| `buildSimYieldCurve(date, curveCode, scenarioCount)` | 构建情景收益率曲线 |
| `simValuationNonStdBonds(simDate, nominal, curveCode)` | 非标债情景估值 |
| `calcBondVarEs(date)` | 计算损益、VaR / ES |
| `buildBondYieldCurveFromLix(date, periods, curveCode)` | 基于 LIX 选债构建收益率曲线 |
| `buildStdYieldCurve(date, curveCode)` | 用标准债 YTM 构建基准（STD）曲线 |

---

## 连接与部署

`bootstrap.py` 的默认连接参数（可用命令行参数覆盖）：

```text
host 127.0.0.1   port 8849   user admin   pass 123456   db dfs://caplib-bond
```

业务脚本（`*.dos`）由 `bootstrap.py --deploy` 通过 DolphinDB 会话直接写到服务端
`/data/ddb/server/scripts/`（服务端 `mkdir` + `file` 句柄落盘，并做字节数校验），
无需访问宿主机文件系统——远程服务器只要知道 DolphinDB 地址和账号密码即可部署，
可用 `--server-scripts` 修改服务端目标目录。例如：

```bash
python bootstrap.py --deploy --host 10.0.0.1 --port 8848 --user admin --pass xxx
```

> 前提：登录账号对服务端目标目录有写权限（官方镜像中 `/data/ddb/server/` 默认可写）。
