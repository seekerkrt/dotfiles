---
name: verify
description: 非自明な変更後に、working treeと対象diffを確認し、repository固有の最小build・testから必要なruntime検証まで段階的に実行して、成功・失敗・warning・未実施・環境制約を分けて報告する。
---

# 目的

変更scopeに見合う検証を小さく始め、必要な範囲まで段階的に広げる。

実行したcommandと観測結果だけを根拠にし、build、test、emulator、VM、実機の結果を混同せず、残るリスクを明示する。

# 使用条件

次の作業で使用する。

- 複数fileまたは非自明なコード変更後の検証
- bug fix、refactor、設定変更、docsと実装の同期確認
- build、test、lint、static analysisの実行と結果整理
- QEMU、KVM、TCG、VirtualBox、実機等のruntime確認
- ユーザーが検証、test、動作確認を依頼した作業

単純なtypoや1行変更でも、影響が読みにくい場合やrepository契約で検証が必要な場合は使用する。

# 最重要ルール

- 実行していない検証を成功扱いしない。
- repository固有commandを推測しない。
- build成功だけでtest成功やruntime成功と断定しない。
- warning、failure、flaky、環境制約、sandbox制約を分ける。
- QEMU、KVM、TCG、VirtualBox、実機の結果を混同しない。
- 検証のためだけにunrelatedなfileや生成物を更新しない。
- 明示依頼なしに修正、stage、commit、pushを行わない。
- 既存の未コミット変更をユーザーの作業として尊重する。

# 開始時確認

最初に可能な範囲で次を確認する。

```bash
git status --short --branch
git diff
git diff --cached
```

確認する内容:

- repositoryとbranch
- staged、unstaged、untrackedの状態
- 今回の対象diff
- unrelated change
- repository内のAGENTS.md、README、Makefile、scripts、CI設定
- 既存のtest、lint、build、runtime手順

untracked fileの内容は必要な範囲だけ確認し、秘密情報を探索しない。

# 基本ワークフロー

1. 変更scopeと影響する契約を把握する。
2. diff、構文、参照、設定、docs整合等を静的に確認する。
3. `git diff --check` を実行する。staged diffがある場合は必要に応じて `git diff --cached --check` も実行する。
4. repositoryが定める最小のbuild、test、lint、validatorを実行する。
5. 変更の影響と最小検証の結果から、broader testが必要か判断する。
6. runtime固有の挙動がある場合は、利用可能な環境と依頼scopeを確認してruntime検証を行う。
7. 実行commandと結果をpass、fail、warning、partialに分ける。
8. 未実施の検証と理由、残るリスク、次の検証候補を記録する。

# repository固有commandの探し方

次の優先順で確認する。

1. 対象scopeに適用されるAGENTS.mdや開発者向け指示
2. README、CONTRIBUTING、docs
3. Makefile、task runner、package script、test script
4. CI workflowや既存automation
5. 近傍の履歴や既存handoff

command名、target、必要dependency、実行directoryを確認してから実行する。見つからない場合は、一般的なcommandを推測で作らず「標準手順は未確認」とする。

# 検証範囲の広げ方

最初は変更に直接対応する最小検証を選ぶ。次の場合にbroader testを検討する。

- 共通library、public API、build設定、serialization形式を変更した。
- 複数componentや複数targetから参照されるsymbolを変更した。
- 最小testが間接影響を覆わない。
- repository契約やCIがbroader suiteを要求する。
- regression riskが高く、追加検証の費用が妥当である。

時間や環境制約で広げない場合は、未実施理由と残るリスクを報告する。

# runtime検証

runtimeが関係する場合、環境を具体的に記録する。

- QEMU acceleratorのKVMとTCG
- VirtualBox等の別hypervisor
- simulatorまたはemulator
- containerまたはhost実行
- 実機と機種・接続条件

一つの環境で成功しても、別環境や実機での成功とはみなさない。実機未確認なら「実機未確認」と明記する。

ログ、画面、動画、device counter等の外部観測は、観測事実と解釈を分ける。

# 結果の分類

- pass: commandが成功し、検証対象の期待条件を確認できた。
- fail: commandまたは期待条件が失敗した。
- warning: 成功したが、警告や将来リスクが残る。
- partial: 一部だけ確認でき、検証全体は完了していない。
- not run: 未実施。理由を必ず付ける。
- environment blocked: dependency、権限、sandbox、hardware等により実行できない。
- flaky / inconclusive: 再現が安定せず、結論を確定できない。

exit code 0だけで期待条件を満たしたと判断せず、必要な出力やartifactも確認する。

# 禁止事項

- 存在を確認していないbuild/test commandの実行
- test未実施をpassと書くこと
- build成功をruntime成功と書くこと
- warningを隠して全面成功と報告すること
- environment failureをコードfailureと断定すること
- 検証目的のunrelated cleanupや生成物更新
- ユーザーの変更のrestore、reset、stash、clean
- 明示依頼のない修正、stage、commit、push
- 実機、VM、emulator結果の相互読み替え

# 失敗時・未確認時の扱い

- 最初の根本原因候補と、その後の連鎖エラーを分ける。
- command、実行directory、exit code、重要なerrorを記録する。
- sandbox、権限、dependency不足、network、hardware不足をコード不具合と分ける。
- flakyな場合は試行回数と結果を記録し、安定成功と断定しない。
- 実行できなかった検証は、理由を付けて未実施またはenvironment blockedとする。
- 失敗を直すためのコード編集は、ユーザーの依頼scopeに修正が含まれる場合だけ行う。検証のみの依頼では編集しない。

# 最終報告

最低限、次を報告する。

```text
検証scope:
- ...

実行command:
- <command>: pass / fail / warning / partial

未実施:
- <check>: <reason>

environment制約:
- ...

残るリスク:
- ...

次の検証候補:
- ...
```

長いlogをそのまま貼らず、判断に必要なerror、warning、観測値を抜き出す。実行していない項目は省略せず明記する。
