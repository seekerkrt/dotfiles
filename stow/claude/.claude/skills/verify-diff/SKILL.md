---
name: verify-diff
description: Claude Codeで非自明な変更後、docsと実装の同期確認、またはbuild / test / lint / runtime検証を行うverify-diff Skillとして使用し、対象diffとrepository固有commandを段階的に確認してpass、fail、warning、partial、未実施、環境制約を区別して報告する。
---

# Verification

## 固有契約

- 実行したcommandと観測した結果だけを根拠にする。
- build、test、lint、runtime、QEMU、KVM、TCG、VirtualBox、実機を相互に読み替えない。
- exit code 0だけで期待条件を満たしたと判断せず、必要な出力やartifactも確認する。
- repository固有commandを名前から推測しない。
- 検証だけの依頼では、失敗を直すための編集やstage / commitへ進まない。
- 検証副作用や生成物を今回の変更と区別する。

## Preflight

最初に確認する。

```bash
git status --short --branch
git diff
git diff --cached
```

対象diff、staged / unstaged / untracked、既存のunrelated changeを分ける。対象変更がcommit済み、branch差分、またはPR差分である場合は、指定されたbase / head、commit range、PRのchanged filesを対象diffとして確認する。working treeの`git diff`が空であることを、変更なしの根拠にしない。

次の順で正規の検証入口を探す。

1. 適用される`CLAUDE.md`
2. README、CONTRIBUTING、developer docs
3. Makefile、task runner、package script、test script
4. CI workflowや既存automation
5. 必要な場合だけ近傍履歴やhandoff

command、実行directory、dependency、targetの意味を確認する。見つからなければ「標準手順は未確認」とする。

## Workflow

1. 変更scopeと影響する契約を把握する。
2. diff、構文、参照、設定、docs、同期関係を静的に確認する。
3. 対象変更に対応する`git diff --check`を実行する。working treeなら通常diff、staged変更なら`--cached`、commit済み変更なら明示されたbase / headまたはcommit rangeを使う。
4. repositoryが定める最小のvalidator、build、test、lintを実行する。実装途中はfocused validationを優先し、変更のたびにfull suiteを反復しない。
5. public API、共通library、build設定、serialization等へ影響する場合だけ、必要なbroader suiteへ広げる。full testはslice完成時またはcommit-prep前を基本とし、失敗修正後はまず失敗targetをfocused rerunしてから、最後にfull suiteを1回実行する。
6. release前または明示された最終監査では、repository契約に従ってclean build、full test、release-checkを実行する。
7. runtime固有の変更なら、利用可能な環境と依頼scopeを確認してruntime検証する。
8. 結果、未実施理由、環境制約、残るriskを記録する。
9. 最後に対象diffと`git status --short --branch`を再確認する。

docs-only変更では、repositoryの契約が要求しないbuildやruntime検証を形式的に実行しない。参照path、同期、front matter、Markdown構造等、変更内容に直接対応する静的検証を選ぶ。

## GNU Make

GNU Makeがrepositoryの正式な検証入口であることを確認でき、repositoryがparallel executionを禁止しておらず、targetの依存関係とtest fixtureがparallel-safeであり、既存の直列化／jobserver契約に反しない場合は、bounded parallelismを既定とする。

既定形式は次とし、repositoryが提供するMakeの検証入口、たとえば`make`、`make test`、`make release-check`等へ適用する。

```bash
env -u MAKEFLAGS -u MFLAGS make -j8 --output-sync=target <target>
```

- repository内の既存`-j1`、`.NOTPARALLEL`、局所的な直列化、jobserver契約は上書きしない。適用されるjobserver契約がある場合は、その契約に従い、既定形式の環境変数解除を機械的に適用しない。
- `clean`は必ず単独のmake invocationで実行し、build、test、release-checkと同じmake invocationへ混ぜない。
- 同じworktreeで独立したtop-level make processを同時実行しない。
- parallel safetyが不明、禁止されている、または共有fixture／固定outputの競合が疑われる場合は直列実行し、その理由を報告する。
- parallel runが失敗しraceが疑われる場合は、該当targetを直列でも確認する。直列PASSをparallel failureの成功扱いにせず、parallelと直列の両方の結果を報告する。

## Runtime

runtime検証では環境を具体的に記録する。

- host / container
- simulator / emulator
- QEMUのKVM / TCG
- VirtualBox等の別hypervisor
- 実機と機種・接続条件

ログ、画面、counter、動画等は、観測事実と解釈を分ける。一つの環境での成功を別環境の成功としない。

## Result classification

- `pass`: commandが成功し、対象の期待条件を確認できた。
- `fail`: commandまたは期待条件が失敗した。
- `warning`: 成功したが警告や将来riskが残る。
- `partial`: 一部だけ確認でき、検証全体は完了していない。
- `not run`: 未実施。理由を付ける。
- `environment blocked`: dependency、権限、sandbox、network、hardware等で実行できない。
- `flaky / inconclusive`: 再現が安定せず結論を確定できない。

## 長い出力と作業artifact

長い、または長くなる可能性が高いfull test、clean build、release-check、compiler full output、sanitizer、static analysis、large search、full diff、package build、runtime / VM等の出力は、repository外の次へ保存する。

```text
~/handoff/<repo>/<scope>/
```

`<scope>`は、Issueがあれば`issue-<number>`、PRだけなら`pr-<number>`、特定テーマなら`topic-<short-kebab-slug>`、それ以外は`general`とする。filenameは次とし、`latest.*`等の固定名を作らず、既存artifactをrename、移動、削除しない。

```text
<YYYYMMDD-HHMMSS>-claude-<short-purpose>.<log|txt|diff>
```

次は、repositoryの正式な検証commandとして`make test`を確認できた場合の実行例である。`make test`を全repositoryへ固定するものではない。実際の利用時は、repository固有の指示、docs、build設定で確認した正式な検証commandへ置き換える。

```bash
mkdir -p ~/handoff/<repo>/<scope>
timestamp=$(date +%Y%m%d-%H%M%S)
log=~/handoff/<repo>/<scope>/"${timestamp}-claude-<purpose>.log"

# 例: GNU Make repositoryでparallel safetyを確認済み、正式な検証targetが `test` の場合
if env -u MAKEFLAGS -u MFLAGS make -j8 --output-sync=target test >"$log" 2>&1; then
    echo "PASS: $log"
else
    status=$?
    echo "FAIL ($status): $log"
    tail -n 120 "$log"
    exit "$status"
fi
```

- failure時だけroot cause判断に必要な箇所を表示し、exit statusとlog pathを報告する。
- success時はpass、log path、期待条件の要点だけを報告する。raw logをterminal会話やfinal responseへ貼らない。
- raw log保存を通常handoff生成と混同せず、`handoff` Skillを自動起動しない。
- raw logをrepositoryへ追加、stage、commitしない。

## 失敗時

- 最初のroot cause候補と後続の連鎖errorを分ける。
- command、directory、exit code、判断に必要なerror / warningを記録する。
- environment failureをcode failureと断定しない。
- timeoutや部分成功の後は、再実行前に現在状態を確認する。
- 検証生成物が残った場合は、そのpathと扱いを報告し、勝手に既存変更を消さない。

## 出力

```text
検証scope:
- ...

実行command:
- <command>: pass / fail / warning / partial

未実施:
- <check>: <reason>

環境制約:
- ...

残るrisk:
- ...

次の検証候補:
- ...
```

長い出力は上記の保存契約に従い、未実施項目を成功項目の陰に隠さない。
