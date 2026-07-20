---
name: handoff-archive
description: ユーザーが選別済みの外部handoff fileをrepositoryへ保存、archive、収蔵、またはdocs/handoffsへcopyすると明示し、対象file、scope、repositoryが確定している場合だけ安全に収蔵する。通常handoff生成、inline、本文だけ、保存不要、相談だけ、作業終了・PR作成・Issue close時の自動archiveには使用しない。
---

# 目的

repository外に保存された選別済みagent handoffを、ユーザーの明示的な指示に基づいて対象repositoryへ収蔵する。

入力と出力の責務を次に限定する。

```text
入力:
  ~/handoff/<repo>/<scope>/<filename>.md

出力:
  <repository>/docs/handoffs/<scope>/<filename>.md
```

通常の`handoff`はrepository外へ生成し、`handoff-archive`は明示的に選ばれたhandoffだけをrepositoryへ収蔵する。この責務を混ぜない。

# 使用条件

次をすべて満たす場合だけ使用する。

- ユーザーがhandoffをrepositoryへ保存、収蔵、archive、または`docs/handoffs`へcopyしたいと明示している。
- archive元handoffが存在する。
- archive対象repositoryが特定できる。
- archive対象scopeが特定できる。
- repositoryへのfile追加が意図された作業である。

次の場合は使用しない。

- 通常のhandoff生成
- 作業終了時の自動archive
- PR作成時の自動archive
- Issue close時の自動archive
- `handoff-inline`、inline、本文だけ、保存不要、file不要、ファイル不要の依頼
- repository外handoffの単なる閲覧
- archive候補の相談だけ
- ユーザーがrepository変更を求めていない場合

出力方式が競合した場合の優先順位は、明示的なarchive指示、明示的なinlineまたはfile不要指示、通常handoffの順とする。repository保存、archive、収蔵、`docs/handoffs`へのcopyが明示されている場合だけ、このskillを選ぶ。

# 最重要ルール

- archive対象を推測せず、ユーザーが明示したfileまたは明確な集合だけを扱う。
- sourceを編集、rename、移動、削除しない。
- 通常はsourceをbyte-identicalでコピーし、内容をarchive時に改善しない。
- credentialの疑いがあればcopy前に停止し、自動redactionしない。
- destinationを無条件に上書きしない。
- unrelated changeを変更、stageしない。
- archive後のpublishは別workflowへ分離し、`git add`、commit、push、PR作成を行わない。

# Source selection

archive元は原則として、ユーザーが指定したexact pathを使用する。

推奨形式:

`~/handoff/<repo>/<scope>/<timestamp>-<agent>-<phase>.md`

選択規則:

```text
exact file pathが指定されている:
  そのfileを確認して使用

repo / scopeだけが指定され、そのscope内に候補が1fileだけ:
  そのfileを使用してよい

候補が複数:
  candidate一覧を表示し、archiveを実行せず停止

候補が0:
  archiveを実行せず停止
```

`latest`という名前やmtimeだけで、複数候補から自動選択しない。globで複数fileを無断archiveしない。

複数fileをarchiveする場合は、ユーザーがexact listまたは明確な集合を指定していることを確認する。選択範囲が曖昧ならcopy前に停止する。

# Source validation

archive元ごとに次を確認する。

- path自体がregular fileである。
- Markdown fileである。
- symlinkではない。
- `~/handoff/<repo>/<scope>/`配下にある。
- `..`等のpath traversalを含まず、解決後も許可されたscope配下に収まる。
- 読み取り可能である。
- empty fileではない。
- filenameが`<YYYYMMDD-HHMMSS>-<agent>-<phase>.md`形式である。
- contentがhandoffとして最低限のsectionを持つ。

最低限確認するsection:

```text
## Repository
## Task
## Summary
## Validation
## Git status
## Git operations
```

古いhandoffで一部sectionが欠ける場合は、自動修正せず不足sectionを報告して停止する。ユーザーがその古いhandoffのarchive継続を明示した場合だけ、後続preflightへ進む。

