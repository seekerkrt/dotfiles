---
name: handoff
description: コーディング、複数手順のリポジトリ調査・検証、Issue/PR作業、デバッグ、設計レビュー、実機/QEMU観測などの非自明な作業を終えるときに、ChatGPTへ渡す日時付きの日本語Markdown引き継ぎメモを作る。単純なtypo修正、1行程度の変更、単発の質問応答には通常使わない。
---

# 目的

ChatGPTへ作業結果を渡すための、短くても必要情報が揃った日本語Markdown引き継ぎメモを作成する。

長いターミナル出力をユーザーが手作業でコピーしなくても、次のChatGPT会話で状況を再開できるようにする。

# 使用条件

次のような非自明な作業の終了時に使用する。

- 複数ファイルにまたがる変更
- 複数手順を要した調査や検証
- 設計判断やトレードオフ検討を伴う作業
- Issue、PR、review、CI等に関する作業
- デバッグや責務境界の監査
- 実機、QEMU、VM、動画、外部ログ等の観測を伴う作業
- 作業が途中で止まり、次の会話へ正確に引き継ぐ必要がある場合

通常は次の作業には使用しない。

- 単純なtypo修正
- 1行程度の自明な変更
- 単発の質問応答

# 最重要ルール

- 実行ごとに日時を含む一意なファイル名を使う。
- `latest.md`や`current.md`等の固定名を作らない。
- 事実、推測、変更内容、検証結果、未確認点、次の一手を分ける。
- 作業していない内容を完了扱いしない。
- 実行していない検証を成功扱いしない。
- handoffファイルを `git add`、stage、commitしない。
- handoff作成を理由にpushしない。
- 作業対象repositoryとbranch、変更ファイル、実施・未実施作業を記録する。

# 出力先

引き継ぎメモは次のディレクトリ配下に作成する。

`~/handoff/`

ディレクトリが存在しない場合は作成してよい。

```bash
mkdir -p ~/handoff
```

引き継ぎメモ自体はrepository外の `~/handoff/` に置くため、通常は作業中repositoryの `git status` に出てこない。

# ファイル名

実行ごとに、タイムスタンプ付きの個別Markdownファイルを作成する。

形式:

`<agent>-<repo>[-issueNNまたはtask名]-<YYYYMMDD-HHMMSS>.md`

例:

- `~/handoff/codex-jadeos-20260629-081530.md`
- `~/handoff/codex-jadeos-issue24-20260629-081530.md`
- `~/handoff/claude-jpacker-issue154-20260629-081530.md`
- `~/handoff/codex-jadeos-usb-realhw-20260629-081530.md`

作成してはいけない固定名:

- `latest.md`
- `current.md`
- `codex-latest.md`
- `claude-latest.md`

# 基本ワークフロー

1. repository root、現在branch、HEAD、日時、agent名を確認する。
2. 読んだファイル、変更したファイル、実施内容、意図的な非目標を整理する。
3. 実行した検証commandと結果、未実施の検証と理由を整理する。
4. 既知の問題、リスク、未確認点、次の一手を整理する。
5. 命名規則に従って一意な出力先を決める。
6. 日本語Markdownでhandoffを作成する。
7. 作成内容とファイル名を確認する。
8. `git status --short --branch` を再確認し、handoffをstageしていないことを確認する。

# 必須内容

引き継ぎメモには、次の項目を含める。

1. リポジトリ名と現在ブランチ
2. 現在HEADまたはcommit状態
3. 作業日時とagent
4. 作業目的と意図的に守ったscope / non-scope
5. 読んだファイル
6. 変更したファイル
7. 実施した作業と実施していない作業
8. 変更内容または調査結果の要約
9. 実行した検証commandと結果
10. 既知の問題、リスク、不確実な点
11. 次に推奨する作業を1つ以上
12. `git status --short --branch` の結果
13. commit、pushの実施有無

# 検証結果の書き方

- commandを省略せず、実際に実行した形で記録する。
- 結果をpass、fail、partial、warning、未実施に分ける。
- 検証を実行していない場合は、未実施であることと理由を書く。
- build成功をruntime成功と読み替えない。
- 実機、QEMU、KVM、TCG、VirtualBox等を区別する。
- 実機、QEMU、動画確認、外部観測が絡む場合は、観測事実と解釈を分ける。
- USB/xHCI実機bring-upでは、ログに出た値、表示名、カウンタ名をできるだけ正確に残す。

# 推奨テンプレート

以下の形式を基本にする。

~~~markdown
# ChatGPT handoff: <repo> / <task>

## Repository

- Repo:
- Branch:
- Commit:
- Date:
- Agent:

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
- Scope / non-scope notes
- Validation
- Known issues / risks
- Next recommended action

ただし、次のいずれかに当てはまる場合は、`~/handoff/` にtimestamp付きhandoff Markdownを作成する。

- PRを作成していない
- branchをpushしていない
- 変更が未commit、または一部だけcommit済み
- 作業が調査途中で止まっている
- PR bodyに収まりにくい重要な観測、仮説、実機ログ、次の検証課題がある
- JadeOS USB実機bring-upのような長期調査・深掘り作業である

PR作成を指示されていたが失敗した場合もhandoff Markdownを作成する。その場合は、失敗理由、branch、commit状態、検証、次にやることを明記する。

# 禁止事項

- `latest.md`、`current.md`等の固定名を作ること
- handoffファイルの `git add`、stage、commit
- handoff作成を理由にしたpush
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
ls -l ~/handoff/
```

さらに次を確認する。

- ファイル名が一意で、日時を含む。
- 必須項目が揃っている。
- 実施済みと未実施が分かれている。
- handoffファイルをstageしていない。
- commitやpushを実施していない場合、その事実が書かれている。

# 最終報告

handoff作成後は、次を簡潔に報告する。

```text
handoff:
- 作成先: ~/handoff/<一意なファイル名>.md

確認:
- 必須項目確認済み
- git status確認済み

未確認:
- ...

未実施:
- git add
- commit
- push
```

作業結果そのものの最終報告にも、handoffの作成先を含める。
