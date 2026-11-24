---
name: handoff
description: 非自明な開発、repository調査、検証、Issue / PR、debug、設計reviewの結果について、通常のhandoffまたは引き継ぎメモを明示的に求められた場合に使用し、後続会話が再開できる事実ベースの日本語Markdownを既定では~/handoffsへ永続保存する。handoff自体にinline / 本文だけ / 保存不要 / file不要 / fileを作らない / 次スレへ貼る文章だけが明示された場合はInline modeでfile / directoryを作らず最終応答本文だけへ出力し、選別済みsnapshotのrepository収蔵はhandoff-archiveへroutingする。
---

# Handoff基本契約

handoff作成時は[共通contract](references/common.md)を確認し、authority・事実性・再開情報に適用する。

## 目的

後続のChatGPT会話や別agentが、長いterminal logを再読せずに作業を安全に再開できるhandoffを作る。handoffは作成時点のsnapshotであり、現在仕様のsource of truthではない。

## Output mode

依頼された成果物を特定し、それぞれに適用される最新の明確なユーザー指定から出力modeを決める。
同じhandoffへの「保存不要」の訂正は、それ以前の保存指定に優先する。
監査報告にinline指定があり、別途永続handoffが明示依頼されている場合は、監査報告を本文で返し、handoffをPersistent modeで保存する。
監査報告だけを依頼された場合は監査報告だけを返す。handoffの作成にはhandoff自体の明示依頼が必要となる。
出力モードの選択では、同じ成果物に対する最新のwrite / no-write指定が同時に有効で実質的に矛盾する場合だけ、
write前にユーザー判断を求める。

### Persistent mode

既定。通常handoffまたは引き継ぎメモを、`~/handoffs/...`へ新しいhistorical snapshotとして保存する。
下記「Persistent workflow」に従う。

### Inline mode

inline、本文だけ、保存不要、file不要、fileを作らない、次スレへ貼る文章だけ等が明示されたhandoffに適用する。
次の制約は、このinline handoffの生成に適用する。

- 保存先: 最終応答本文だけ
- file / directory作成: なし
- repository変更: なし
- archive metadata: 原則不要
- 長さ: 再開に必要な情報を保てる範囲で短く

共通contractの該当する必須情報を保ち、次のinline固有差分を適用する。

- repository、branch、HEAD、working tree、完了事項、採用判断、scope / non-goal、validation、未実施、未確認、risk、next、Git操作状態を残す。
- file一覧、command全文、Structure before / afterは再開に必要な場合だけ含める。
- External handoff path、Suggested repository path、Archive statusは、ユーザーが必要としない限り省く。
- inline成果物の生成ではclipboard、background task、Git / GitHub mutationを行わない。

完成したhandoff本文を最終応答へ直接出す。長い前置きや外側の説明を付けず、handoff本文から始める。全体をcode fenceで囲まない。

#### Inline template

```markdown
# Inline handoff: <repo> / <task>

## Current state

- Repo / branch / HEAD:
- Date / Agent / Phase:
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

### Archive mode

選別済みの外部handoff snapshotを内容不変でrepositoryへ収蔵する場合は、`../handoff-archive/SKILL.md`に従う。
通常handoffからrepository archiveへ自動的に進まない。

## Evidence collection

Persistent / Inlineの双方で共通contractのevidence再利用原則に従う。既読で不変のSkill / commonは再読しない。
Inline modeでもbranch / HEAD / working tree等のclaimに必要な鮮度を確認する。
有効なsession evidenceを再利用し、不足・不整合や変更の兆候があるclaimだけ必要な現在stateと根拠を取得する。
取得できない情報は未確認と理由を残す。

## Persistent workflow

以下の保存手順、永続fileの配置・filename生成、archive metadata付与、既定template、
保存artifactのread-back validation、handoff path / suggested archive pathを含む最終報告はPersistent mode専用とする。
同一sessionの作業終了直後で必要なevidenceが揃う場合はFast pathを使い、不足・不整合があるclaimだけRecovery pathで扱う。

### Fast path

1. 対象repositoryに実行directoryを固定する。確認済みのroot、repository名、Issue / PRとの対応、scope、
   作業内容、判断、validation結果を再利用する。日時、agent、phaseを記録する。
2. 保存前に次を原則1回取得する。branch、HEAD、tracked / staged / untrackedの観測をfilename、本文、保存後validationで共有する。

   ```bash
   git --no-optional-locks status --porcelain=v2 --branch --untracked-files=all -z
   ```

3. 既存evidenceから共通の必須情報を整理し、下記「永続fileの配置」に従って新規保存する。
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

### 永続fileの配置

通常handoffは次へ作る。

```text
~/handoffs/<repo>/<scope>/<YYYYMMDD-HHMMSS>-<agent>-<branch-slug>-<phase>.md
```

対象worktreeのGit rootと`~/handoffs`をsymlinkも含めて解決し、実体を比較する。
一致する場合に限り、`<repo>`を`handoffs`とし、対象repository内の`~/handoffs/handoffs/<scope>/<filename>`への保存を許容する。
それ以外は解決済みの保存先が対象repository外にあることを必須とする。

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
~/handoffs/example-project/issue-281/20260728-100747-codex-feat-issue-281-example-implementation.md
~/handoffs/example-project/issue-243/20260724-094904-codex-fix-issue-243-example-validation.md
~/handoffs/example-project/topic-handoff-filename/20260728-130000-claude-sonnet-main-validation.md
```

