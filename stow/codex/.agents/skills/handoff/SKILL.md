---
name: handoff
description: 非自明な開発、repository調査、検証、Issue / PR、debug、設計reviewの結果について、通常のhandoffまたは引き継ぎメモを明示的に求められた場合に使用し、後続会話が再開できる事実ベースの日本語Markdownを既定ではrepository外の~/handoffへ永続保存する。inline / 本文だけ / 保存不要はhandoff-inline、repository収蔵はhandoff-archiveへroutingする。
---

# Handoff基本契約

## 目的

後続のChatGPT会話や別agentが、長いterminal logを再読せずに作業を安全に再開できるhandoffを作る。handoffは作成時点のsnapshotであり、現在仕様のsource of truthではない。

## ユーザー追加指定のoverlay

handoffは次の式で作る。

```text
handoff Skillの既定契約
    +
今回のユーザーの追加指定
    ↓
重複や矛盾を整理した1つのhandoff
```

優先順位は次とする。

1. 安全性、事実性、未実施を偽らない契約
2. 今回のユーザーの明示指定
3. 本Skillの既定形式

追加指定を末尾へ機械的に付け足さず、既定sectionへ統合する。

- 「短く」: 必須情報を落とさず圧縮する。
- 「設計判断を詳しく」: Decisionと理由・棄却案を拡張する。
- 「実機確認中心」: Validationを実機の機種、条件、観測、未確認中心に再構成する。
- 「次スレに貼る本文だけ」: `handoff-inline`へ切り替える。
- 「残作業をIssue単位で」: RemainingをIssue候補、scope、acceptanceへ整理する。

## Output mode

- 通常handoffまたは引き継ぎメモを明示的に求められた場合: repository外へ永続fileを作る。
- inline、本文だけ、保存不要、file不要: `../handoff-inline/SKILL.md`に従う。
- repositoryへ保存、archive、収蔵、`docs/handoffs`へcopy: `../handoff-archive/SKILL.md`に従う。

明示的なarchive、明示的なinline、通常handoffの順でoutput指定を解決する。通常handoffからrepository archiveへ自動的に進まない。

## Authority

現状の観測と意図・仕様は分けて根拠を確認する。

- 現状の観測: 現在のsource code、実際のbuild設定、runtime evidence。
  観測条件と未確認範囲を記録する。
- 意図・仕様: repositoryが指定するdecision authorityに従い、採用済みの決定（Issue / PR等）や
  正式な仕様書 / architecture / decision documentを確認する。
  未採用のproposalを採用済み仕様と扱わない。

両者が食い違う場合は、現在実装と採用済み仕様の内容・根拠・不一致を両方残す。
codeまたはdocsを一律に優先して片方を消さない。

handoff内のbranch、commit SHA、line番号、caller一覧、validation、推奨、推測は作成時点のsnapshotである。agentの推奨とユーザーが採用した判断を分ける。

## Evidence collection

1. repository root、repository名、branch、HEAD、日時、agentを確認し、filename用のbranch-slugを決める。
2. 関連する場合はIssue / PRとの対応を確認し、scopeとphaseを決める。
3. 作成前の`git status --short --branch`を記録する。
4. 読んだfile、変更したfile、実施内容、non-goalを整理する。
5. 実行したvalidation commandと結果、未実施と理由を整理する。
6. 決定、既知risk、未確認、次の一手を整理する。
7. handoffを作成し、内容とpathを検証する。
8. 作成後のrepository statusを確認し、handoff生成によるrepository差分がないことを確かめる。

## 必須情報

該当する内容を次から落とさない。空のsectionを増やす必要はない。

- repository、branch、HEAD、日時、agent、phase
- taskの目的、scope、non-goal
- 読んだfileと変更したfile
- 完了事項と実施していない事項
- 確認済み事実、採用判断、推測、未確認
- validation command、結果、未実施理由、環境
- known issue / risk
- 次に推奨する作業
- working tree状態
- `git add`、commit、pushの実施有無
- 永続fileではexternal path、suggested repository path、archive status、authority

## Validationの書き方

- commandを実際に実行した形で記録する。
- pass、fail、warning、partial、not run、environment blockedを区別する。
- build、test、runtime、QEMU KVM / TCG、VirtualBox、実機を区別する。
- 外部log、画面、動画、counterは観測事実と解釈を分ける。
- 長いlogを貼らず、再開に必要な値とerrorだけ残す。

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

新規永続handoffでは次を記録する。

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

- 通常handoffまたは引き継ぎメモを明示的に求められた場合は、PR bodyの有無にかかわらず既定の永続fileを作る。
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
