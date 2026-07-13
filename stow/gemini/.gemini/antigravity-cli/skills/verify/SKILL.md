---
name: verify
description: >-
  非自明な変更後にdiffと既存契約を確認し、repository固有の最小build・testから
  runtime検証まで段階的に実行して、結果と未実施項目を分類する。
---

# 検証設計・結果整理

## 目的

変更scopeに見合う検証を小さく始め、必要な範囲まで段階的に広げる。実行した
commandと観測結果だけを根拠にし、静的確認、build、test、runtimeを混同しない。

## 開始時確認

repository rootで次を確認する。

~~~bash
git status --short --branch
git diff --name-status
git diff
git diff --cached --name-status
git diff --cached
~~~

確認する内容:

- branchとworking tree
- staged、unstaged、untracked
- 今回の対象diff
- unrelatedな既存変更
- 適用されるrepository指示とdocs
- 既存のbuild、test、lint、runtime手順

untracked fileは必要な範囲だけ確認し、秘密情報を探索しない。

## 基本ワークフロー

1. 変更scope、期待contract、影響するconsumerを整理する。
2. diff、構文、参照、設定、docs整合を静的に確認する。
3. `git diff --check`を実行する。
4. repositoryが定める最小のvalidator、lint、build、testを実行する。
5. 直接影響を覆えない場合だけbroader testへ広げる。
6. runtime固有挙動がある場合は、対象環境を特定して確認する。
7. command、exit status、期待条件、重要なwarningを記録する。
8. 未実施項目、理由、残るrisk、次の検証候補を記録する。

staged diffがある場合は必要に応じて`git diff --cached --check`も実行する。
exit code 0だけで期待条件を満たしたと判断せず、必要なoutputやartifactも確認する。

## repository固有commandの探し方

次の順で確認する。

1. 対象scopeに適用されるrepository指示
2. README、CONTRIBUTING、docs
3. Makefile、task runner、package script、test script
4. CI workflowと既存automation
5. 近傍の履歴や既存handoff

command、target、dependency、実行directoryを確認してから実行する。見つからない
場合は一般的なcommandを推測で作らず、「標準手順は未確認」とする。

## 検証範囲の広げ方

次の場合にbroader testを検討する。

- 共通library、public API、build設定、serialization形式を変更した。
- 複数componentやtargetから参照されるcontractを変更した。
- 最小testが間接影響を覆わない。
- repository契約やCIがbroader suiteを要求する。
- regression riskに対して追加検証の費用が妥当である。

環境や時間の制約で広げない場合は、`not run`の理由と残るriskを書く。

## AGY permission・workspace境界

検証commandやruntime環境へのaccessが拒否された場合は、次を守る。

- permission拒否、workspace外、dependency不足、network、hardware不足を区別する。
- 対象と必要性が明確な通常のapprovalだけを求める。
- workspace追加、permission設定変更、bypassで検証を成立させない。
- 承認されない場合は`environment blocked`とし、test failureへ読み替えない。
- 検証目的でscope外fileやglobal環境を変更しない。

## runtime検証

runtimeが関係する場合は環境を具体的に記録する。

- host process、container
- simulator、emulator
- QEMUのKVMまたはTCG
- VirtualBox等のhypervisor
- 実機と機種・接続条件

一つの環境での成功を別環境や実機の成功とみなさない。log、画面、動画、
device counter等は観測事実と解釈を分ける。

## 結果分類

- pass: commandが成功し、期待条件も確認できた。
- fail: commandまたは期待条件が失敗した。
- warning: 成功したが、警告や将来riskが残る。
- partial: 一部だけ確認でき、検証全体は完了していない。
- not run: 未実施。理由を必ず付ける。
- environment blocked: permission、dependency、hardware等で実行できない。
- flaky / inconclusive: 再現が安定せず、結論を確定できない。

実行していない検証は必ず`not run`とする。build成功をtest成功、test成功を
runtime成功として扱わない。

## 失敗時

- 最初の根本原因候補と後続の連鎖errorを分ける。
- command、実行directory、exit status、重要なerrorを記録する。
- environment failureを変更内容のfailureと断定しない。
- flakyな場合は試行回数と結果を記録する。
- 検証だけの依頼では、失敗を直すためのfile編集を行わない。
- 実装依頼に修正が含まれる場合も、scope内の最小修正後に該当検証を再実行する。

## 最終報告

~~~text
検証scope:
- ...

実行command:
- <command>: pass / fail / warning / partial

not run:
- <check>: <reason>

environment blocked:
- ...

残るrisk:
- ...

次の検証候補:
- ...
~~~

長いlogを貼らず、判断に必要なerror、warning、観測値を抜き出す。
