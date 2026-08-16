# 第七步：导入链路解析

解析对象：

- `entry/src/main/ets/domain/TextDateParser.ets`
- `entry/src/main/ets/data/JsonTransfer.ets`
- `entry/src/main/ets/domain/ImportValidator.ets`
- `entry/src/main/ets/pages/Index.ets` 中的导入编排方法

本章只讨论输入如何变成候选日期、问题分类和最终写入数据。导入链路的核心边界是：解析和校验阶段不能修改 `markedDays`，只有用户在确认页点击确认后，`Index.confirmImport()` 才能写入事实数据。

## 1. 当前页面实际使用的链路

```text
用户输入文本
  └─ TextImportComponent
       └─ Index.continueTextImport()
            ├─ TextDateParser.parseTextDates()
            └─ ImportValidator.validateImportDates()

用户选择 JSON
  └─ JsonTransfer.selectDateCandidates()
       └─ parseJsonDateCandidates()
            └─ Index.loadJsonIntoTextImport()
                 └─ 回填 TextArea
                      └─ 上面的文本解析与校验链路

ImportValidationResult
  └─ ImportConfirmationComponent
       └─ Index.confirmImport()
            └─ validDates -> MenstrualDay(source='import')
                 └─ markedDays -> PreferencesStore.saveDays()
```

当前页面没有直接使用 `JsonTransfer.import()`。因此 JSON 文件不是直接转成 `MenstrualDay[]` 写入，而是先转为日期文本和问题列表，再与文本输入共用确认流程。

## 2. `TextDateParser`：文本语法识别

### 2.1 存在目的

`TextDateParser` 把用户输入的自由文本转换成三个结果集合：

```ts
interface TextDateParseResult {
  dates: string[];
  invalidTokens: string[];
  duplicateDates: string[];
}
```

它只回答“文本中识别到了哪些日期、哪些内容明确无效、哪些日期重复”，不回答：

- 日期是否晚于今天；
- 日期是否已经存在于本地记录；
- 用户是否确认导入；
- 是否写入 Preferences。

### 2.2 实际支持的表达式

代码中的两个全局正则共同提供以下输入：

| 形式 | 示例 | 结果 |
| --- | --- | --- |
| 四位年份加分隔符 | `2026-08-14`、`2026/8/14`、`2026.08.14` | 标准日期键 |
| 两位年份加分隔符 | `26-08-14`、`26/8/14` | 年份补成 `2026` |
| 中文年月日 | `2026年8月14日`、`26年8月14日` | 标准日期键 |
| 省略年份 | `8-14`、`8/14`、`8.14`、`8月14日` | 使用传入的 `currentYear` |
| 固定长度紧凑数字 | `20260814`、`260814`、`0814` | 按 8/6/4 位拆分 |

`parseTextDates()` 使用空格、换行、逗号、顿号、分号、竖线等分隔输入，再对每个 token 提取日期表达式。输入中没有数字且没有日期表达式的文字会被忽略；含数字但没有任何表达式的 token 会进入 `invalidTokens`。

日期格式化后统一通过 `isValidDateKey()` 检查，因此非法闰日、月份、日期和混合分隔符会被标记为无效，而不会进入 `dates`。

### 2.3 重复处理

`dates` 只保留第一次出现的标准日期键；后续相同日期进入 `duplicateDates`，并且 `duplicateDates` 自身也去重。重复判断发生在解析阶段，比较的是标准化后的日期键，不是原始输入字符串。

例如：

```text
2026-08-14 2026/08/14 26年8月14日
```

结果是：

```text
dates          = ['2026-08-14']
duplicateDates = ['2026-08-14']
invalidTokens  = []
```

### 2.4 一个必须保留的解析边界

解析器是“从 token 中提取日期”，不是“要求整个 token 完全等于日期”。已有测试覆盖了“经期开始：2026-08-03”这类带说明文字的输入。因为正则不是整 token 锚定匹配，日期旁边的其他文字不会导致该日期失效；后续不能直接改成整行严格匹配，否则会改变当前文本输入行为。

## 3. `JsonTransfer`：文件边界与 JSON 候选

### 3.1 JSON 结构校验

`parseJsonDateCandidates(text)` 只处理 JSON 文本，不打开文件，也不修改本地记录。它要求：

1. JSON 根节点可作为对象读取；
2. `schemaVersion === 1`；
3. `exportedAt` 是非空且可解析的时间字符串；
4. `days` 是数组；
5. 每个条目有合法 `date` 和 `manual/import` 之一的 `source`。

结构错误直接抛出异常。单条条目错误不会使整个文件进入候选日期，而是把原始日期、缺失日期或“无法识别的日期条目”加入 `invalidTokens`。

合法日期在 JSON 解析阶段去重：第一次进入 `dates`，后续进入 `duplicateDates`。未来日期不会在这里过滤，这是 `ImportValidator` 的职责。

