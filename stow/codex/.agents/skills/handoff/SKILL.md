---
name: handoff
description: ユーザーが非自明な開発作業の結果について通常のhandoffや引き継ぎメモを求め、inline、本文だけ、保存不要、file不要、repository archiveを明示していない場合に、後の会話や別agentで再利用できる日本語Markdown fileをrepository外の~/handoff配下へ永続保存する。作業終了時の自動生成やdocs/handoffsへの収蔵には使用しない。
---

# 目的

ChatGPTへ作業結果を渡すための、短くても必要情報が揃った日本語Markdown引き継ぎメモを作成する。

長いターミナル出力をユーザーが手作業でコピーしなくても、次のChatGPT会話で状況を再開できるようにする。

handoffファイルはrepository外の`~/handoff`配下へ永続保存する。repositoryへの収蔵は、ユーザーの明示指示に基づく`handoff-archive`へ分離する。

# 使用条件

ユーザーが永続的なhandoff fileの作成を求めた場合、または作業指示に通常handoffの作成が含まれる場合に限り、次のような非自明な作業の終了時に使用する。

- 複数ファイルにまたがる変更
- 複数手順を要した調査や検証
- 設計判断やトレードオフ検討を伴う作業
- Issue、PR、review、CI等に関する作業
- デバッグや責務境界の監査
- 実機、QEMU、VM、動画、外部ログ等の観測を伴う作業
- 作業が途中で止まり、次の会話へ正確に引き継ぐ必要がある場合

特に出力方式の指定がない「handoff」「引き継ぎメモ」「次スレ用の引き継ぎを作って」は、後からアップロード、再利用できる永続fileを求める通常handoffとして扱う。

通常は次の作業には使用しない。

- 単純なtypo修正
- 1行程度の自明な変更
- 単発の質問応答
- handoff作成が依頼や作業指示に含まれていない単なる作業終了
- `inline`、`handoff-inline`、本文だけ、保存不要、file不要、ファイル不要、このチャットに出す等が明示された依頼
- repositoryへの保存、archive、収蔵、`docs/handoffs`への保存が明示された依頼

出力方式が競合した場合の優先順位は、明示的なarchive指示、明示的なinlineまたはfile不要指示、通常handoffの順とする。

- 「handoffをinlineで」「保存不要の引き継ぎメモ」: `handoff-inline`
- 「このhandoffをdocs/handoffsへarchive」: `handoff-archive`
- 単なる「引き継ぎメモよろしく」: `handoff`

# 最重要ルール

- 実行ごとに日時を含む一意なファイル名を使う。
- `latest.md`や`current.md`等の固定名を作らない。
- handoffはrepository外へ作成し、repositoryへの収蔵は別の`handoff-archive`作業へ分離する。
- handoff作成によって、作業対象repositoryを作成前よりdirtyにしない。
- 事実、推測、変更内容、検証結果、未確認点、次の一手を分ける。
- 作業していない内容を完了扱いしない。
- 実行していない検証を成功扱いしない。
- handoffファイルを`git add`、stage、commitしない。
- handoff作成を理由にpushしない。
- 作業対象repositoryとbranch、変更ファイル、実施・未実施作業を記録する。

# 出力先

handoffはrepository外の次のディレクトリへ作成する。

`~/handoff/<repo>/<scope>/`

`<repo>`には作業対象repositoryの名前を使う。`<scope>`は次の順で決める。

repository名の例は`jadeos`、`jpacker`、`cade-lang`、`game-engine`、`dotfiles`とする。

- GitHub Issueがある: `issue-<number>`
- Issueがなく、PRだけを対象とする: `pr-<number>`
- Issue / PR番号がない特定テーマ: `topic-<short-slug>`
- repository全体または分類不能: `general`

PRがIssueに対応している場合は`issue-<number>`を使う。`<short-slug>`は内容を識別できる短いkebab-caseにする。

例:

- `~/handoff/jadeos/issue-211/`
- `~/handoff/jpacker/issue-225/`
- `~/handoff/cade-lang/topic-semantic-result/`
- `~/handoff/game-engine/general/`

必要なディレクトリだけ作成してよい。

```bash
mkdir -p ~/handoff/<repo>/<scope>
```

既存のflatな`~/handoff/*.md`は移動、rename、削除しない。新規作成分からこの階層契約を適用する。

# ファイル名

実行ごとに、タイムスタンプを先頭に持つ個別Markdownファイルを作成する。

形式:

`<YYYYMMDD-HHMMSS>-<agent>-<phase>.md`

agent名の例:

- `codex`
- `claude-fable5`
- `claude-sonnet`

phaseの標準候補:

- `audit`
- `design`
- `investigation`
- `implementation`
- `validation`
- `commit-push`
- `pr-create`
- `pr-review`
- `merge-cleanup`
- `release`

標準候補に合わない場合だけ、作業段階を表す短いkebab-caseのphaseを使ってよい。

例:

