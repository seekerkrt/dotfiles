---
name: audit
description: 実装前調査、責務境界・未使用コード・危険な前提の監査、docs / tests / build設定と実装の整合確認、Issue化前調査、または「調査だけ」「監査だけ」の依頼で使用し、fileを編集せずEvidenceへ対応したfindingを作る。
---

# Read-only audit

## 固有契約

- 監査中はfileを編集せず、stage、commit、push、外部mutationを行わない。
- 一般論ではなく、具体的なfile、function、symbol、call path、設定、docsへfindingを対応させる。
- 事実、推測、提案、未確認を分ける。
- 単一grep、参照0件、1つのbuildだけで結論を確定しない。
- 調査結果を実装済み、修正採用済み、Issue作成済みとして書かない。

ユーザーが修正まで依頼している場合も、編集前の監査phaseだけにこの契約を適用し、監査結果と実装結果を混同しない。

## Workflow

1. repository、branch、対象directory / file / feature / symbol、依頼された問い、non-goalを確定する。
2. `git status --short --branch`で既存変更を確認する。
3. `rg --files`、`git ls-files`、`find`等で対象を列挙する。
4. definition、reference、include / import、registration、build定義、生成処理、external entryを追う。
5. 近傍のdocs、tests、README、`CLAUDE.md`、build / CI設定、履歴を必要な範囲で確認する。
6. 現行owner、source of truth、lifetime、invariant、責務境界を整理する。
7. 反証経路、別build、runtime lookup、code generation、外部consumerがないか確認する。
8. Evidence付きfindingを作り、Severity、Confidence、最小検証、fix方向を示す。
9. 必要な場合だけIssue / PR分割候補を提案する。作成はしない。

存在を確認していないtoolやtargetを前提にしない。call pathを最後まで追えない場合は、確認済みの終点と未確認の分岐を示す。

## Finding contract

各findingへ最低限、次を含める。

```text
Severity:
Confidence:
Area:
Evidence:
Expected contract:
Actual behavior:
Risk:
Minimal verification:
Suggested fix direction:
```

`Evidence`には可能な限りpath、symbol、行、call path、docs / testとの対応を入れる。`Suggested fix direction`は採用済みの実装ではなく、最小scopeの方向として書く。

Issue化が有用なfindingに限り、`Suggested issue title`を追加する。

### Severity

- Critical: data loss、重大な安全性問題、広範な破壊へ直結する。
- High: 通常経路のcorrectnessや主要機能を壊す可能性が高い。
- Medium: 条件付き不具合、契約不整合、無視しにくい保守riskがある。
- Low: 影響が限定され、急がない改善候補である。

repository固有の基準があればそちらを優先する。

### Confidence

- High: code path、契約、testまたは再現根拠が揃う。
- Medium: 主要根拠はあるが、runtimeや分岐が一部未確認である。
- Low: 仮説段階で追加調査が必要である。

## 未使用判定

次を区別する。

- 本当に未使用: definition、reference、build、生成、外部入口を確認しても利用根拠がない。
- 現在dormant: 現行経路では動かないが、意図的に残している可能性がある。
- 将来利用予定の根拠あり: docs、Issue、TODO、設定等に具体的根拠がある。
- 生成物・別build・external entryで利用: 通常検索に出ない経路が確認できる。
- 判定保留: 証拠が足りない。

reflection、registration、runtime lookup、code generation、build option、public APIを確認せず「参照0件だから削除可能」と断定しない。

## Issue / PR分割候補

提案する場合は、title、scope、non-goal、受け入れ条件、最小検証、依存関係、同一PRまたは分割の理由を示す。

## 失敗時

- 読めないfile、取得できない外部情報、実行できないtoolを理由付きで「未確認」とする。
- sandbox、権限、環境不足、repository外依存、対象コードの不具合を区別する。
- 根拠が競合する場合は両方を示し、結論を保留する。
- dormantや判定保留を「削除してよい」と言い換えない。

## 出力

現状、scope / non-goal、findings、未確認、Issue / PR分割候補、推し案、次の一手の順で簡潔にまとめる。findingがない場合も、確認範囲と未確認範囲を示し、無条件に「問題なし」と断定しない。
