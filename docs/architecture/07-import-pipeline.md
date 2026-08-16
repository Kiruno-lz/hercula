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
            └─ ImportPipeline.validateTextImport()
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

JSON 文件不是直接转成 `MenstrualDay[]` 写入，而是先转为日期文本和问题列表，再与文本输入共用确认流程。

## 2. `TextDateParser`：文本语法识别

### 2.1 存在目的

文本解析和 JSON 解析都把输入转换为同一个 `DateCandidateResult`：

```ts
interface DateCandidateResult {
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

系统选择器取消、文件无法读取、文件为空或超过 4 MiB 时返回带明确 `status` 的 `JsonCandidateLoadResult`，分别对应 `cancelled`、`read-failed`、`empty` 和 `too-large`；成功时返回 `success` 和候选结果。`Index.loadJsonIntoTextImport()` 对非成功结果仍直接返回，因此没有改变当前页面文案或交互。JSON 格式或 schema 错误仍由解析器抛出，再由 Index 捕获并写入 `textImportNotice`。

### 3.3 页面实际的 JSON 接入

`Index.loadJsonIntoTextImport()` 收到候选后：

- 把 `result.candidates.dates.join('\n')` 回填到文本框；
- 把 `invalidTokens` 和 `duplicateDates` 保存到 `jsonImportIssues`；
- 根据问题数量生成提示。

这意味着 JSON 的重复条目和非法条目不一定出现在文本框中，但问题会继续参与后续校验。用户继续时，Index 再次解析当前文本，并把新解析的问题与旧的 JSON 问题数组拼接后交给 `ImportValidator`。

### 3.4 文件结果边界

`JsonTransfer.selectDateCandidates()` 只返回候选日期和文件读取状态，不创建 `MenstrualDay`。未来日期过滤、已有记录比较和用户确认前的阻断统一由 `ImportPipeline.validateTextImport()` 完成；确认后才由 `createImportedDays()` 创建 `source='import'` 的事实记录。

### 3.5 `source` 字段的实际处理

JSON 解析会检查输入条目的 `source` 必须是 `manual` 或 `import`，但 `DateCandidateResult` 不保留每条日期的来源。当前页面确认时统一创建：

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

`Index.continueTextImport()` 只负责把页面状态传给 `domain/ImportPipeline.ets` 的 `validateTextImport()`：

1. 传入当前 `textImportInput`、`jsonImportIssues`、已有日期、当天日期和当前年份；
2. 接收 `validateTextImport()` 返回的 `ImportValidationResult`；
3. 如果既没有候选日期也没有问题，写入反馈并保持文本弹层；
4. 否则保存 `importValidation` 并切换到确认弹层。

`Index.confirmImport()` 只读取 `importValidation.validDates`，通过 `createImportedDays()` 生成事实：

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

### 当前缺少的页面集成覆盖

`ImportPipeline.test.ets` 已覆盖候选回填、问题合并、文本编辑后的校验分类和确认日期到事实的转换；仍没有覆盖真实页面和系统能力的完整路径：

```text
JSON 文件候选
  -> TextArea 回填
  -> 用户编辑后的文本
  -> JSON 问题合并
  -> ImportValidator
  -> Index.confirmImport