- `20260720-074843-claude-fable5-audit.md`
- `20260720-075145-codex-audit.md`
- `20260720-093000-codex-implementation.md`
- `20260720-103000-codex-validation.md`
- `20260720-110000-codex-pr-create.md`

作成してはいけない固定名:

- `latest.md`
- `current.md`
- `codex-latest.md`
- `claude-latest.md`

# Repository archiveとの責務分離

通常のhandoffはrepository外へ作成する。repositoryへの収蔵は、別の`handoff-archive`作業で行う。

`handoff-archive`は次の経路で収蔵する。

```text
~/handoff/<repo>/<scope>/<filename>
  ↓
<repository>/docs/handoffs/<scope>/<filename>
```

archiveを行うには、ユーザーから対象を特定した明示的な指示が必要である。

通常のhandoffでは、次を行わない。

- `docs/handoffs/`への自動コピー
- 作業対象repository内へのfile作成
- archive目的のbranch作成、切替
- archive目的の`git add`、commit、push
- 外部handoffの自動削除
- 外部handoffの自動移動、rename
- archive済みかどうかの推測
- 作業終了時の自動archive
- PR作成時の自動archive
- Issue close時の自動archive

`Suggested repository path`は将来の収蔵先の提案にすぎない。通常のhandoff実行では作成しない。

作業対象repositoryに既存変更がある場合はその状態を保持する。handoff作成前後の`git status`を比較し、handoffによる差分を追加しない。

# Authority policy

情報が競合する場合のauthorityは、原則として次の順に扱う。

1. 現在のsource code
2. 採用済みのGitHub Issue / Pull Request上の決定
3. 正式なarchitecture / decision document
4. repositoryへ収蔵されたagent handoff
5. repository外の未収蔵handoff

handoffは`historical snapshot; not the current specification`として扱う。repositoryへ収蔵されても、現在のsource codeや採用済みの決定より上位の正本にはならない。

handoff内の次の情報は、すべて作成時点のsnapshotである。

- branch
- commit SHA
- line番号
- caller一覧
- repository状態
- validation結果
- agentの推奨
- agentの推測

agentの推奨は、ユーザーが採用した設計判断とは限らない。推測は事実と分け、未確認であることを明記する。

# 基本ワークフロー

1. repository root、repository名、現在branch、HEAD、日時、agent名を確認する。
2. Issue / PRとの対応を確認し、scopeとphaseを決める。分類不能ならscopeは`general`にする。
3. handoff作成前の`git status --short --branch`を記録する。
4. 読んだファイル、変更したファイル、実施内容、意図的な非目標を整理する。
5. 実行した検証commandと結果、未実施の検証と理由を整理する。
6. 既知の問題、リスク、未確認点、次の一手を整理する。
7. 命名規則に従って一意な外部出力先とSuggested repository pathを決める。
8. 必要な外部ディレクトリだけ作成し、日本語Markdownでhandoffを作成する。
9. 作成内容、directory、ファイル名、Archive metadataを確認する。
10. `git status --short --branch`を再確認し、作業対象repositoryがhandoffによって変化していないことと、handoffをstage、commit、pushしていないことを確認する。

# 必須内容

引き継ぎメモには、次の項目を含める。

1. リポジトリ名と現在ブランチ
2. 現在HEADまたはcommit状態
3. 作業日時とagent
4. Phase
5. 作業目的と意図的に守ったscope / non-scope
6. 読んだファイル
7. 変更したファイル
8. 実施した作業と実施していない作業
9. 変更内容または調査結果の要約
10. 実行した検証commandと結果
11. 既知の問題、リスク、不確実な点
12. 次に推奨する作業を1つ以上
13. External handoff path
14. Suggested repository path
15. Archive status
16. Authority
17. `git status --short --branch`の結果
18. `git add`、commit、pushの実施有無

新規handoffのArchive statusは`not archived`とする。GitHubまたはfilesystemでarchive済みと確認していない限り、`not archived`から変更しない。通常のhandoffではarchiveを実行せず、archive済みとは推測しない。

# 検証結果の書き方

- commandを省略せず、実際に実行した形で記録する。
- 結果をpass、fail、partial、warning、未実施に分ける。
- 検証を実行していない場合は、未実施であることと理由を書く。
- build成功をruntime成功と読み替えない。
- 実機、QEMU、KVM、TCG、VirtualBox等を区別する。
- 実機、QEMU、動画確認、外部観測が絡む場合は、観測事実と解釈を分ける。
- USB/xHCI実機bring-upでは、ログに出た値、表示名、カウンタ名をできるだけ正確に残す。

# 推奨テンプレート

以下の形式を基本にする。Archiveの値は実際のtaskに合わせる。

~~~markdown
# ChatGPT handoff: <repo> / <task>

## Repository

- Repo:
- Branch:
- Commit:
- Date:
- Agent:

## Archive

- Phase: audit
- External handoff: `~/handoff/jadeos/issue-211/20260720-075145-codex-audit.md`
- Suggested repository path: `docs/handoffs/issue-211/20260720-075145-codex-audit.md`
- Archive status: not archived
- Authority: historical snapshot; not the current specification

