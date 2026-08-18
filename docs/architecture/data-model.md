# 数据模型与业务规则

## 0. 数据层次与不变量

| 层次 | 类型/状态 | 产生位置 | 是否持久化 | 允许谁修改 |
| --- | --- | --- | --- | --- |
| 事实 | `MenstrualDay[]` | 手动记录、确认导入、Preferences 恢复 | 是 | 只有 `Index` |
| 输入候选 | `DateCandidateResult` | 文本/JSON 解析 | 否 | 解析器生成，用户可通过文本框改变输入 |
| 校验结果 | `ImportValidationResult` | `ImportValidator` | 否 | `Index` 保存到当前导入会话 |
| 统计派生 | `PeriodSummary[]`、`Prediction` | `MenstrualData` | 否 | 由事实和 today 重新计算 |
| 布局/刷新 | `RuntimeLayoutMetrics`、`dataRevision` | 页面壳/Index | 否 | UI 生命周期控制 |

必须保持的单向关系：

    输入候选 -> 校验结果 -> 用户确认 -> MenstrualDay[] -> 本地存储
    MenstrualDay[] -> 周期统计/预测/日历标记/JSON 导出

统计、预测和布局结果不能写回 `MenstrualDay`；解析和校验阶段不能直接修改事实数据。

## 1. 数据分层

```text
事实数据
  MenstrualDay[]
      │
      ├─ normalizeDays ─> 稳定、去重、升序的日期集合
      ├─ derivePeriods ─> PeriodSummary[]
      └─ predictNextPeriod ─> Prediction

导入输入
  文本 / JSON 文件
      ├─ DateCandidateResult
      └─ ImportValidationResult
              └─ 用户确认后才转回 MenstrualDay[]
```

设计核心是“日期集合为唯一事实来源”。经期时长、历史柱体和预测全部可重算，不应在本地或 JSON 中额外保存派生字段。

## 2. 核心类型

### `MenstrualDay`

```ts
interface MenstrualDay {
  date: string;                    // YYYY-MM-DD，本地日历日期
  source: 'manual' | 'import';
}
```

`source` 只用于记录来源；当前统计不区分来源。日期字符串的字典序与时间先后等价，代码大量使用这一性质比较未来日期和排序。

`source` 是 ArkTS 类型约束，不是 `MenstrualData.normalizeDays()` 的运行时校验规则。JSON 文件解析会检查输入来源，但本地 Preferences 恢复和导出前规范化不会重新检查；当前代码不能保证所有进入 `MenstrualDay[]` 的 `source` 在运行时都属于两个枚举值。

### `PeriodSummary`

```ts
interface PeriodSummary {
  startDate: string;
  endDate: string;
  durationDays: number;
  ongoing: boolean;
}
```

它是 `derivePeriods` 的派生输出，不持久化。每个已保存日期都被解释为一个经期起点：

- 有下一条日期：`endDate = nextDate - 1 day`，`durationDays = dayDistance(startDate, nextDate)`，`ongoing=false`。
- 没有下一条日期：`endDate = today`，`durationDays = max(1, dayDistance(startDate, today))`，`ongoing=true`。
- 未来日期先被过滤，不进入派生结果。

注意：当前实现的进行中时长使用 `dayDistance(startDate, today)`，再用 `max(1)` 保底；它不是“起止日期含首尾”的 `+1` 算法。现有产品设计文档对这一点有不同表述，后续应以产品意图补测试后再决定是否调整，不能在无验收的重构中顺手改变。

### `Prediction`

```ts
interface Prediction {
  label: string;
  available: boolean;
}
```

`Prediction` 是兼容当前历史页的轻量文案；内部同时生成 `CycleForecast` 和 `OvulationPrediction`。当前规则：

1. 将所有已派生的开始日排序，少于 3 个开始日时不生成预测。
2. 取最近最多 12 个周期间隔。
3. 使用线性时间权重构建周期长度经验分布，越接近当前的间隔权重越大。
4. 以 ±2 天高斯核平滑分布，并提取相对峰值 60% 以上的连续日期序列。
5. 以加权平均作为中心周期长度，并以最新一次开始日生成中心月经日期。
6. 以中心月经预测日向前 14 天得到排卵中心，并用 11–17 天黄体期生成排卵窗口。

这是透明的日历估算，不是医学结论；当前 UI 仍只展示下一次月经日期，排卵预测结果暂不持久化。`OvulationPredictionStrategy` 为后续 skin temperature 数据接入保留替换边界。

## 3. 规范化与不变量

### `normalizeDays`

`MenstrualData.normalizeDays`：

1. 丢弃 `date` 不是合法 `YYYY-MM-DD` 的条目。
2. 以日期为键放入 `Map`，重复日期后出现的条目覆盖前一条的 `source`。
3. 按日期升序输出。

它不主动过滤未来日期。因此当前代码的“未来日期不可记录”主要由日历点击和导入校验保证；如果本地存储中已经存在未来日期，`derivePeriods` 会在统计时过滤，但日历仍可能依据原始 `markedDays` 显示其标记。阶段 0 已用测试固定这一边界。

重复日期以最后出现的条目为准，后出现条目的 `source` 会覆盖前一条；规范化只保证日期键唯一、合法和升序，不保证输入数组的每个元素都具备完整的运行时对象形状。

### 日期工具 `DateUtils.ets`

- `toDateKey` / `todayKey`：生成本地 `YYYY-MM-DD`。
- `parseDateKey`：按本地年月日构造 `Date`，不解析带时区的日期字符串。
- `addDays` / `dayDistance`：日期加法和日差计算。
- `isValidDateKey`：同时验证格式和构造后的年月日一致性，能拒绝非法闰日、月份和日期。
- `formatShortDate`：用于 UI 的月日短文案。