### 3.2 文件读取

`JsonTransfer.selectDateCandidates(context)` 负责：

1. 通过 `DocumentViewPicker` 选择一个 `.json` 文件；
2. 读取文件大小；
3. 拒绝空文件和大于 4 MiB 的文件；
4. 以 UTF-8 读取文本；
5. 调用 `parseJsonDateCandidates()`。

系统选择器取消、文件无法读取、文件为空或超过 4 MiB 时返回 `undefined`。JSON 格式或 schema 错误则由解析器抛出，再由 `Index.loadJsonIntoTextImport()` 捕获并写入 `textImportNotice`。

### 3.3 页面实际的 JSON 接入

`Index.loadJsonIntoTextImport()` 收到候选后：

- 把 `result.dates.join('\n')` 回填到文本框；
- 把 `invalidTokens` 和 `duplicateDates` 保存到 `jsonImportIssues`；
- 根据问题数量生成提示。

这意味着 JSON 的重复条目和非法条目不一定出现在文本框中，但问题会继续参与后续校验。用户继续时，Index 再次解析当前文本，并把新解析的问题与旧的 JSON 问题数组拼接后交给 `ImportValidator`。

### 3.4 未接入的直接导入路径

`JsonTransfer.import()` 会调用 `selectDateCandidates()`，把候选日期直接映射成 `source='import'` 的 `MenstrualDay[]`，再包装成 `JsonImportResult`。当前仓库没有它的调用方。

这条路径不调用 `ImportValidator`，因此它不会执行：

- 未来日期过滤；
- 与本地已有记录比较；
- 用户确认前的阻断。

它不是当前页面的实际导入路径，而是一个保留在 `JsonTransfer` 中的备用模型。

### 3.5 `source` 字段的实际处理

JSON 解析会检查输入条目的 `source` 必须是 `manual` 或 `import`，但 `JsonDateCandidateResult` 不保留每条日期的来源。当前页面确认时统一创建：

```ts
{ date: date, source: 'import' }
```

因此 JSON 输入中的来源只参与合法性检查，不参与导入后的来源恢复；导入得到的所有新记录都会标记为 `import`。

## 4. `ImportValidator`：候选分类

### 4.1 输入和输出

输入：

```ts
interface ImportValidationInput {
  dates: string[];
  invalidTokens: string[];
  duplicateDates: string[];
  existingDates: string[];
  today: string;
}
```

输出：

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

### 4.2 分类顺序

```text
输入 dates
  └─ 格式合法且去重 -> candidateDates
       ├─ date > today                  -> futureDates
       ├─ 非未来且存在于 existingDates  -> existingDates
       └─ 其余                        -> validDates

输入 invalidTokens    -> 去重后保留
输入 duplicateDates   -> 去重后保留
```

`validDates` 只排除未来日期和本地已存在日期，不排除 `duplicateDates`。这是因为 `candidateDates` 已经把同一日期去重，重复输入仍允许保留一个新日期。测试明确固定了这一行为：一个日期同时出现在 `dates` 和 `duplicateDates` 时，仍会保留在 `validDates` 一次。

`today` 和 `existingDates` 由 `Index` 提供：`today` 来自 `todayKey()`，已有日期来自当前 `markedDays`。分类函数本身不访问系统时间、不访问 Preferences。

## 5. `Index` 的确认和落库

`Index.continueTextImport()` 是解析与校验的汇聚点：

1. 对当前 `textImportInput` 调用 `parseTextDates()`；
2. 将文本问题与 `jsonImportIssues.invalidTokens/duplicateDates` 合并；
3. 将当前已有日期和当天日期传给 `validateImportDates()`；
4. 如果既没有候选日期也没有问题，写入反馈并保持文本弹层；
5. 否则保存 `importValidation` 并切换到确认弹层。

`Index.confirmImport()` 只读取 `importValidation.validDates`：

```text
validDates
  -> MenstrualDay{ source: 'import' }
  -> concat markedDays
  -> dataRevision += 1
  -> PreferencesStore.saveDays()
  -> 关闭确认和文本弹层
  -> 清理 importValidation
```

解析、校验和用户返回不会改变 `markedDays`。只有确认回调才产生事实数据写入。

## 6. 测试、规格与实现的交叉结果

### 已有测试覆盖

- `TextDateParser.test.ets` 覆盖分隔符、中文格式、两位年份、无年份、紧凑格式、重复和非法日期。
- `JsonTransfer.test.ets` 覆盖 schema v1、重复日期、非法条目和不支持版本。
- `ImportValidator.test.ets` 覆盖未来日期、已有日期和解析问题保留。

### 当前缺少的组合覆盖

现有测试分别调用三个纯函数，没有覆盖完整的：