## Task

<依頼された作業内容と、意図的に守った作業範囲を書く。>

## Structure before

<構造変更がある場合、編集前の配置を書く。該当しない場合は省略してよい。>

## Structure after

<構造変更がある場合、編集後の配置を書く。該当しない場合は省略してよい。>

## Files read

- `path/to/file`
- `path/to/file`

## Files changed

- `path/to/file`
- `path/to/file`

変更がない場合:

- 変更なし。

## Work completed

- <実施した作業>

## Work not performed

- <実施していない作業と理由>

## Summary

<実施内容または調査結果を、日本語で簡潔にまとめる。>

## Validation

実行したcommand:

```bash
<command>
```

結果:

- pass / fail / partial / warning
- 重要な出力やメモ

検証していない場合:

- 検証は未実行。
- 理由:

## Known issues / risks

- <リスクまたは不確実な点>
- <未確認事項>

## Next recommended action

1. <次にやるとよいこと>
2. <次にやるとよいこと>

## Git status

```text
<git status --short --branch の出力>
```

## Git operations

- git add: 未実施 / 実施
- commit: 未実施 / 実施
- push: 未実施 / 実施
~~~

# PR作成時のhandoff方針

作業branchをpushし、draft PRを作成できた場合は、原則として別途handoff Markdownは作成しない。

この場合は、PR bodyをhandoffとして扱えるように十分な情報を書く。PR bodyには次を含める。

- Summary
- Scope / non-scope
- Validation
- Known issues / risks
- Next recommended action

ただし、次のいずれかに当てはまる場合は、`~/handoff/<repo>/<scope>/`にtimestamp付きhandoff Markdownを作成する。

- PRを作成していない
- branchをpushしていない
- 変更が未commit、または一部だけcommit済み
- 作業が調査途中で止まっている
- PR bodyに収まりにくい重要な観測、仮説、実機ログ、次の検証課題がある
- JadeOS USB実機bring-upのような長期調査・深掘り作業である
- PRの作成に失敗した

PR作成を指示されていたが失敗した場合もhandoff Markdownを作成する。その場合は、失敗理由、branch、commit状態、検証、次にやることを明記する。

# 禁止事項

- `latest.md`、`current.md`、`codex-latest.md`、`claude-latest.md`等の固定名を作ること
- handoffファイルの`git add`、stage、commit
- handoff作成を理由にしたpush
- `docs/handoffs/`への自動コピー
- 作業対象repository内へのfile作成
- archive目的のbranch作成、切替、`git add`、commit、push
- 外部handoffを自動で削除すること
- 外部handoffを自動で移動、renameすること
- archive済みかどうかを推測すること
- 作業終了時、PR作成時、Issue close時に自動archiveすること
- handoff作成によって作業対象repositoryを作成前よりdirtyにすること
- 作業していない変更や検証を完了扱いすること
- 未確認事項を事実として書くこと
- 長いlogを根拠整理なしにそのまま貼ること
- ユーザーの既存変更をrestore、reset、stash、cleanすること

# 失敗時・未確認時の扱い

- 不明点は断定せず「未確認」または「要確認」と書く。
- commandが失敗した場合は、失敗したcommand、理由、部分成功の有無を記録する。
- 出力先へ書き込めない場合は、固定名やrepository内fileで代用せず、handoff未作成と理由を報告する。
- branch、HEAD、GitHub状態等を確認できない場合は、推測で埋めない。
- 外部観測の解釈に確信がない場合は、観測値と仮説を別項目にする。
- ファイル変更がない場合は「変更なし」と明記する。
- 調査のみの場合は、調査結果と次の一手を中心に書く。

# 作成後の確認

作成後、最低限次を確認する。

```bash
git status --short --branch
test -f ~/handoff/<repo>/<scope>/<filename>
ls -l ~/handoff/<repo>/<scope>/
```

さらに次を確認する。

- timestampがfilenameの先頭にある。
- agent名を含む。
- phaseを含む。
- repository directoryが正しい。
- scope directoryが正しい。
- Suggested repository pathを記録している。
- Archive statusが`not archived`である。
- Authorityがhistorical snapshotである。
- handoffによって作業対象repositoryが作成前よりdirtyになっていない。
- handoffをstageしていない。
- handoffをcommitしていない。
- handoff作成だけを理由にpushしていない。
- 必須項目が揃っている。
- 実施済みと未実施が分かれている。

# 最終報告

handoff作成後は、次を簡潔に報告する。

```text
handoff:
- 作成先: ~/handoff/<repo>/<scope>/<filename>

archive:
- 推奨先: docs/handoffs/<scope>/<filename>
- repositoryへのコピー: 未実施

確認:
- 必須項目確認済み
- git status確認済み
- repositoryはhandoff作成によって変更されていない

未確認:
- ...

未実施:
- repositoryへのarchive
- git add
- commit
- push
```

作業結果そのものの最終報告にも、handoffの作成先を含める。
