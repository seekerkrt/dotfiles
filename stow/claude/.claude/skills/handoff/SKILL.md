---
name: handoff
description: 非自明な開発、repository調査、検証、Issue / PR、debug、設計reviewの結果について、通常のhandoffまたは引き継ぎメモを明示的に求められた場合に使用し、後続会話が再開できる事実ベースの日本語Markdownを既定ではrepository外の~/handoffへ永続保存する。inline / 本文だけ / 保存不要はhandoff-inline、repository収蔵はhandoff-archiveへroutingする。
---

# Handoff基本契約

handoff作成時は[共通contract](references/common.md)を確認し、authority・事実性・再開情報に適用する。
以下は通常保存のworkflowとする。

## 目的

後続のChatGPT会話や別agentが、長いterminal logを再読せずに作業を安全に再開できるhandoffを作る。handoffは作成時点のsnapshotであり、現在仕様のsource of truthではない。

## Output mode

- 通常handoffまたは引き継ぎメモの新規保存: repository外へ新しいhistorical snapshotを作る。
- inline、本文だけ、保存不要、file不要: file / directoryを書かず、`../handoff-inline/SKILL.md`に従う。
- 選別済みの外部handoff snapshotを内容不変でrepositoryへ収蔵: `../handoff-archive/SKILL.md`に従う。

対象成果物ごとに最新の明確なユーザー指定を適用する。「保存不要」へ訂正された成果物には書き込まない。
inline本文と別途保存用snapshot等、異なる成果物への両立可能な指定はそれぞれ扱い、片方を捨てない。
出力モードの選択では、同じ成果物に対する最新のwrite / no-write指定が同時に有効で実質的に矛盾する場合だけ、
write前にユーザー判断を求める。通常handoffからrepository archiveへ自動的に進まない。

## Evidence collection

1. repository root、repository名、branch、HEAD、日時、agentを確認し、filename用のbranch-slugを決める。
2. 関連する場合はIssue / PRとの対応を確認し、scopeとphaseを決める。
3. 作成前の`git status --short --branch`を記録する。
4. 読んだfile、変更したfile、実施内容、non-goalを整理する。
5. 実行したvalidation commandと結果、未実施と理由を整理する。
6. 決定、既知risk、未確認、次の一手を整理する。
7. handoffを作成し、内容とpathを検証する。
8. 作成後のrepository statusを確認し、handoff生成によるrepository差分がないことを確かめる。

## 永続fileの配置

通常handoffは次へ作る。

```text
~/handoff/<repo>/<scope>/<YYYYMMDD-HHMMSS>-<agent>-<branch-slug>-<phase>.md
```

`<scope>`は次の順で決める。

- GitHub Issueがある: `issue-<number>`
- IssueがなくPRだけ: `pr-<number>`
- 特定テーマ: `topic-<short-kebab-slug>`
- repository全体または分類不能: `general`

`<branch-slug>`は、handoff作成時点で実際にcheckoutされているbranchから決める。

```bash
git branch --show-current
```

- 通常branch: branch名の`/`だけを`-`へ置換する。
- detached HEAD: `detached-<short-sha>`とし、short-shaは12文字程度を使う。

branch名をIssue名やtask内容から推測しない。大文字小文字、`.`、`_`等を理由なく変更せず、branchを識別できる情報をできるだけ保持する。

```text
feat/issue-281-upgrade-all-cli     → feat-issue-281-upgrade-all-cli
fix/issue-243-ramfs-filename-bound → fix-issue-243-ramfs-filename-bound
develop                            → develop
main                               → main
detached HEAD a1b2c3d4e5f6...      → detached-a1b2c3d4e5f6
```

phaseは`audit`、`design`、`investigation`、`implementation`、`validation`、`commit-push`、`pr-create`、`pr-review`、`merge-cleanup`、`release`等、実際の段階を示す短い名前にする。

例:

```text
~/handoff/jpacker/issue-281/20260728-100747-codex-feat-issue-281-upgrade-all-cli-implementation.md
~/handoff/jadeos/issue-243/20260724-094904-codex-fix-issue-243-ramfs-filename-bound-validation.md
~/handoff/dotfiles/topic-handoff-filename/20260728-130000-claude-sonnet-main-validation.md
```

filenameのbranch-slugは本文の代替ではない。`Current state`の`Branch:`へ、置換前の完全なbranch名を引き続き記録する。

`latest.md`、`current.md`等の固定名を作らない。既存handoffを移動、rename、削除しない。この命名は新規handoffだけへ適用し、旧`<YYYYMMDD-HHMMSS>-<agent>-<phase>.md`形式の既存handoffはそのまま残す。必要なdirectoryだけ作る。

新規永続handoffでは、共通の必須情報に加えて次を記録する。

```text
External handoff: ~/handoff/<repo>/<scope>/<filename>
Suggested repository path: docs/handoffs/<scope>/<filename>
Archive status: not archived
Authority: historical snapshot; not the current specification
```

Suggested pathは提案だけであり、通常handoffではrepository内に作らない。

## 既定template

~~~markdown
# ChatGPT handoff: <repo> / <task>

## Current state

- Repo:
- Branch:
- HEAD:
- Date:
- Agent:
- Phase:

## Archive

- External handoff:
- Suggested repository path:
- Archive status: not archived
- Authority: historical snapshot; not the current specification

## Task

- Purpose:
- Scope:
- Non-goals:

## Files

- Read:
- Changed:

## Completed

- ...

## Decisions and evidence

- Confirmed facts:
- Adopted decisions:
- Inference / proposal:

## Validation

- `<command>`: pass / fail / warning / partial
- Not run:
- Environment:

## Remaining risks

- Known issue:
- Unconfirmed:

## Next

1. ...

## Git status

```text
<git status --short --branch>
```

## Git operations

- git add:
- commit:
- push:
~~~

構造変更が再開に重要な場合だけStructure before / afterを追加する。Issue単位指定等がある場合は、overlayに合わせてsectionを置換・拡張する。

## PR bodyとの関係

- 最新の出力指定が通常保存である成果物は、PR bodyの有無にかかわらず既定の永続fileを作る。
- PR bodyはhandoffのEvidenceや再利用元として参照できるが、自動的な代替にはしない。
- ユーザーが「PR bodyだけ」「外部handoff fileは不要」と明示した場合だけ、PR bodyを代替出力として扱える。
- PR bodyの作成・更新はGitHub mutationであるため、対象と操作内容の明示依頼を確認し、`github` Skillに従う。

PR bodyへ記録する場合も、scope / non-scope、validation、risk、nextを事実に合わせて残す。

## 永続handoffの検証

```bash
git status --short --branch
test -f ~/handoff/<repo>/<scope>/<filename>
```

次を確認する。

- filenameがtimestamp、agent、branch-slug、phaseを持つ。
- branch-slugが作成時点のbranch、またはdetached HEADの`detached-<short-sha>`と対応する。
- repo / scope directoryが正しい。
- 既存handoffをrename、移動、削除していない。
- 必須情報とarchive metadataがある。
- 本文の`Branch:`に完全なbranch名がある。
- `Archive status`が`not archived`である。
- repositoryがhandoff生成によってdirtyになっていない。
- handoffをstage、commit、pushしていない。

出力先へ書けない場合は固定名やrepository内fileで代用せず、未作成と理由を報告する。

## 最終報告

handoff path、suggested archive path、必須情報確認、repository statusを簡潔に報告する。作業全体でのGit operationsと、handoff生成自体によるarchive / stage / commit / pushの有無を分ける。通常handoffではhandoff fileを自動archive、stage、commit、pushしない。作業結果の最終報告にもhandoff pathを含める。