filenameのbranch-slugは本文の代替ではない。`Current state`の`Branch:`へ、置換前の完全なbranch名を引き続き記録する。

`latest.md`、`current.md`等の固定名を作らない。既存handoffを移動、rename、削除しない。この命名は新規handoffだけへ適用し、旧`<YYYYMMDD-HHMMSS>-<agent>-<phase>.md`形式の既存handoffはそのまま残す。必要なdirectoryだけ作る。
保存前に`<repo>`、`<scope>`、filenameがそれぞれ単一のpath要素であることを確認し、空要素、`.`、`..`、path区切りを含む値を拒否する。
解決済みの`~/handoffs`に検証済みの`<repo>/<scope>`を連結したpathを保存範囲とする。
未作成のdirectoryは既存の親から解決し、解決後の保存先をpath要素単位でその範囲と照合する。
directory作成後、書込み直前に保存範囲と対象repositoryの内外を再確認する。保存領域自身が対象の場合は、保存先が同じworktreeに属することも確認する。
同名の既存file、directory、symlink（リンク切れを含む）との衝突があれば保存を止める。
対象worktree内への保存では、HEAD / index / 保存前statusに同一pathがある場合も衝突として扱う。
fileは排他的に新規作成し、保存内容は共通`AGENTS.md`の機密情報の取り扱いに従う。

新規永続handoffでは、共通の必須情報に加えて次を記録する。

```text
External handoff: ~/handoffs/<repo>/<scope>/<filename>
Suggested repository path: docs/handoffs/<scope>/<filename>
Archive status: not archived
Authority: historical snapshot; not the current specification
```

Suggested pathは選別済みsnapshotを明示依頼で収蔵する場合の候補であり、ここでは作成しない。
保存領域自身が対象の場合は`External handoff`を`Handoff path`に置き換えて実際の保存先を記録し、`Suggested repository path`を省く。
この場合も`Archive status: not archived`と`Authority`を記録する。通常保存から収蔵やpublishへ進むには別の明示依頼が必要となる。

### 既定template

`Archive`欄は「永続fileの配置」のmetadata規則を保存先に応じて適用する。
`Git status`欄には、保存前のNUL区切りの観測を読みやすい形式で記録する。

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

保存前の観測

```text
<保存前のstatusの表示用整形>
```

## Git operations

- git add:
- commit:
- push:
````

構造変更が再開に重要な場合だけStructure before / afterを追加する。Issue単位指定等がある場合は、overlayに合わせてsectionを置換・拡張する。

### PR bodyとの関係

- 最新の出力指定が通常保存である成果物は、PR bodyの有無にかかわらず既定の永続fileを作る。
- PR bodyはhandoffのEvidenceや再利用元として参照できるが、自動的な代替にはしない。
- ユーザーが「PR bodyだけ」「外部handoff fileは不要」と明示した場合だけ、PR bodyを代替出力として扱える。
- PR bodyの作成・更新はGitHub mutationであるため、対象と操作内容の明示依頼を確認し、`github-safe-ops` Skillに従う。

PR bodyへ記録する場合も、scope / non-scope、validation、risk、nextを事実に合わせて残す。

### 永続handoffの検証

保存済みartifactのread-backと次の内容・path確認を行い、保存前と同じstatus commandを1回実行して比較する。
filenameや本文の照合には保存前の観測setを使う。path照合ではNUL区切りの元のstatusレコードを使う。

- filenameがtimestamp、agent、branch-slug、phaseを持つ。
- branch-slugが作成時点のbranch、またはdetached HEADの`detached-<short-sha>`と対応する。
- repo / scope directoryが正しい。
- 既存handoffをrename、移動、削除していない。
- 必須情報と、保存先に対応するarchive metadataがある。
- 本文の`Branch:`に完全なbranch名がある。
- `Archive status`が`not archived`である。
- 通常の開発repositoryでは保存前後のstatusが一致する。
- 保存領域自身が対象の場合は、今回の保存先に完全一致するrepository相対pathの未追跡レコード（`? <path>`）の追加だけを許容する。
  そのレコードを除いた全項目を保存前と比較し、既存のtracked / staged / untracked状態が保持されていることを確認する。
  statusに増分がない場合は当該pathがignore対象であることを確認し、status上の増分なしと記録する。
- handoffをstage、commit、pushしていない。

status一致だけでfile内容の完全不変を証明したとは扱わない。予期しない差分や競合の兆候があれば、該当するclaimだけRecoveryで扱う。
許容条件を満たさない場合は検証失敗として観測差分を報告し、保存操作に帰属すると確認できた増分だけをそのように記録する。
保存失敗・結果不明の場合は今回のartifactの存在と内容を先に確認し、同じ保存を無条件に繰り返さない。
所定の出力先へ書けない場合は未作成と理由を報告する。

### 最終報告

上記validation結果を再利用し、handoff path、該当する場合はsuggested archive path、必須情報確認、保存前のrepository状態と今回の保存による増分を簡潔に報告する。同じstateを別の最終確認として再取得しない。作業全体でのGit operationsと、handoff生成自体によるarchive / stage / commit / pushの有無を分ける。作業結果の最終報告にもhandoff pathを含める。
