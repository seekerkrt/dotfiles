---
name: handoff
description: "コーディング作業、リポジトリ調査、検証、Issue/PR作業、デバッグ、設計レビューを終えるときに、ChatGPTへ渡すための日本語Markdown引き継ぎメモを作成する。対象の目安: 複数ファイルにまたがる変更、複数手順を要した調査・検証、設計判断やトレードオフ検討を伴う作業、実機/QEMU観測を伴うデバッグ。対象外: 単純なtypo修正、1行程度の変更、単発の質問応答。"
model: claude-haiku-4-5-20251001
---

# 目的

ChatGPTへ作業結果を渡すための、短くても必要情報が揃ったMarkdown引き継ぎメモを作成する。

長いターミナル出力をユーザーが手作業でコピーしなくても、次のChatGPT会話で状況を再開できるようにする。

# 出力先

引き継ぎメモは次のディレクトリ配下に作成する。

`~/handoff/`

ディレクトリが存在しない場合は作成してよい。

```bash
mkdir -p ~/handoff
```

# ファイル名

実行ごとに、タイムスタンプ付きの個別Markdownファイルを作成する。

形式:

`<agent>-<repo>[-issueNNまたはtask名]-<YYYYMMDD-HHMMSS>.md`

例:

- `~/handoff/codex-jadeos-20260629-081530.md`
- `~/handoff/codex-jadeos-issue24-20260629-081530.md`
- `~/handoff/claude-jpacker-issue154-20260629-081530.md`
- `~/handoff/codex-jadeos-usb-realhw-20260629-081530.md`

作成してはいけないファイル:

- `latest.md`
- `current.md`
- `codex-latest.md`
- `claude-latest.md`

# 必須内容

引き継ぎメモには、次の項目を含める。

1. リポジトリ名と現在ブランチ
2. 作業目的と意図的に守ったscope / non-scope
3. 読んだファイル
4. 変更したファイル
5. 実施した作業と実施していない作業
6. 変更内容または調査結果の要約
7. 実行した検証コマンドと結果
8. 既知の問題、リスク、不確実な点
9. 次に推奨する作業
10. `git status --short --branch` の結果
11. commit、pushの実施有無

# ルール

- 引き継ぎメモは git add しない。
- 引き継ぎメモは commit しない。
- 引き継ぎメモは stage しない。
- 事実と推測を分けて書く。
- 検証していないことを成功扱いしない。
- 検証を実行していない場合は、実行していないことと理由を書く。
- ファイル変更がない場合は「変更なし」と明記する。
- 調査のみの場合は、調査結果と次アクションを中心に書く。
- 実機、QEMU、動画確認、外部観測が絡む場合は、観測事実と解釈を分ける。
- USB/xHCI実機bring-upでは、ログに出た値、表示名、カウンタ名をできるだけ正確に残す。
- 不明点は断定せず「未確認」「要確認」と書く。

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

実行したコマンド:

```bash
<command>
```

結果:

- pass / fail / partial
- 重要な出力やメモ

検証していない場合:

- 検証は未実行。
- 理由:

## Known issues / risks

- <リスクまたは不確実な点>
- <リスクまたは不確実な点>

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

引き継ぎメモ自体はリポジトリ外の `~/handoff/` に置くため、通常は作業中リポジトリの `git status` に出てこない。
