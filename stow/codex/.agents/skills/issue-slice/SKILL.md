---
name: issue-slice
description: GitHub Issueまたは明示されたPR単位の実装scopeを、repository固有契約・decision authority・既存構造へ接続して小さな変更として実装するときに使用し、scope / non-scopeを固定し、必要な既存Skillを適用して検証し、commit前の状態で結果を報告する。
---

# Issue slice implementation

## 目的と停止点

GitHub Issueまたは明示されたPRのうち、現在のPRとして成立する1つの実装sliceを、repositoryの既存契約へ接続して完了させる。Issue全体と現在のPR単位を区別し、最小実装、focused verification、必要なbroader verificationまで進め、commit前で停止する。

本Skillは既存Skillの本文を置き換えない。各段階で必要になる直前に該当Skillを全文読み、その固有契約へroutingする。

## Authorityとpreflight

編集前に次を確認する。

1. repository root
2. 対象scopeへ適用される`AGENTS.md`
3. branch、HEAD、staged / unstaged / untrackedを含むworking tree
4. Issue本文とacceptance criteria。PRだけが明示された場合は、そのPRの目的と成立条件
5. 採用済みdecision、設計文書、maintainer判断等のdecision authority
6. dependency Issueとparent roadmap
7. 関連するmerged PRと現在の実装状態
8. repositoryの正式docs
9. build / test / CIの正式な入口
10. 既存consumerと近傍test

Issue、PR、decision、関連履歴のGitHub確認が必要なら、最初に`~/.agents/skills/github/SKILL.md`を全文読み、read-onlyとmutationの境界に従う。存在を確認していないpath、command、Issue、PR、branch、decisionを推測で補わない。

Issueやdecision authorityを参照できない場合も、確認できた情報だけで安全に固定できるsliceがあるか判断する。確認済みscopeと未確認部分を分け、成立条件が確定しない場合は実装を開始せずblockerとして報告する。

## Scope分類

編集前に次の4分類を作る。

```text
Required scope:
- 今回のPR成立に必要

Accepted supporting changes:
- dependency、test、build metadata、license等
- required scopeを成立させるために直接必要

Explicit non-scope:
- 今回は変更しない

Follow-up / release audit:
- 局所的に後付け可能
- 特殊条件
- defense-in-depth
- 広い設計評価
```

実装中に得たfindingも必ずこの4分類へ入れる。次の理由だけでscopeを自動拡張しない。

- 将来便利そう
- 一般化できそう
- security関連である
- 近傍コードも整理できる
- 新しい共通基盤を作れそう

現在のPR成立に必須でない内容は、follow-upまたはrelease auditへ送る。scope変更がacceptance criteriaやdecision authorityを変える場合は、実装を止めて確認する。

## Workflowと既存Skillへのrouting

1. authorityとpreflightを確認する。
2. required、accepted supporting changes、explicit non-scope、follow-up / release auditを固定する。
3. 既存構造、public contract、consumer、tests、build surfaceを調査する。
4. required scopeを成立させる最小変更を実装する。
5. 対象diffを静的確認し、focused verificationを実行する。
6. 影響範囲とrepository契約が要求する場合だけbroader verificationへ広げる。
7. commit前のworking treeとIssue残scopeを確認して報告する。

段階ごとのroutingは次とする。

- 実装前の独立監査、read-only調査、Issue化前調査が依頼された場合は、編集せず`~/.agents/skills/audit/SKILL.md`を全文読んで`audit`へroutingする。調査だけの依頼を実装へ拡張しない。
- C++、C++から利用するC互換header、共有ABI境界を生成・編集・reviewする直前に、`~/.agents/skills/cpp-conventions/SKILL.md`を全文読む。repositoryの`docs/CODING_CONVENTIONS.md`があれば併読し、実際のcompiler設定も確認する。
- 実装後の検証へ入る直前に`~/.agents/skills/verify/SKILL.md`を全文読み、結果分類と出力契約を含めて適用する。
- commit準備を求められた場合だけ`~/.agents/skills/commit-prep/SKILL.md`を全文読み、`commit-prep`へroutingする。
- GitHubの調査・操作は`github`へroutingする。外部mutationは明示された対象と操作だけに限定する。
- 通常handoffまたは引き継ぎメモを明示的に求められた場合だけ`~/.agents/skills/handoff/SKILL.md`を全文読み、`handoff`へroutingする。raw log保存だけでは起動しない。

