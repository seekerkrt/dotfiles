---
name: audit
description: 実装前調査、責務境界・未使用コード・危険な前提の監査、docsと実装の整合確認、Issue化前の調査、またはユーザーが「調査だけ」「監査だけ」と指定した場面で、編集せず根拠付きfindingを作る。
---

# 目的

read-onlyの監査を、具体的なfile、function、symbol、call pathに対応したfindingとして残す。

調査と実装の境界を守り、事実、推測、提案、未確認を分けたうえで、修正判断に必要な根拠と最小の次の一手を示す。

# 使用条件

次の作業で使用する。

- 実装前調査
- 責務境界の監査
- 未使用コードや不要ファイルの監査
- 危険な前提や暗黙のinvariantの棚卸し
- docs、tests、build設定、実装の整合確認
- Issue化やPR分割前の調査
- ユーザーが「調査だけ」「監査だけ」と明示した作業

ユーザーが修正まで明示している場合も、編集前の調査フェーズにこのSkillを使ってよい。ただし、監査結果と実装結果は混同しない。

# 最重要ルール

- 監査中はファイルを編集しない。
- `git add`、commit、pushを行わない。
- 調査依頼を勝手に実装依頼へ拡張しない。
- 一般論だけで終わらせず、具体的なfile、function、symbol、call pathへ対応させる。
- 事実、推測、提案、未確認を明示的に分ける。
- grepや単一の観測だけで結論を確定しない。
- 推測だけで未確認部分の実装や削除を勧めない。
- working treeの既存変更をユーザーの作業として扱い、内容を変更しない。

# scopeとnon-goal

調査開始時に次を明確にする。

- 対象repositoryとbranch
- 調査対象のdirectory、file、feature、symbol
- 依頼された問い
- 今回確認しない範囲
- 編集、外部書き込み、runtime検証などの非目標

依頼からscopeを安全に確定できる場合は調査を進める。複数repositoryや破壊的判断につながる対象が曖昧な場合は、推測で範囲を広げない。

# 基本ワークフロー

1. scopeと除外範囲を確定する。
2. `git status --short --branch` でworking treeとbranchを確認する。
3. `rg --files`、`find`、`git ls-files`等で関連ファイルを列挙する。
4. `rg`、参照検索、include/import、build定義から呼び出し元と呼び出し先を追跡する。
5. 近傍のdocs、tests、README、AGENTS.md、build設定、CI設定を確認する。
6. 現行のowner、source of truth、lifetime、invariant、責務境界を整理する。
7. 反証になる経路や別build、生成処理、外部入口がないか確認する。
8. 根拠を付けてfindingを作成する。
9. SeverityとConfidenceを付け、最小の検証とfix方向を示す。
10. 必要に応じてIssue化とPR分割の候補を示す。

repository固有の検索・解析commandは、既存docsや構造から決める。存在を確認していないtoolやbuild targetを前提にしない。

# finding形式

各findingには最低限、次を含める。

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
Suggested issue title:
```

`Evidence`には、可能な限りfile path、functionまたはsymbol、該当行、call path、docsやtestの対応箇所を含める。

`Suggested fix direction`は実装済みのように書かず、最小scopeの方向性として示す。複数案を出す場合も、推し案を先に置く。

## Severity

対象repositoryに既存基準があればそれを優先する。基準がない場合は、次を目安にする。

- Critical: データ消失、重大な安全性問題、広範な破壊につながる。
- High: 通常経路でcorrectnessや主要機能を壊す可能性が高い。
- Medium: 条件付きの不具合、保守性低下、契約の不整合がある。
- Low: 影響が限定的で、急がない改善候補である。

## Confidence

- High: code path、契約、再現またはtest根拠が揃っている。
- Medium: 主要根拠はあるが、runtimeや別経路が未確認である。
- Low: 仮説段階で、追加調査なしには結論を出せない。

# 未使用判定

未使用コードや不要ファイルは、次を分けて報告する。

- 本当に未使用: 定義、参照、build、生成、外部入口を確認しても利用根拠がない。
- 現在dormant: 現行経路では動かないが、意図的に残している可能性がある。
- 将来利用予定の根拠あり: docs、TODO、Issue、設定等に具体的な根拠がある。
- 生成物や別buildでのみ利用: 通常検索に出にくい利用経路が確認できる。
- 判定保留: 利用有無を確定する証拠が足りない。

grep結果が0件という理由だけで、削除可能または本当に未使用と断定しない。reflection、registration、code generation、build option、external API、runtime lookup等の可能性を対象に応じて確認する。

# Issue化・PR分割候補

findingを作業単位へ落とす場合は、次を示す。

- Issue title候補
- 対象scope
- non-goal
- 受け入れ条件
- 最小検証
- 依存関係
- 1 PRで扱う理由、または分割する理由

IssueやPRの作成は行わない。GitHub側へ書き込む場合は、別途ユーザーの明示依頼と `github` Skillの手順が必要になる。

# 禁止事項

- 監査中のファイル編集
- `git add`、commit、push
- 勝手なrestore、reset、stash、clean、branch切り替え
- 調査scope外の広範な棚卸し
- findingの数を増やすための推測
- 実行していないtestやruntime確認を根拠にすること
- dormantや判定保留を「削除してよい」と言い換えること
- 調査依頼からIssue作成、PR作成、comment等へ進むこと

# 失敗時・未確認時の扱い

- 読めないfile、取得できないGitHub情報、実行できないtoolは、理由とともに「未確認」とする。
- sandbox、権限、環境不足、repository外依存を区別する。
- call pathを最後まで追えない場合は、確認済みの終点と残る分岐を示す。
- 根拠が競合する場合は両方を示し、結論を判定保留にする。
- 調査commandの失敗を、対象コードの不具合と混同しない。

# 最終報告

次の順で簡潔に報告する。

```text
現状:
- repository / branch
- scope / non-goal

findings:
- Severity / Confidence / Area
- Evidence / Risk / Suggested fix direction

未確認:
- ...

Issue / PR分割候補:
- ...

推し案:
- ...

次の一手:
- ...
```

findingがない場合も「問題なし」と断定せず、確認した範囲、使った根拠、未確認範囲を示す。