source fileは検証中もcopy後も編集、rename、移動、削除しない。copy前のSHA-256を記録し、copy後にもsourceが同じ値であることを確認する。

# Sensitive content preflight

repositoryへ公開され得るため、copy前に強いcredential patternを確認する。

確認対象の例:

- private key block
- GitHub personal access token
- OpenAI / Anthropic API key
- AWS access key
- Slack token
- `Authorization: Bearer` header
- `Cookie` header
- session token
- passwordを含むcredential assignment

単なる`token`、`password`という一般語だけでcredentialと断定しない。値の形式、prefix、周辺構文を含む強いpatternで判断する。

実credentialの疑いがある場合は次を守る。

- archiveせず停止する。
- 該当内容を全文再表示しない。
- file、line、pattern種別だけを報告する。
- 自動redactionしない。
- source fileを変更しない。

absolute home path、username、local checkout path等は自動削除しない。preflightを通過してcopyする場合、それらを保持したexact archiveになることを最終報告へ記録する。

# Target repository preflight

対象repositoryについて次を確認する。

- repository名
- repository root
- current branch
- HEAD
- remote
- `git status --short --branch`
- intended repo名とhandoffの`Repo`が一致すること
- `docs/handoffs/`とdestinationの解決先がrepository内に収まること

次の場合は変更せず停止する。

- repositoryが特定できない。
- handoffの`Repo`と対象repositoryが不一致である。
- detached HEADである。
- merge、rebase、cherry-pickが進行中である。
- destinationにpath traversalが生じる。
- target fileに既存の異なる内容がある。
- working treeに対象archiveと衝突する既存変更がある。
- 安全にscopeを分離できない。

無関係な既存変更がある場合は、その存在を記録して内容を変更、stageしない。

branch switch、pull、fetch、reset、restore、stash、cleanを自動実行しない。ユーザーがarchive用に準備した現在branchでのみ作業する。

remoteを確認するときもcredentialを探索、表示しない。remote URLにcredentialらしい値が含まれる場合は値を再表示せず報告する。

# Destination

保存先は次とする。

`docs/handoffs/<scope>/<filename>`

例:

- `docs/handoffs/issue-211/20260720-074843-claude-fable5-audit.md`
- `docs/handoffs/issue-211/20260720-075145-codex-audit.md`
- `docs/handoffs/topic-semantic-result/20260720-130000-codex-audit.md`

source filenameを維持し、agent名、timestamp、phaseをrenameしない。directoryが存在しない場合は必要なdirectoryだけ作成してよい。

同名fileが存在する場合は、sourceとdestinationのSHA-256を比較する。

```text
SHA-256が一致:
  already archivedとして扱い、書き換えない

SHA-256が不一致:
  上書きせず停止
```

`cp --force`、無条件overwrite、renameによる衝突回避を行わない。

# Copy contract

通常はsourceをbyte-identicalでコピーする。

推奨操作:

```bash
mkdir -p <repo>/docs/handoffs/<scope>
cp --no-clobber \
  ~/handoff/<repo>/<scope>/<filename> \
  <repo>/docs/handoffs/<scope>/<filename>
```

コピー後にSHA-256を比較する。

```bash
sha256sum \
  ~/handoff/<repo>/<scope>/<filename> \
  <repo>/docs/handoffs/<scope>/<filename>
```

さらに`cmp -s`でbyte-identicalを確認する。sourceとdestinationが一致しない場合は成功扱いしない。

archive時に次を行わない。

- content整形
- Markdown formatter
- heading変更
- typo修正
- agent判断の修正
- path置換
- line番号更新
- metadata追記
- 推奨案の書き換え

内容を整理、要約した正式文書が必要な場合は、`docs/audit/`やarchitecture docsへ別成果物として作成し、archive copyへ混ぜない。

# README policy

`docs/handoffs/README.md`が存在する場合は内容を確認し、最低限次の意味が含まれていることを確認する。

- agent handoffは作成時点の履歴snapshotである。
- 現在の仕様、設計、実装の正本ではなく、`not the current specification`として扱う。
- source code、採用済みIssue / PR、正式docsを優先する。
- branch、SHA、line番号、推奨は作成時点の情報である。