```

模拟器已补齐以下页面级路径：有效 JSON 回填后进入确认页并导入 3 条新日期；重复 JSON 在确认页显示 3 条“已存在”；非法 schema 回到文本导入弹层并显示具体错误；文件选择器取消保持文本导入弹层且不新增提示；导出取消返回历史页，导出成功后文件出现在系统 Download 列表。

仍未由当前运行环境证明的路径是：导出写入失败。阶段 12 已尝试将 `/storage/media/100/local/files/Docs/Download/hercula-2026-08-17.json` 设为只读，但模拟器 shell 对 `file_manager` 用户持有的文件执行 `chmod 444` 返回 `Permission denied`。阶段 17 在 Pura 90 进一步尝试由 shell 在同一 `Documents/Download` 目录创建 `readonly-shell-phase17.json`，`touch` 也返回 `Permission denied`；虽然可以在 `/data/local/tmp` 创建 `0444` 的 `readonly-export-phase17.json`，但保存文件选择器只暴露 `Download` 和 `Documents`，不会提供该路径，因此现有 `JsonTransfer.export()` 无法接收到这个只读 URI。不能用 `parseJsonDateCandidates()` 的单元测试替代。空文件和超过 4 MiB 文件已由系统文件选择器实际访问，均回到文本导入弹层且没有新增页面提示；空 JSON 数组已进入现有确认页并显示 0 条结果；确认按钮连续点击已回到历史页，目标日期只出现一条。

### 已确认的文档偏差

`TextDateParser.test.ets` 和当前正则实现明确支持 `26-08-14`、`20260814` 等输入，但 `docs/examples/text-date-import-cases.md` 把这些形式列为“不支持的表达式”。这是测试/实现与示例文档之间的直接矛盾，不是解析器的未知行为。

`docs/json_SPEC.md` 写明“空数组可导入，结果为空状态”；当前 `Index` 只对成功加载且未被用户编辑的空 JSON 保留一次性来源标记，`continueTextImport()` 将其送入现有确认弹层，显示 0 条结果并禁用导入按钮。手动空文本和用户编辑后的空文本仍按“没有输入”直接返回。

## 7. 当前明确的代码边界问题

1. **JSON 问题与可编辑文本没有重新建立关联。** JSON 回填只写入去重后的 `dates`；非法条目和重复条目不写入文本框，但 `jsonImportIssues` 会在用户修改文本后继续被拼接进校验结果。用户清空或修改文本不能移除原 JSON 问题，确认结果仍会携带这些问题。

2. **文件结果已经在数据层区分，但页面暂不消费。** `selectDateCandidates()` 现在返回 `JsonCandidateLoadResult.status`，可区分取消、读取失败、空文件和超大文件；`Index.loadJsonIntoTextImport()` 仍对非成功结果直接返回，因而保持现有静默行为，不把内部状态误写成用户提示。

3. **候选协议已统一，但来源仍不进入候选事实。** `TextDateParser` 和 `JsonTransfer` 都返回 `DateCandidateResult`；`Index` 用其字段构造独立的 `ImportIssues` 保存 JSON 问题。候选协议不表达 JSON 原始 `source`，确认落库仍统一使用 `source='import'`。

4. **JSON 输入的 `source` 被验证后丢弃。** 解析器检查每条来源是否合法，但候选结果不携带来源，确认落库时所有日期统一标记为 `source='import'`。这不是数据丢失到日期事实层的问题，但会改变 JSON 中 `manual` 条目的来源值。

5. **确认分类与预览行依赖两种数据形状。** `ImportValidator` 把重复日期作为报告数组保留，同时允许去重后的日期进入 `validDates`；确认页又只遍历 `candidateDates` 和 `invalidTokens`。因此“重复”既可能是某个候选行的状态，也可能只存在于摘要数据中，不能把 `duplicateDates` 简单改成 `validDates` 的排除集合。

6. **页面集成导入流程仍没有自动化测试。** 纯逻辑 `ImportPipeline.test.ets` 已固定 JSON 候选回填后的校验、旧问题合并和确认事实转换；但 JSON 文件选择、TextArea 回填、确认弹层切换和真实 `Index.confirmImport()` 仍需页面运行时证据。后续改动状态协议前，不能把纯逻辑测试当作页面流程证据。

## 8. 不应误判为死代码的对象

- `ImportValidator` 不在 `parseJsonDateCandidates()` 中过滤未来日期，这是分层边界，不是漏写；页面统一在校验阶段处理。
- `duplicateDates` 不从 `validDates` 排除，是当前“输入去重后保留一个日期”的实现语义，测试已有证据。
- `TextDateParser` 的正则提取而不是整 token 匹配，是为了支持带说明文字的日期输入，不能仅凭正则未锚定删除。

## 9. 本步骤结论

导入链路当前只有一个实际使用的统一确认流：

```text
实际页面：候选 -> 文本回填 -> 重新解析 -> 统一校验 -> 用户确认 -> 落库
备用方法：候选 -> MenstrualDay[] -> 返回调用方
```

后续重构的首要边界不是重新设计解析语法，而是先统一候选结果协议、明确 JSON 问题与用户编辑的关系、移除或隔离绕过确认的备用路径，并为完整导入链路建立组合行为基线。任何删除都必须保留“只有 `validDates` 经确认后才能写入 `markedDays`”这一不变量。
