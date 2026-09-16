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

共通contractのevidence再利用原則に従い、同一sessionの作業終了直後で必要なevidenceが揃う場合はFast pathを使う。
既読で不変のSkill / commonは再読しない。不足・不整合があるclaimだけRecovery pathで扱う。

### Fast path

1. 対象repositoryに実行directoryを固定する。確認済みのroot、repository名、Issue / PRとの対応、scope、
   作業内容、判断、validation結果を再利用する。日時、agent、phaseを記録する。
2. 保存前に次を原則各1回freshに取得する。1観測setをfilename、本文、保存後validationで共有する。

   ```bash
   git branch --show-current
   git rev-parse HEAD
   git status --short --branch
   ```

3. 既存evidenceから共通の必須情報を整理し、外部へ新規保存する。
4. 下記「永続handoffの検証」を1つの工程として行う。保存後statusは1回取得し、結果を最終報告へ再利用する。

既知のdirty stateだけを理由にRecoveryへ降りない。ただしbranch / HEAD / statusの一致を内容不変の証明にしない。
dirty fileは同じ`M`表示のまま再編集され、untracked pathの内容も変わり得る。
並行writer / watcher、Git操作、cwd / worktree変更、長い中断等、evidenceを無効化する変更の可能性があれば、
影響するclaimだけRecoveryで確認する。通常経路で全file hashや全diff取得を必須にしない。

### Recovery path

次の場合は不足・不整合の範囲を特定し、必要な現在stateと根拠だけを取得する。

- standalone invocation、context不足、evidence provenance不足、historical claimしかない。
- branch / HEAD不整合、ユーザー指定と現状の矛盾、repository stateが作業中に変化した可能性がある。

対象repo / worktreeが曖昧ならrootを確認する。対象file / diff、Issue / PR、指定artifact等のうち、
当該claimの確認に必要なものだけを読む。過去handoffはexact pathまたは限定scopeで扱い、全体探索しない。
取得済みの有効なstateは使い続け、Fast pathの全commandを再実行しない。
保存に使うbranch / HEAD / statusが古くなった場合だけ更新し、理由を残す。

repo、scope、出力mode、書込み権限等の保存成立条件を確定できない場合は、依存する書込みを止めて不足情報を報告する。

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

`<branch-slug>`は、Evidence collectionで取得した保存前のbranch / HEADから決める。命名のために再取得しない。

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
保存先の解決先がrepository外の上記directoryに収まることを確認し、既存fileを上書きしない。

新規永続handoffでは、共通の必須情報に加えて次を記録する。

```text
External handoff: ~/handoff/<repo>/<scope>/<filename>
Suggested repository path: docs/handoffs/<scope>/<filename>
Archive status: not archived
Authority: historical snapshot; not the current specification
```

Suggested pathは提案だけであり、通常handoffではrepository内に作らない。

## 既定template

````markdown
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
````

構造変更が再開に重要な場合だけStructure before / afterを追加する。Issue単位指定等がある場合は、overlayに合わせてsectionを置換・拡張する。

## PR bodyとの関係

- 最新の出力指定が通常保存である成果物は、PR bodyの有無にかかわらず既定の永続fileを作る。
- PR bodyはhandoffのEvidenceや再利用元として参照できるが、自動的な代替にはしない。
- ユーザーが「PR bodyだけ」「外部handoff fileは不要」と明示した場合だけ、PR bodyを代替出力として扱える。
- PR bodyの作成・更新はGitHub mutationであるため、対象と操作内容の明示依頼を確認し、`github` Skillに従う。

PR bodyへ記録する場合も、scope / non-scope、validation、risk、nextを事実に合わせて残す。

## 永続handoffの検証

保存済みartifactのread-backと次の内容・path確認、保存後の`git status --short --branch`を1つのvalidation工程で行う。
statusは保存前と比較するために1回取得する。filenameや本文の照合には保存前の観測setを使い、branch / HEADを再取得しない。

- filenameがtimestamp、agent、branch-slug、phaseを持つ。
- branch-slugが作成時点のbranch、またはdetached HEADの`detached-<short-sha>`と対応する。
- repo / scope directoryが正しい。
- 既存handoffをrename、移動、削除していない。
- 必須情報とarchive metadataがある。
- 本文の`Branch:`に完全なbranch名がある。
- `Archive status`が`not archived`である。
- repository statusにhandoff生成による追加変更がなく、既存ユーザー変更が保持されている。
- handoffをstage、commit、pushしていない。

status一致だけでfile内容の完全不変を証明したとは扱わない。変化や競合の兆候があれば、該当するclaimだけRecoveryで扱う。
保存失敗・結果不明の場合は今回のartifactの存在と内容を先に確認し、同じ保存を無条件に繰り返さない。
出力先へ書けない場合は固定名やrepository内fileで代用せず、未作成と理由を報告する。

## 最終報告

上記validation結果を再利用し、handoff path、suggested archive path、必須情報確認、repository statusを簡潔に報告する。同じstateを別の最終確認として再取得しない。作業全体でのGit operationsと、handoff生成自体によるarchive / stage / commit / pushの有無を分ける。通常handoffではhandoff fileを自動archive、stage、commit、pushしない。作業結果の最終報告にもhandoff pathを含める。
