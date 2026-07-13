---
name: handoff
description: >-
  非自明な実装、調査、検証、debug、設計review、Issue・PR作業の終了時に、
  ChatGPTへ渡す日時付き日本語Markdown引き継ぎメモを作る。
---

# ChatGPT handoff

## 目的

次の会話で作業を正確に再開できるよう、repository状態、変更、検証、未確認、
次の一手を1つの日本語Markdownへ残す。長いlogは貼らず、判断に必要な根拠を要約する。

## 使用する場面

- 複数fileにまたがる変更
- 複数手順を要した調査や検証
- 設計判断やtrade-offを伴う作業
- Issue、PR、review、CIに関する作業
- debug、責務境界監査、実機・VM・emulator観測
- 作業が途中で止まり、別会話へ正確に引き継ぐ場合

単純なtypo、1行程度の自明な変更、単発の質問応答では通常使わない。

## 出力先とAGY workspace境界

出力先は`~/handoff/`とする。実行ごとに個別fileを作り、固定名を更新しない。

`~/handoff/`がactive workspace外なら、書き込み前にAGYの通常のpermission promptで
今回作るdirectoryまたはfileだけの承認を求める。

- workspaceへ追加するために`--add-dir`を使わない。
- permission設定やoutside-folder policyを変更しない。
- broadな`write_file(*)`やbypassを求めない。
- 承認されない場合はrepository内へ代替fileを作らず、`handoff not created`と理由を
  報告する。

directoryが存在せず、作成が承認された場合だけ`mkdir -p ~/handoff`を実行してよい。

## ファイル名

次の形式で、agent名は`agy`を使う。

~~~text
agy-<repo>[-issueNNまたはtask名]-<YYYYMMDD-HHMMSS>.md
~~~

例:

- `agy-dotfiles-20260714-091500.md`
- `agy-jadeos-issue24-20260714-091500.md`
- `agy-jadeos-usb-realhw-20260714-091500.md`

`latest.md`、`current.md`等の固定名は作らない。同名fileが既にあれば上書きせず、
新しいtimestampを採る。

## 基本ワークフロー

1. repository root、branch、HEAD、日時、agentを確認する。
2. 読んだfile、変更したfile、scope、non-goalを整理する。
3. 実施した作業と実施しなかった作業を分ける。
4. 実行した検証commandと結果、未実施理由を整理する。
5. known issue、risk、未確認、次の一手を整理する。
6. 一意なfile名を決め、必要ならworkspace外writeのapprovalを受ける。
7. 日本語Markdownを作成し、必須項目を確認する。
8. `git status --short --branch`を再確認する。

## 必須内容

1. repository名、root、branch
2. HEADまたはcommit状態
3. 作業日時とagent
4. 作業目的、scope、non-scope
5. 読んだfile
6. 変更したfile
7. 実施した作業と実施しなかった作業
8. 変更内容または調査結果
9. 検証commandと結果
10. known issue、risk、不確実な点
11. 次に推奨する作業
12. `git status --short --branch`の結果
13. stage、commit、push、GitHub writeの実施有無

## 検証結果

結果はcommandごとに次で分類する。

- pass
- fail
- warning
- partial
- environment blocked
- not run

実行していない検証は`not run`とし、理由を書く。build成功をtestやruntime成功へ
読み替えない。実機、QEMU、KVM、TCG、VirtualBox、container等は区別し、外部観測は
観測事実と解釈を分ける。

## 推奨テンプレート

~~~markdown
# ChatGPT handoff: <repo> / <task>

## Repository

- Repo:
- Root:
- Branch:
- Commit:
- Date:
- Agent: AGY

## Task

<目的、scope、non-scope>

## Structure before

<構造変更がある場合だけ>

## Structure after

<構造変更がある場合だけ>

## Files read

- <path>

## Files changed

- <path>

## Work completed

- <実施した作業>

## Work not performed

- <実施しなかった作業と理由>

## Summary

<変更内容または調査結果>

## Validation

実行command:

    <command>

結果:

- pass / fail / warning / partial / environment blocked / not run
- <重要な観測>

## Known issues / risks

- <riskまたは未確認>

## Next recommended action

1. <次の一手>

## Git status

    <git status --short --branch>

## Git and GitHub operations

- git add: not run / 実施
- commit: not run / 実施
- push: not run / 実施
- GitHub write: not run / 実施
~~~

## PRがある場合

作業branchをpushし、十分な情報を持つdraft PRを作成済みなら、PR bodyをhandoffとして
扱ってよい。ただし次の場合は`~/handoff/`にも作る。

- PRを作成していない、またはpushしていない。
- 変更が未commitまたは一部だけcommit済み。
- 調査途中、runtime観測、長期debugの文脈がPR bodyに収まらない。
- PR作成に失敗し、次の会話へ失敗状態を渡す必要がある。

PR作成自体はユーザーの明示依頼なしに行わない。

## 作成後の確認

- file名が一意でtimestampを含む。
- 必須項目が揃い、実施済みと`not run`が分かれている。
- handoffをstage、commitしていない。
- working treeのscope外変更が保持されている。
- commit、push、GitHub writeをしていない場合、その事実を書いている。

作成先、確認結果、未確認、未実施のGit操作を最終報告へ含める。