## 実装契約

- repository内の既存構造、owner、命名、error処理、test patternを優先する。
- unrelated refactor、広いrename、形式だけのchurnを混ぜない。
- public contract、typed model、owner、lifetime、failure orderingを確認する。
- testを実装と同じcontract変更として扱い、正常系だけでなく今回のfailure boundaryを覆う。
- dependency追加時は、build、packaging、license、install layout等のrepository既存契約を確認する。
- 作業中のunrelated changeを変更、stage、退避、削除しない。

## Verification

次の候補から、repository必須check、変更内容・影響範囲・risk、ユーザー要求に対応する検証を選ぶ。
選択した検証と必要なartifact保存が完了した時点を基本的な終了点とする。
成功後の追加・反復検証は、新しい変更、新たに発生したfailure、現在未解決のfailure、
修正後の確認に必要なfocused rerun、未解決のrisk / ambiguity、
repository contractまたはユーザーによる追加検証要求がある場合に行う。
必要なfocused rerunでfailureの解消を確認した後に、追加変更・未解決failure・未解決risk / ambiguity、
repository contract・ユーザーの追加要求がなく、選択した検証と必要なartifact保存が完了していれば終了する。
過去のfailure記録だけを追加・反復の理由にしない。終了判定とrunごとの結果は分け、
過去にfailしたrunの結果は`fail`のまま保持する。
必要・要求された未実施検証は理由付きの`not run`とし、明らかな対象外項目を毎回列挙しない。

```text
1. 対象diffの静的確認
2. git diff --check
3. focused test / validator
4. clean build
5. broader test
6. release-check
7. 必要な場合だけClang、sanitizer、static analysis、runtime
```

repository固有commandを推測しない。実行していない検証を成功扱いせず、build、test、runtime、VM、実機を相互に読み替えない。

## 長い出力と作業artifact

長い、または長くなる可能性が高いfull test、release-check、compiler full output、sanitizer、static analysis、large search、full working-tree / PR diff、audit raw output、package build、runtime / VM等の出力は次へ保存する。

```text
~/handoff/<repo>/<scope>/
```

`<scope>`は次の順で決める。

```text
Issueあり: issue-<number>
PRのみ: pr-<number>
特定テーマ: topic-<short-kebab-slug>
その他: general
```

filenameは次とする。

```text
<YYYYMMDD-HHMMSS>-codex-<short-purpose>.<log|txt|diff>
```

- `latest.*`や固定名を作らず、既存artifactをrename、移動、削除しない。
- stdout / stderrとexit statusを失わない形で保存する。
- failure時は保存pathとroot causeに関係する行だけを報告する。
- success時はpass、保存path、重要な要点だけを報告する。raw logをterminal会話やfinal responseへ貼らない。
- raw log保存は通常handoff生成とは別物であり、`handoff` Skillを自動起動しない。
- raw logをrepositoryへ追加、stage、commitしない。

## Gitと外部mutationの停止境界

明示依頼なしに次を行わない。

```text
git add
git commit
git push
branch / tag mutation
PR作成・更新
merge
Issue更新・close
release
GitLab mirror更新
handoff archive
```

依頼があっても、対象、scope、現在状態、影響を確認し、各Skillとagentのpermission境界に従う。本Skillの通常終了点はunstagedまたはユーザーが既にstageした状態を保持したcommit前である。

## 最終報告

最低限、次を簡潔に報告する。

```text
Scope:
- required:
- accepted supporting changes:
- non-scope:

Changed:
- <file / contract>

Validation:
- <command>: pass / fail / partial / environment blocked
- long output: <path>

Findings:
- blocker:
- follow-up:
- release audit:

Not run:
- <check>: <reason>

Git state:
- staged / unstaged / untracked:
- commit / push / PR:

Next:
- <1つの具体的な次の一手>
```

現在のPR単位の完了とIssue全体の完了を区別する。作業sliceが完了してもIssueに残scopeがあれば、Issue completedと報告しない。
