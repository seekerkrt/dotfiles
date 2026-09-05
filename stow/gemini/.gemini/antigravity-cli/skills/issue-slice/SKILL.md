---
name: issue-slice
description: GitHub Issueまたは明示されたPR単位の実装scopeを、repository固有契約・decision authority・既存構造へ接続して小さな変更として実装するときに使用し、scope / non-scopeを固定し、必要な既存Skillを適用して検証し、commit前の状態で結果を報告する。
---

# Issue slice implementation

## 目的と停止点

GitHub Issueまたは明示されたPRのうち、現在のPRとして成立する1つの実装sliceを、repositoryの既存契約へ接続して完了させる。
Issue全体と現在のPR単位を区別し、最小実装と必要なverificationの完了を確認して、commit前で停止する。

本Skillは既存Skillの契約を置き換えず、必要な成果物に応じてroutingする。
Skill本文・referenceの読取りは共通指示に従い、確認済みで不変の内容を機械的に再読しない。

## Authorityとpreflight

編集前に次を確認する。

1. repository root
2. 対象scopeへ適用される`GEMINI.md`
3. branch、HEAD、staged / unstaged / untrackedを含むworking tree
4. Issue本文とacceptance criteria。PRだけが明示された場合は、そのPRの目的と成立条件
5. 採用済みdecision、設計文書、maintainer判断等のdecision authority
6. dependency Issueとparent roadmap
7. 関連するmerged PRと現在の実装状態
8. repositoryの正式docs
9. build / test / CIの正式な入口
10. 既存consumerと近傍test

Issue、PR、decision、関連履歴のGitHub確認が必要なら、
`~/.gemini/antigravity-cli/skills/github/SKILL.md`の契約に従う。
存在を確認していないpath、command、Issue、PR、branch、decisionを推測で補わない。

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
5. acceptance criteria、impact / risk、repository・ユーザー要求を`verify`へ渡し、
   必要な検証を行う。
6. その結果・未完了事項・必要なartifactを確認し、sliceの成立条件を満たすか判断する。
7. commit前のworking treeとIssue残scopeを確認して報告する。

段階ごとのroutingは次とする。

- 実装前の独立監査、read-only調査、Issue化前調査が依頼された場合は、
  `~/.gemini/antigravity-cli/skills/audit/SKILL.md`を適用する。
  調査だけの依頼を編集や実装へ拡張しない。
- C++、C++から利用するC互換header、共有ABI境界の生成・編集・reviewには
  `~/.gemini/antigravity-cli/skills/cpp-conventions/SKILL.md`を適用する。
  repositoryの`docs/CODING_CONVENTIONS.md`があれば併読し、実際のcompiler設定も確認する。
- 実装後の検証には`~/.gemini/antigravity-cli/skills/verify/SKILL.md`を適用する。
- commit準備を求められた場合だけ
  `~/.gemini/antigravity-cli/skills/commit-prep/SKILL.md`を適用する。
- GitHubの調査・操作は`github`へroutingする。外部mutationは明示された対象と操作だけに限定する。
- 通常handoffまたは引き継ぎメモを明示的に求められた場合だけ
  `~/.gemini/antigravity-cli/skills/handoff/SKILL.md`を適用する。
  raw log保存だけでは起動しない。

## 実装契約

- repository内の既存構造、owner、命名、error処理、test patternを優先する。
- unrelated refactor、広いrename、形式だけのchurnを混ぜない。
- public contract、typed model、owner、lifetime、failure orderingを確認する。
- testを実装と同じcontract変更として扱い、正常系だけでなく今回のfailure boundaryを覆う。
- dependency追加時は、build、packaging、license、install layout等のrepository既存契約を確認する。
- 作業中のunrelated changeを変更、stage、退避、削除しない。

## Verification

詳細workflowのownerは`~/.gemini/antigravity-cli/skills/verify/SKILL.md`とする。
本Skillはdecision authorityから定めたacceptance criteria、
scope / non-scope、impact / risk、repository・ユーザー要求を検証の入力として保持する。
検証選択・実行・結果分類・環境・artifact保存・完了条件は`verify`へ委ね、ここでは再定義しない。

本Skillは`verify`の結果と必要な検証・artifactの完了を確認し、未完了事項や残るriskを報告する。
実装済みという理由だけでsliceを完了扱いせず、成立条件とIssue全体の残scopeを確認する。

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

AGYのpermission、approval、workspace境界を追加の停止境界として扱い、workspace追加、設定変更、別tool等で回避しない。accessできない検証や操作は未実施または`environment blocked`として報告する。

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
- <verifyの結果・必要な検証の完了状況>
- artifact: <verifyの保存先>

Findings:
- blocker:
- follow-up:
- release audit:

Incomplete:
- <検証の未完了事項と理由>

Git state:
- staged / unstaged / untracked:
- commit / push / PR:

Next:
- <1つの具体的な次の一手>
```

現在のPR単位の完了とIssue全体の完了を区別する。作業sliceが完了してもIssueに残scopeがあれば、Issue completedと報告しない。
