---
name: handoff-inline
description: 非自明な開発作業や調査について、ユーザーがinline、本文だけ、保存不要、ファイル不要等を明示した場合に、fileを作らず現在の応答本文へ短い日本語引き継ぎを出力する。通常handoff生成やrepository archiveには使用しない。
---

# 目的

非自明な開発作業や調査結果を、fileを作らず現在の最終応答本文へ短い日本語handoffとして出力する。

ユーザーがそのまま次スレッドへ貼れる一時的な引き継ぎとし、永続保存を必要としない場合だけ使用する。通常handoffの簡易版ではなく、ユーザーが非保存を明示した場合の別出力形式として扱う。

3スキルの責務を次のように分離する。

```text
handoff:
  repository外のfileへ永続保存

handoff-inline:
  現在の応答本文だけ、fileなし

handoff-archive:
  選別済みの外部fileをrepositoryへ収蔵
```

他skillを自動実行しない。それぞれ独立したユーザー指示で動作する。

# 使用条件

次のいずれかが明示された場合に使用する。

- `handoff-inline`
- inlineで引き継ぎ
- 本文だけ
- 保存不要
- ファイル不要
- fileを作らない
- このチャットに引き継ぎを書く
- 次スレへ貼る文章だけ
- 小規模または中規模作業で、永続fileが不要と明示された

次の場合は使用しない。

- 通常の「handoff」「引き継ぎメモ」だけ
- 永続保存を求められた
- fileを作ってほしい
- あとでアップロードしたい
- repositoryへarchiveしたい
- `docs/handoffs`へ保存したい
- PR bodyをhandoffとして扱う作業
- archive候補の相談だけ
- 単発の質問応答
- 単純なtypo修正
- 通常の最終報告だけで十分な作業

出力方式が競合した場合の優先順位は、明示的なarchive指示、明示的なinlineまたはfile不要指示、通常handoffの順とする。

- 「handoffをinlineで」: `handoff-inline`
- 「保存不要の引き継ぎメモ」: `handoff-inline`
- 「このhandoffをdocs/handoffsへarchive」: `handoff-archive`
- 単なる「引き継ぎメモよろしく」: `handoff`
- 「archive候補を相談したい」または単発の質問: いずれも使用しない

# 最重要ルール

- 完成したhandoffを現在の最終応答本文だけへ出力する。
- fileやdirectoryを一切作成、更新しない。
- repositoryを一切変更しない。
- `~/handoff/`へ書き込まない。
- `docs/handoffs/`へ書き込まない。
- archive候補fileを生成しない。
- 永続handoffより短くするが、現在地、重要な判断、未確認、次の一手を落とさない。
- 現在のセッションに実在する作業と証拠だけを報告する。

# 長さと必須内容

通常handoffより短くし、該当しないsectionは省略してよい。

ただし最低限、次を残す。

- repository、branch、HEADによる現在地
- 完了事項
- ユーザーが採用した判断
- 維持するscope / non-scope
- validationの実施内容、結果、未実施と理由
- 未完了、未確認、known risk
- 次の一手
- commit、push状態

# 標準テンプレート

```markdown
# Inline handoff: <repo> / <task>

## Current state

- Repo:
- Branch:
- HEAD:
- Working tree:
- Related Issue / PR:

## Completed

- 完了した作業
- 確認済みの事実

## Decisions

- ユーザーが採用した決定
- 維持するscope / non-scope

## Validation

- 実施した検証と結果
- 未実施の検証と理由

## Remaining

- 未完了
- 未確認
- known risk

## Next

1. 次に推奨する作業

## Git operations

- git add:
- commit:
- push:
```

# 必要な場合だけ含める情報

次は必要な場合だけ含める。

- Files readの完全一覧
- 実行command全文
- 長いterminal log
- Structure before / after
- Archive metadata
- Suggested repository path
- Authority順位表
- 全validation matrix
- PR body例外規則

ただし、再開に不可欠なcommand、commit SHA、runtime観測値は省略しない。

# 事実性ルール

- 事実と推測を分ける。
- 実施していないことを完了扱いしない。
- build成功をruntime成功と扱わない。
- QEMU、KVM、TCG、VirtualBox、実機を区別する。
- 観測事実と解釈を分ける。
- 未確認は未確認と書く。
- GitHub状態を確認していない場合は推測しない。
- source変更なしの場合は変更なしと明記する。
- ユーザーの採用判断とagent推奨を区別する。

正確なhandoffに必要な場合だけ、repository状態、既存file、差分、log、既に実行された検証結果をread-onlyで確認してよい。handoffを埋めるためだけに新しい実装、広範な調査、高コストな検証を始めない。

# 絶対禁止事項

`handoff-inline`実行時は、次を一切行わない。

- file作成
- directory作成
- `~/handoff/`への書き込み
- repositoryへの書き込み
- `docs/handoffs/`への書き込み
- archive
- `git add`
- commit
- push
- branch作成、切替
- pull
- fetch
- reset
- restore
- stash
- clean
- PR作成
- Issue更新
- clipboard操作
- background処理

inline handoffは、現在の応答本文を出力するだけとする。

# 最終出力

- 完成したhandoff本文から始め、長い前置きや外側の説明を加えない。
- 「handoff-inlineを作成しました」「以下がhandoffです」等の前置きは原則として付けない。
- handoff全体をcode fenceで囲まない。
- file pathやarchive pathを報告しない。
- fileを作成したと主張しない。
- ユーザーが別言語を明示しない限り日本語で出力する。
