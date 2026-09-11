# 档案、采集状态与创作版本

首次建档、保存采集批次、创建草稿或关联发布版本时读取本文件。

## 稳定目录与已有数据

数据根目录按入口规则解析，使用 `index.json` 登记档案ID、名称、绝对路径和可选项目绑定。所有文本和JSON显式使用UTF-8读写。档案ID不得含路径分隔符；用于文件路径的账号/帖子key使用确定的安全名称或ID摘要，原始ID仍保存在记录中。多档案不能依赖一个会随其他任务变化的全局“当前账号”。

每个档案采用以下结构，只有用到时才创建对应文件：

```text
<profile-id>/
  profile.json
  posts/<platform>/<account-key>/<post-key>/<revision-id>.json
  acquisitions/<run-id>.json
  style/rules.json
  style/versions/<style-version>.json
  style-profile.md
  history-summary.md
  campaigns/<campaign-id>.json
  feedback/<feedback-id>.json
  validation/<run-id>.json
```

旧档案如果存在 `profile.yaml`、`history.jsonl` 或 `feedback.jsonl`，先读取并映射，不删除或覆盖原文件。保留旧记录来源，不知道的完整度和身份标为 `unknown`；迁移后比对记录数、账号和重复项。映射无法确认时保留旧模式并报告缺口。

使用 [profile.template.json](../assets/profile.template.json) 初始化档案。模板中的 `null` 表示尚未取得的信息，不能当成验证成功；档案ID、名称、绝对路径和启用的来源必须在实际建档时填写。

## 来源记录

每个来源按 `platform + account_id` 唯一标识，记录：

固定平台键为 `xiaohongshu`、`wechat_official`、`bilibili`，其他平台使用稳定小写键。迁移时记录别名映射，不能为同一个账号创建不同拼写的重复来源。

- `source_id`、`platform`、`account_id`、`profile_url`、`identity_status`（`verified/ambiguous/unknown`）、`ownership`（`own/reference`）。
- `method`、`access_status`（`unverified/available/partial/login_required/blocked/unavailable`）、`verified_at`、`verified_capabilities`。
- `last_attempt_at`、`last_successful_check_at`、`last_complete_collection_at`，分别表示尝试、成功检查已知目标范围、完整获取目标范围的时间。
- `coverage`：时间范围、目标范围、列表是否结束、已发现/已获取/部分/失败数量及缺口。
- `cursor`：上次已提交的分页位置、时间水位与该时刻全部已见ID；平台ID默认是不可排序的字符串。另存未完成分页位置及有限的已见ID集合。
- `pending_items`：已发现但待获取的ID和链接；`retry_queue`：原因、重试次数、状态、下次时间及上次错误。

`last_successful_check_at` 可以在列表检查成功且全部已发现项目已有结果或已持久化待办后更新，但 `access_status=partial` 及失败数量必须保留。未完成分页必须保留后续进度。只有整个声明范围已完成、没有未取正文时才能更新 `last_complete_collection_at`。

时间使用含时区的ISO 8601；原始时区不清楚时单独记录不确定性。可用链接中的身份信息以实际网页或接口观察为依据。

## 帖子和修订记录

主键为 `(platform, account_id, post_id)`；规范化URL只是缺少稳定ID时的替代。链接参数仅剔除已确认的跟踪参数，必要的访问参数保留在来源记录中。

每条帖子保存以下字段：

```text
schema_version, platform, account_id, post_id, url
published_at, source_updated_at, collected_at, revision_id, content_hash
title, body, description, tags, media_summary
transcript: {text, source, language, coverage, timestamp_ranges}
completeness: {title, body, image_text, visuals, transcript}
identity_status, authorship, campaign_group, column, content_type
metrics: {observed_at, available_values}
evidence: [{field, locator, extraction_method}]
eligible_dimensions, excluded_reasons, previous_revision_id
```