```text
JSON 文件候选
  -> TextArea 回填
  -> 用户编辑后的文本
  -> JSON 问题合并
  -> ImportValidator
  -> Index.confirmImport
```

因此 JSON 问题与文本编辑的关系、空 JSON 数组的页面行为、文件读取失败提示和确认期间重复点击，都不是现有单元测试能证明的行为。

### 已确认的文档偏差

`TextDateParser.test.ets` 和当前正则实现明确支持 `26-08-14`、`20260814` 等输入，但 `docs/examples/text-date-import-cases.md` 把这些形式列为“不支持的表达式”。这是测试/实现与示例文档之间的直接矛盾，不是解析器的未知行为。

`docs/json_SPEC.md` 写明“空数组可导入，结果为空状态”；当前 `Index.continueTextImport()` 在候选和问题都为空时不会打开确认页，而是写入 `feedback` 并保持文本导入页。当前实现没有把空数组送入确认态。

## 7. 当前明确的代码边界问题

1. **JSON 问题与可编辑文本没有重新建立关联。** JSON 回填只写入去重后的 `dates`；非法条目和重复条目不写入文本框，但 `jsonImportIssues` 会在用户修改文本后继续被拼接进校验结果。用户清空或修改文本不能移除原 JSON 问题，确认结果仍会携带这些问题。

2. **文件选择取消、文件读取失败和文件大小不合法共用 `undefined`。** `Index.loadJsonIntoTextImport()` 对这些情况都直接返回，没有可区分的提示；只有 JSON 语法/schema 异常会进入 `textImportNotice`。因此页面无法从当前返回值判断用户取消还是文件不可用。

3. **`JsonTransfer.import()` 绕过统一确认链路。** 该方法当前无调用方，但如果被接入，会直接把候选日期转换成记录，不执行未来/已有日期分类，也不等待确认。它与页面实际使用的 `selectDateCandidates()` 代表两套不同导入协议。

4. **文本和 JSON 候选结果使用两个结构相同但未共享的接口。** `TextDateParseResult` 与 `JsonDateCandidateResult` 都是 `dates/invalidTokens/duplicateDates`，而 `Index.jsonImportIssues` 直接使用文本解析结果类型保存 JSON 问题。这依赖 ArkTS 的结构兼容，没有表达“两个来源共用同一候选协议”的显式边界。

5. **JSON 输入的 `source` 被验证后丢弃。** 解析器检查每条来源是否合法，但候选结果不携带来源，确认落库时所有日期统一标记为 `source='import'`。这不是数据丢失到日期事实层的问题，但会改变 JSON 中 `manual` 条目的来源值。

6. **空 JSON 数组无法进入确认流程。** `parseJsonDateCandidates()` 可以返回空候选且无问题的结果，`Index.continueTextImport()` 却把它当作“没有输入”处理；这与 JSON 规格中定义的空数组导入行为不一致。

7. **确认分类与预览行依赖两种数据形状。** `ImportValidator` 把重复日期作为报告数组保留，同时允许去重后的日期进入 `validDates`；确认页又只遍历 `candidateDates` 和 `invalidTokens`。因此“重复”既可能是某个候选行的状态，也可能只存在于摘要数据中，不能把 `duplicateDates` 简单改成 `validDates` 的排除集合。

8. **跨模块导入流程没有组合测试。** 当前测试能证明三个纯函数的局部结果，不能证明 JSON 回填、旧问题合并、确认切换和最终落库之间的联合行为。后续清理任何候选模型或问题数组前，需要先以当前页面实际路径补足这条证据。

## 8. 不应误判为死代码的对象

- `ImportValidator` 不在 `parseJsonDateCandidates()` 中过滤未来日期，这是分层边界，不是漏写；页面统一在校验阶段处理。
- `duplicateDates` 不从 `validDates` 排除，是当前“输入去重后保留一个日期”的实现语义，测试已有证据。
- `JsonTransfer.import()` 和 `JsonImportResult` 在当前仓库确实没有调用方，但它们不是与 `selectDateCandidates()` 等价的简单重复；删除前必须先处理它代表的备用导入协议。
- `TextDateParser` 的正则提取而不是整 token 匹配，是为了支持带说明文字的日期输入，不能仅凭正则未锚定删除。

## 9. 本步骤结论

导入链路当前有一个实际使用的统一确认流和一个未接入的直接 JSON 流：

```text
实际页面：候选 -> 文本回填 -> 重新解析 -> 统一校验 -> 用户确认 -> 落库
备用方法：候选 -> MenstrualDay[] -> 返回调用方
```

后续重构的首要边界不是重新设计解析语法，而是先统一候选结果协议、明确 JSON 问题与用户编辑的关系、移除或隔离绕过确认的备用路径，并为完整导入链路建立组合行为基线。任何删除都必须保留“只有 `validDates` 经确认后才能写入 `markedDays`”这一不变量。
