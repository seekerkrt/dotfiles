---
name: commit-prep
description: >-
  commit前にstaged・unstaged・untrackedを分類し、unrelated changeを除いた
  論理単位、stage候補path、検証状況、日本語commit messageを提案する。
---

# commit前整理

## 目的

working treeを変更せず、commitへ含める変更の論理単位、stage候補、検証状況、
commit message案を整理する。このSkill単体は準備と提案までを担当する。

## 開始時確認

repository rootで、可能な範囲で次を確認する。

~~~bash
git status --short --branch
git diff --name-status
git diff
git diff --cached --name-status
git diff --cached
git diff --check
~~~

staged変更がある場合は`git diff --cached --check`も確認する。untracked fileは
今回の候補か判断するために必要な範囲だけ読む。目的不明のfileや秘密情報らしき
fileは開かず、「内容未確認」として候補から外す。

read-only commandがAGYのpermissionまたはworkspace境界で拒否された場合は、
設定変更や境界回避をせず、取得できた状態と未確認項目を分ける。

## 基本ワークフロー

1. staged、unstaged、untrackedを分ける。
2. 今回の依頼に必要な変更と既存のunrelated changeを識別する。
3. 変更理由、依存関係、rollback単位からcommitの論理単位を決める。
4. commit単位ごとにstage候補pathを列挙する。
5. diff checkと実施済み検証を確認する。
6. repository固有規約と直近履歴に合わせてmessage案を作る。
7. stage、commit、pushの実施有無を明記する。

ユーザーがstageまたはcommitを明示していない限り、`git add`と`git commit`は
実行しない。依頼がある場合も、対象pathとstaged diffを直前に再確認する。

## 変更の分類

各pathを次のいずれかへ分類する。

- 今回のcommitに必要
- 同じ目的だが別commitが妥当
- unrelatedな既存変更
- generated artifactまたは検証副作用
- 内容未確認
- commit対象外のhandoffや一時file

同じfile内に今回の変更とunrelated changeが混在する場合は、file単位stageで安全に
分離できないことを明記する。明示依頼なしにinteractive stagingや手作業の差分分割を
行わない。

## commit粒度

次を基準に判断する。

- 1つの目的と説明でまとめられるか。
- 一方だけをrevertしても整合するか。
- code、test、docsが同じ契約変更を表すか。
- review時に意図を独立して判断できるか。
- unrelated cleanupが混ざっていないか。

file数だけで機械的に分割しない。同じ契約の実装、test、docsは同一commitが自然な
場合がある。

## stage候補

pathを明示し、除外理由も添える。

~~~text
commit 1:
- path/to/file-a
- path/to/file-b

除外:
- path/to/unrelated-file: 既存のunrelated change
~~~

実行が明示された場合は、対象を絞った`git add -- <path>...`を使う。
`git add .`や広いglobは、含まれるpathを確認せず使わない。

## 検証状況

検証結果は実行済みcommandと結び付け、次を分ける。

- pass
- fail
- warning
- partial
- environment blocked
- not run

実行していないbuild、test、lint、runtime確認は`not run`とし、理由を書く。
検証内容の判断には`verify` Skillを使う。

## commit message

repository固有規約と直近の`git log --oneline`を確認し、日本語件名を主案にする。
件名は何を変更したかが分かる短い形にする。

~~~text
docs(agy): 個人共通SkillをAGY向けに分離
~~~

背景、制約、非目標を残す価値がある場合だけ本文を付ける。必要なら英語要約を
第2段落として提案する。実行していないtest、未確認のIssue完了、未実装内容を
messageへ書かない。

## 失敗時

- `git diff --check`失敗は該当pathと内容を報告し、勝手に修正しない。
- staged内容が想定と違う場合はcommitせず、差分を報告する。
- stageやcommitがtimeoutまたは失敗した場合は、再実行前にread-onlyで状態を確認する。
- partial stageの可能性がある場合は、成功部分と未確認部分を分ける。

## 最終報告

~~~text
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

commit message案:
- ...

未確認:
- ...

Git操作:
- git add / commit / push の実施有無
~~~