完整度值为 `complete/partial/missing/unknown/not_applicable`，不能用单一“抓取成功”代替。视频简介存为 `description`，不要挪入 `body` 或 `transcript`，完整度中可相应增加 `description` 字段。`authorship` 区分本人发布/明确批准、合作、引用他人、AI未批准草稿及未知。指标不可见则缺省或为null，绝不补零。

`content_hash` 对规范化后的标题、正文、简介、标签及可取得的字幕/媒体描述计算SHA-256，不包含浏览量或采集时间；不以删除全部空格的方式归一化，因为换行和标点本身是风格。互动变化单独保存观察记录，不制造正文新版本。同一帖多个修订只算一个独立样本。

## 持久化与断点顺序

每批使用唯一 `run-id`，执行顺序为：

1. 将观察到的列表ID及待取链接写入未完成批次记录。
2. 获取并保存不可变帖子修订；已有相同主键和内容摘要值时复用。失败项写入可重试队列。
3. 验证每个已发现条目都有修订、部分记录或持久化待办；再提交批次结果和下一分页位置。
4. 最后更新来源的水位与新鲜度。失败不能擦除上次成功值。

写完整JSON到同目录临时文件、解析确认后用原子替换更新索引。对同一档案串行提交；遇到其他写入者时等待其释放，不覆盖未知新版本。重放同一批次按主键、修订摘要和批次ID去重。写入途中中断时从未完成批次恢复，不跳过失败条目。

## 创作清单与发布关联

使用 [campaign.template.json](../assets/campaign.template.json) 为每次创作生成时间+随机后缀的唯一 `campaign_id`。同一创作的三个平台共享该编号，各自有明确的目标账号、格式及版本列表。输出路径使用编号，不只用日期和标题。

清单记录素材位置及摘要值、事实清单、使用的风格版本、规则ID、参考历史帖子和其修订ID、平台草稿文件及摘要值、审核结果和发布对应关系。返工追加 `v002` 等版本，不覆盖用于后续比较的初稿。

清单中 `source_assets` 的元素包含 `locator/content_hash/media_type`；`facts` 包含 `fact_id/text/source_locator`；`history_examples` 包含帖子主键、`revision_id` 和选用理由。`targets` 每项包含 `platform/account_id/content_type`、`versions` 和 `publications`：

- `versions` 每项含 `version_id/status/created_at/artifacts`；每个artifact含绝对路径、内容摘要值及用途，status为 `draft/approved`，批准有实际证据才记录。
- `publications` 每项含 `url/post_id/published_at/draft_version_id/observed_revision_id` 和身份/发布验证状态。平台草稿箱位置另存 `remote_draft_id/remote_draft_url`，不能等同公开URL。

自动刷新发现发布变更时根据这些关联读取先前草稿。未创建过创作清单的历史帖子可用于历史风格学习，但不能虚构一份“原草稿”来算修改。

新生成版本一律为 `draft`。只有用户明确表示“这稿可用”或批准指定版本，才记作 `approved` 并保存该反馈；助手自评通过不构成用户批准。批准也不能证明已经发布。发布状态需要用户确认或可访问页面的证据，记录实际URL、帖子ID、目标账号、时间和对应草稿版本。匹配优先级：明确创作编号/已保存关系 → 用户明确指定的稿件 → 唯一候选且经确认的正文匹配；仅标题相似或发布时间接近时保持未关联。

发布后修改继续保存新修订；反馈记录包含前后版本及证据。相同发布修订不得反复产生相同反馈。已知来源链接无法访问时保留关系并标记此次读取失败，不擅自改为未发布。

## 风格版本

`rules.json` 保存当前机器可读规则，`style-profile.md` 是便于用户检查的摘要。更新时先保存不可变的 `style/versions/<version>.json`，记录前版、变更原因和证据，再切换当前版本。创作清单始终固定引用当时版本；回退切换指针，不抹去历史。
