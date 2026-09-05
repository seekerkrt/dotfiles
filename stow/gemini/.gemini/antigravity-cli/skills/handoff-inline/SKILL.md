---
name: handoff-inline
description: 非自明な作業のhandoffについて、ユーザーがhandoff-inline、inline、本文だけ、保存不要、file不要、fileを作らない、次スレへ貼る文章だけ等を明示した場合に使用する。handoffの共通事実性・必須情報を保ち、repositoryや~/handoffへ書かず最終応答本文だけへ短く出力する。
---

# Inline handoff routing

## 基本契約

最初に`~/.gemini/antigravity-cli/skills/handoff/SKILL.md`を読み、そのauthority、事実性、必須情報、ユーザー追加指定overlayを適用する。本Skillは共通契約を再定義せず、output modeだけを次のように上書きする。

```text
保存先: 最終応答本文だけ
file / directory作成: なし
repository変更: なし
archive metadata: 原則不要
長さ: 再開に必要な情報を保てる範囲で短く
```

本Skillはinline成果物を担当し、file / directoryを書かない。
別成果物として永続snapshot保存や選別済みsnapshotの収蔵も要求された場合は、
それぞれhandoff / handoff-archiveの契約で併せて扱う。
成果物ごとの最新指定・訂正・実質的な矛盾は、親SkillのOutput modeに従って解決する。

## Inline delta

- 完成したhandoff本文を最終応答へ直接出す。
- repository、branch、HEAD、working tree、完了事項、採用判断、scope / non-goal、validation、未実施、未確認、risk、next、Git操作状態を残す。
- file一覧、command全文、Structure before / afterは再開に必要な場合だけ含める。
- external handoff path、suggested archive path、archive statusは、ユーザーが必要としない限り省く。
- handoffを作るためだけに新しい実装、広範な調査、高costな検証を始めない。
- inline成果物の生成ではfile、directory、clipboard、background task、
  Git / GitHub mutationを行わない。

## 既定template

```markdown
# Inline handoff: <repo> / <task>

## Current state

- Repo / branch / HEAD:
- Working tree:

## Completed and decisions

- ...

## Validation

- 実施:
- 未実施:

## Remaining

- 未確認 / risk:

## Next

1. ...

## Git operations

- git add:
- commit:
- push:
```

長い前置きや外側の説明を付けず、handoff本文から始める。全体をcode fenceで囲まない。
