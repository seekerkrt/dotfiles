---
name: chatgpt-handoff
description: "非自明なコーディング作業、リポジトリ調査、検証、Issue/PR作業、デバッグ、設計レビューを終えるときに、ChatGPTへ渡すための日本語Markdown引き継ぎメモを作成する。"
---

# 目的

ChatGPTへ作業結果を渡すための、短くても必要情報が揃ったMarkdown引き継ぎメモを作成する。

長いターミナル出力をユーザーが手作業でコピーしなくても、次のChatGPT会話で状況を再開できるようにする。

# 出力先

引き継ぎメモは次のディレクトリ配下に作成する。

`~/chatgpt-handoff/`

ディレクトリが存在しない場合は作成してよい。

```bash
mkdir -p ~/chatgpt-handoff
```

# ファイル名

実行ごとに、タイムスタンプ付きの個別Markdownファイルを作成する。

形式:

`<agent>-<repo>[-issueNNまたはtask名]-<YYYYMMDD-HHMMSS>.md`

例:

- `~/chatgpt-handoff/codex-jadeos-20260629-081530.md`
- `~/chatgpt-handoff/codex-jadeos-issue24-20260629-081530.md`
- `~/chatgpt-handoff/claude-jpacker-issue154-20260629-081530.md`
- `~/chatgpt-handoff/codex-jadeos-usb-realhw-20260629-081530.md`

作成してはいけないファイル:

- `latest.md`
- `codex-latest.md`
- `claude-latest.md`

# 必須内容

引き継ぎメモには、次の項目を含める。

1. リポジトリ名と現在ブランチ
2. 作業目的
3. 読んだファイル
4. 変更したファイル
5. 変更内容または調査結果の要約
6. 実行した検証コマンドと結果
7. 既知の問題、リスク、不確実な点
8. 次に推奨する作業
9. `git status --short --branch` の結果

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

## Files read

- `path/to/file`
- `path/to/file`

## Files changed

- `path/to/file`
- `path/to/file`

変更がない場合:

- 変更なし。

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
~~~

# 作成後の確認

作成後、最低限次を確認する。

```bash
git status --short --branch
ls -l ~/chatgpt-handoff/
```

引き継ぎメモ自体はリポジトリ外の `~/chatgpt-handoff/` に置くため、通常は作業中リポジトリの `git status` に出てこない。