`parseDateKey`、`addDays`、`dayDistance` 和 `formatShortDate` 都要求调用方先提供合法日期键；`parseDateKey` 本身会接受 `Date` 的进位结果，不是错误抛出型解析器。生产路径依赖上游的 `isValidDateKey` 或 `normalizeDays` 满足这个前提。

## 4. 导入模型

### 候选结果协议

```ts
interface DateCandidateResult {
  dates: string[];
  invalidTokens: string[];
  duplicateDates: string[];
}
```

`parseTextDates` 支持带分隔符的年月日、中文年月日、两位年份、无年份日期、固定长度紧凑数字日期，并把无法识别但含数字的片段放入 `invalidTokens`。无年份使用传入的当前年份；生产路径默认使用运行时当前年份，测试可注入年份。

解析器只负责语法识别，不判断未来日期、不判断与本地记录冲突，也不写入数据。

`parseJsonDateCandidates` 要求：

- 根节点为对象。
- `schemaVersion === 1`。
- `exportedAt` 是可解析的非空字符串。
- `days` 是数组。
- 每个条目有合法日期和 `manual/import` 来源。

合法日期去重后返回；重复、非法日期、缺失日期或非法来源都保留为问题。未知字段不参与校验。文件读取由 `JsonTransfer` 限制为大于 0 且不超过 4 MiB，再交给解析器。

### `ImportValidationResult`

```ts
interface ImportValidationResult {
  candidateDates: string[];
  validDates: string[];
  futureDates: string[];
  duplicateDates: string[];
  existingDates: string[];
  invalidTokens: string[];
}
```

`validateImportDates` 的输入包含解析日期、解析问题、当前已有日期和 `today`。输出规则：

- `candidateDates`：格式合法且去重后的输入日期，包括未来和已有日期。
- `futureDates`：大于 `today` 的候选。
- `existingDates`：非未来且已存在于本地的候选。
- `validDates`：既非未来、又不在已有集合中的候选。
- `duplicateDates`、`invalidTokens`：保留解析阶段的问题并去重。

`duplicateDates` 是报告信息，不是排除集合：`candidateDates` 已经去重，重复日期仍可以在 `validDates` 中保留一次。重复项可能不在 `candidateDates` 中，例如 JSON 解析阶段已经把重复项从 `dates` 中省略；确认页不能只依赖一个数组生成完整问题行。

确认前不会修改 `markedDays`；确认后 `Index` 将 `validDates` 映射为 `source='import'` 的 `MenstrualDay`。

## 5. 本地存储

`PreferencesStore` 使用 ArkData Preferences：

| 键 | 类型 | 内容 |
| --- | --- | --- |
| store name `hercula-local-data` | - | 应用本地 Preferences 容器 |
| `menstrual-days` | string | `MenstrualDay[]` 的 JSON，读写时经过 `normalizeDays` |
| `welcome-shown` | boolean | 是否已经展示过首次欢迎弹窗 |

`PreferencesStore` 对每次操作返回明确状态：读取返回 `{ status, days/seen }`，写入返回 `{ status }`；`open()` 失败映射为 `unavailable`，读取或解析失败映射为 `failed`，成功路径映射为 `success`。失败时仍提供空日期或 `false` 降级值，`Index` 当前只消费这些降级字段并保持原有页面行为，不显示新增错误。当前没有显式迁移版本、删除数据入口或事务级跨键一致性模型。

本地 `menstrual-days` 只保存 `MenstrualDay[]` JSON，没有 `schemaVersion`。读取时只要 JSON 解析或规范化抛出异常，整个读取结果就回退为空数组；这不是逐条隔离坏数据的恢复策略。

## 6. JSON 文件契约与文件边界

导出文件的核心形状由 `JsonTransfer` 内部的 `HerculaExportFile` 表达：`schemaVersion`、`exportedAt`、`days`。该类型不作为跨模块协议导出；导出前调用 `normalizeDays`，文件选择和保存由系统 `DocumentViewPicker` 完成。

当前导入使用 `selectDateCandidates`，先把 JSON 日期回填到文本导入窗口，再走统一的文本继续/确认路径。文件候选加载不直接创建 `MenstrualDay`，确认阶段由 `createImportedDays` 统一创建导入事实。

`DateCandidateResult` 不保留每条 JSON 日期的 `source`；当前确认落库会把所有新日期统一标记为 `source='import'`。`selectDateCandidates` 返回 `JsonCandidateLoadResult`，用 `status` 区分取消、读取失败、空文件、超大文件和成功；Index 当前只消费成功候选，非成功状态保持静默。完整导入时序和这些边界见[第七步导入链路解析](./07-import-pipeline.md)。

`PreferencesStore` 的 `PreferencesOperationStatus` 和各操作结果类型只在存储模块内部表达降级结果，不是页面或其他数据模块的公共类型；`PreferencesBackend` 仍作为测试注入接口保留。

本地持久化、日期工具、事实规范化、周期派生和预测函数的调用前提见[第八步数据基础层解析](./08-data-foundation.md)。

## 7. 必须保持的业务不变量

后续重构不得破坏：

1. 日期键格式为合法本地 `YYYY-MM-DD`。
2. 同一天最多一条事实记录。
3. 手动点击未来日期无效。
4. 导入未来日期、重复日期、已有日期和非法内容在确认页可区分，只有 `validDates` 写入。
5. 导入取消、解析失败和导出失败不覆盖已有事实数据。
6. 统计和预测从事实日期重新派生，不从旧 UI 状态或缓存结果读取。
7. 事实数据默认只写应用本地；文件操作必须由用户主动选择文件。