READMEが存在しない場合は、最初のarchive作業で次の標準READMEを新規作成してよい。

```markdown
# Agent handoffs

このdirectoryには、AI agentによる調査、設計、実装、検証、
PR作成等の引き継ぎスナップショットを保存する。

これらは作成時点のrepository状態とagentの判断を記録した履歴資料であり、
現在の仕様、設計、実装の正本ではない。

原則として、情報の優先順位は次のとおり。

1. 現在のsource code
2. 採用済みのGitHub Issue / Pull Request上の決定
3. 正式なarchitecture / decision document
4. 本directoryのagent handoff

handoff内のbranch、commit SHA、line番号、caller一覧、推奨案、
未確認事項は作成時点の情報として扱う。

agentの推奨や仮説は、ユーザーが採用した設計判断とは限らない。
```

既存READMEを無断で置換しない。不足がある場合は内容を報告して停止し、README更新を同じarchive作業へ含めるかユーザーの明示指示を確認する。

# Git policy

archiveはrepository内へfileを追加するため、実行後はworking treeがdirtyになる。その事実とarchive前後のstatusを正確に報告する。

通常の`handoff-archive`では次を行わない。

- `git add`
- stage
- commit
- push
- PR作成
- Issue更新
- branch作成、切替
- source handoff削除

ユーザーが同じ依頼でcommit、pushまで明示した場合でも、このskillの基本責務はcopyと検証までとする。commit、pushは別の明示的なpublish workflowへ委ねる。

# 基本ワークフロー

1. ユーザーの明示指示とsource selectionを確認する。
2. source path、filename、必須sectionを検証する。
3. sensitive content preflightを行う。
4. target repository、handoffのRepo、branch、HEAD、remote、statusを確認する。
5. destinationと既存fileの衝突を確認する。
6. `docs/handoffs/README.md`の状態を確認する。
7. 必要なdirectoryと、許可される場合だけ標準READMEを作成する。
8. `cp --no-clobber`でsourceをcopyする。
9. SHA-256と`cmp -s`でsourceとdestinationを比較する。
10. source不変、destination、file mode、Git差分を検証する。
11. publish操作を行わず最終報告する。

# Validation

archive後に最低限次を実行する。

```bash
git status --short --branch
git diff --check -- docs/handoffs
git diff --stat -- docs/handoffs
```

各archive fileについて次を実行する。

```bash
test -f docs/handoffs/<scope>/<filename>
cmp -s \
  ~/handoff/<repo>/<scope>/<filename> \
  docs/handoffs/<scope>/<filename>
```

次を確認する。

- sourceが変更されていない。
- destinationが存在する。
- sourceとdestinationがbyte-identicalである。
- destination file modeが通常のtext fileである。
- destinationが`docs/handoffs/<scope>/`配下にある。
- unrelated fileを変更していない。
- stageしていない。
- commitしていない。
- pushしていない。

# 最終報告

次の形式を基本にする。

```text
archive:
- source: ~/handoff/<repo>/<scope>/<filename>
- destination: docs/handoffs/<scope>/<filename>
- copy: byte-identical
- README: existing / created / unchanged
- sensitive-content preflight: pass / stopped
- local paths: preserved in exact archive

repository:
- root:
- branch:
- HEAD:
- status:

changed:
- docs/handoffs/README.md
- docs/handoffs/<scope>/<filename>

未実施:
- source handoff変更
- git add
- commit
- push
- PR作成
```

READMEを作成していない場合は`changed`へ含めない。複数fileの場合はsourceとdestinationをすべて列挙する。

# 禁止事項

- 通常handoff作成時の自動archive
- archive対象の推測
- 複数候補からmtimeだけで自動選択
- globによる無断の複数archive
- source handoffの編集、削除、移動、rename
- destinationの無条件overwrite
- filename変更
- content normalization
- credentialの自動redaction
- unrelated docs変更
- source code変更
- branch switch
- pull、fetch
- reset、restore、stash、clean
- `git add`
- commit
- push
- PR作成
- Issue更新
