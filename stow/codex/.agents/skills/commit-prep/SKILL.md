---
name: commit-prep
description: commit前にstaged・unstaged・untrackedを分類し、unrelated changeを除いた論理単位、stage候補path、検証状況、日本語commit件名と必要な本文・英語要約を提案する。明示依頼がない限りstageやcommitは実行しない。
---

# 目的

現在のworking treeを壊さずに、commitへ含める変更の論理単位とstage候補を整理し、根拠のあるcommitメッセージ案を作る。

このSkill単体では準備と提案までを行い、ユーザーが明示的に依頼した場合だけstageまたはcommitを実行する。

# 使用条件

次の作業で使用する。

- commit前の差分整理
- stage対象pathの選定
- 複数変更をcommit単位へ分ける相談
- commit件名、本文、英語要約の作成
- staged内容と検証結果の最終確認
- ユーザーがcommitまたはcommit準備を依頼した作業

単なるdiffレビューやread-only監査には `audit`、変更後の検証には `verify` を優先する。

# 最重要ルール

- 明示依頼なしに `git add` や `git commit` を実行しない。
- `git add .` を無条件に提案または実行しない。
- staged、unstaged、untrackedを分ける。
- unrelated changeをstage候補へ混ぜない。
- ユーザーの変更をrestore、reset、stash、cleanしない。
- 実行していないtestをcommit本文へ書かない。
- commit実行直前にstage対象とstaged diffを再確認する。
- repository固有のcommit規約があれば、個人共通方針より優先する。

# 開始時確認

最初に次を確認する。

```bash
git status --short --branch
git diff
git diff --cached
git diff --check
```

staged変更がある場合は必要に応じて次も確認する。

```bash
git diff --cached --check
```

untracked fileは、対象候補か判断するために必要な範囲だけ内容を確認する。秘密情報やcredentialを探索しない。

# 基本ワークフロー

1. staged、unstaged、untrackedを分ける。
2. 今回の依頼に関係する変更とunrelated changeを識別する。
3. 変更理由、依存関係、rollback単位からcommitの論理単位を判断する。
4. commitごとにstage候補pathを明示する。
5. `git diff --check` と、実施済みのbuild/test結果を確認する。
6. repositoryの既存履歴や規約に合わせて日本語commit件名を提案する。
7. 必要な場合だけ本文と英語要約を提案する。
8. ユーザーが実行を依頼した場合だけ、対象pathを絞ってstageする。
9. commit実行直前に `git status --short --branch` と `git diff --cached` を再確認する。
10. ユーザーがcommitまで明示した場合だけcommitし、直後にread-onlyで結果を確認する。

# 変更の分類

各pathを次のいずれかへ分類する。

- 今回のcommitに必要
- 同じ目的だが別commitが妥当
- unrelatedな既存変更
- generated artifactまたは検証副作用
- 内容未確認
- commit対象外のhandoffや一時file

同じfile内に今回の変更とunrelated changeが混在する場合は、file単位stageで安全に分けられないことを明記する。明示依頼なしにinteractive stagingや手作業の差分分割を行わない。

# commit粒度

次を基準に論理単位を判断する。

- 1つの目的と説明でまとめられるか
- 一方だけをrevertしても整合するか
- code、test、docsが同じ契約変更を表すか
- review時に意図を独立して判断できるか
- unrelated cleanupが混ざっていないか

file数だけで機械的に分割しない。小さくても同じ契約のcodeとtestは同一commitが自然な場合がある。

# stage候補

stage候補はpathを明示して提案する。

```text
commit 1:
- path/to/file-a
- path/to/file-b

除外:
- path/to/unrelated-file: 既存のunrelated change
```

実行が依頼された場合も、可能な限りpathを絞った `git add -- <path>...` を使う。globやrepository全体を対象にする前に、含まれるpathを確認する。

# commitメッセージ

repository固有規約と直近履歴を確認し、日本語件名を主案にする。

件名は「何をしたか」が分かる短い形にし、必要に応じてtypeやscopeを付ける。

```text
docs: 個人共通AGENTS.mdから場面別手順を分離
```

背景、制約、検証、非目標を残す価値がある場合は本文を提案する。必要なら第2段落に英語要約を付ける。

```bash
git commit -m "<日本語件名>" -m "<英語要約>"
```

実行していないtest、未確認のIssue完了、未実装の変更をメッセージへ書かない。

# 禁止事項

- 明示依頼のない `git add`、`git commit`、push
- `git add .` の無条件な使用
- unrelated changeのstage
- ユーザー変更のrestore、reset、stash、clean
- stage対象確認前のcommit
- `git diff --check` やtest失敗の隠蔽
- 未実施testを実施済みとするcommit本文
- repository規約を無視した件名の押し付け
- handoff fileのstageまたはcommit

# 失敗時・未確認時の扱い

- pathの目的が不明なら「内容未確認」とし、stage候補から外す。
- `git diff --check` が失敗した場合は該当pathと内容を報告し、勝手に修正しない。
- test結果が不明なら「検証結果未確認」とし、passと書かない。
- staged内容が想定と違う場合はcommitせず、差分を報告する。
- stageやcommitのcommandがtimeoutまたは失敗した場合は、再実行前にread-onlyで現在状態を確認する。
- partial stageや部分成功の可能性がある場合は、成功部分と未確認部分を分ける。

# 最終報告

準備のみの場合は次を報告する。

```text
現状:
- branch
- staged / unstaged / untracked

推奨commit単位:
- ...

stage候補:
- ...

除外する変更:
- ...

検証状況:
- ...

commitメッセージ案:
- ...

未確認:
- ...
```

stageまたはcommitを明示依頼に基づいて実行した場合は、実行command、対象path、commit SHA、直後の `git status --short --branch` を追加する。pushは別の明示依頼がない限り行わない。
