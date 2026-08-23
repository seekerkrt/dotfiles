---
name: handoff-archive
description: ユーザーが選別済みの外部handoffをrepositoryへ保存、archive、収蔵、またはdocs/handoffsへcopyすると明示し、source fileをexact pathまたは一意な候補として特定でき、scopeとtarget repositoryが確定している場合に使用する。source検証、sensitive content preflight、衝突防止、byte-identical copy、SHA比較を行い、stage / commit / pushはしない。
---

# Handoff archive

## 責務

選別済みの外部handoffを、明示依頼に基づいて次の経路で収蔵する。

```text
~/handoff/<repo>/<scope>/<filename>.md
  ↓ byte-identical copy
<repository>/docs/handoffs/<scope>/<filename>.md
```

通常handoff生成、inline出力、archive候補の相談、自動archive、publishは扱わない。sourceを編集、rename、移動、削除しない。destinationを上書きしない。

## Source selection

原則としてユーザーが指定したexact pathを使う。

```text
exact pathあり:
  そのfileを検証する

repo / scopeだけ指定、候補が1file:
  そのfileを候補にできる

候補が0または複数:
  copyせず、一覧と不足情報を報告する
```

`latest`、mtime、曖昧なglobだけで複数候補から選ばない。複数fileはexact listまたは明確な集合が指定された場合だけ扱う。

## Filename形式

新規に生成されるhandoffは次の形式を要求する。

```text
<YYYYMMDD-HHMMSS>-<agent>-<branch-slug>-<phase>.md
```

次のlegacy形式もarchive対象として受理する。

```text
<YYYYMMDD-HHMMSS>-<agent>-<phase>.md
```

- legacy filenameからbranch名を推測しない。
- archive時にbranch-slugを追加するrenameをしない。
- source filenameをそのままdestinationへ維持する。

## Source validation

各sourceについて確認する。

- regular Markdown fileで、symlinkではない。
- 解決後も`~/handoff/<repo>/<scope>/`配下にあり、path traversalがない。
- 読み取り可能でemptyではない。
- filenameが新形式`<YYYYMMDD-HHMMSS>-<agent>-<branch-slug>-<phase>.md`、またはlegacy形式`<YYYYMMDD-HHMMSS>-<agent>-<phase>.md`である。
- repository、task、summary / completed、validation、Git status、Git operationsに相当する情報がある。
- handoff内のRepoとtarget repositoryが一致する。

古い形式でsectionが欠ける場合は自動修正せず停止する。ユーザーがそのexact fileの継続を明示した場合だけ次へ進む。

copy前にsourceのSHA-256を記録し、copy後も同じ値であることを確認する。

## Sensitive content preflight

repositoryへ公開され得るため、強いcredential patternだけを確認する。

- private key block
- GitHub / OpenAI / Anthropic / AWS / Slack等の既知key形式
- `Authorization: Bearer`、`Cookie`、session token
- credential valueを伴うpassword / token assignment

一般語としての`token`や`password`だけでcredentialと断定しない。疑いがある場合はcopyせず、file、line、pattern種別だけを報告する。値を再表示、自動redaction、source変更しない。

absolute local pathやusernameはbyte-identical archiveでは保持される。その点を最終報告へ明記する。

## Target preflight

次を確認する。

```bash
git status --short --branch
git rev-parse --show-toplevel
git branch --show-current
git rev-parse HEAD
git remote
git branch -vv
```

- repository名、root、branch、HEAD、remote名 / upstreamが依頼対象と一致する。
- detached HEAD、merge / rebase / cherry-pick進行中ではない。
- destination解決先がrepository内の`docs/handoffs/<scope>/`に収まる。
- target pathと衝突する既存変更がない。
- unrelatedな既存変更からarchive scopeを分離できる。

target確認だけを目的に生のremote URLを出力しない。GitHub上のrepository名が必要なら、安全なread-only metadataで確認し、取得できなければ未確認として停止する。branch switch、pull、fetch、reset、restore、stash、cleanは行わない。

## Collision policy

destinationは次とする。

```text
docs/handoffs/<scope>/<source-filename>
```

同名fileが存在する場合はSHA-256を比較する。

- 一致: `already archived`として書き換えない。
- 不一致: 上書き、renameによる回避をせず停止する。

sourceのtimestamp、agent、branch-slug、phaseをarchive時に書き換えない。legacy形式に存在しないbranch-slugを補完しない。byte-identical copy契約はどちらの形式でも同じとする。

## README policy

`docs/handoffs/README.md`があれば、handoffがhistorical snapshotで現在仕様の正本ではなく、source code、採用済み決定、正式docsを優先する意味を持つか確認する。

READMEがない最初のarchiveでは、次の意味だけを持つ短いREADMEを作成候補にできる。

- handoffは作成時点のsnapshotである。
- 現在仕様・設計・実装のsource of truthではない。
- branch、SHA、line、推奨、未確認は作成時点の情報である。

既存READMEに不足がある場合は無断更新せず、同じarchive依頼へ含めるか確認する。

## Copy workflow

1. 明示依頼、source、target、scopeを確定する。
2. source形式と必須情報を検証する。
3. sensitive content preflightを行う。
4. target repositoryとworking treeを確認する。
5. destinationとREADMEの衝突を確認する。
6. 必要なdirectoryだけ作る。
7. `cp --no-clobber`でcopyする。
8. SHA-256と`cmp -s`でbyte-identicalを確認する。
9. source不変、destination mode、Git diff、working treeを確認する。

archive時にMarkdown整形、typo修正、heading変更、path置換、line更新、metadata追記、agent判断の書き換えを行わない。正式文書化は別taskへ分ける。

## Validation

```bash
git status --short --branch
git diff --check -- docs/handoffs
git diff --stat -- docs/handoffs
test -f docs/handoffs/<scope>/<filename>
cmp -s \
  ~/handoff/<repo>/<scope>/<filename> \
  docs/handoffs/<scope>/<filename>
sha256sum \
  ~/handoff/<repo>/<scope>/<filename> \
  docs/handoffs/<scope>/<filename>
```

source不変、destination存在、byte-identical、通常text mode、scope外の変更なし、stage / commit / pushなしを確認する。

## Publish boundary

このSkillはcopyと検証までを行う。`git add`、commit、push、PR、Issue更新、branch操作、source削除は行わない。同じ依頼にpublishが含まれていても、archive結果を確認した後の別workflowとして扱う。

## 失敗時と出力

- 不明なsource、repo不一致、path traversal、sensitive content、destination衝突、進行中Git操作ではcopyせず停止する。
- partial copyやtimeoutでは、再実行前にsource / destinationの存在、SHA、statusを読む。
- source、destination、README、preflight結果、byte-identical確認、local path保持、repository状態、変更file、未実施Git操作を報告する。
