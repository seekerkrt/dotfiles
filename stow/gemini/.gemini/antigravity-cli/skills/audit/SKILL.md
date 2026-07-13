---
name: audit
description: >-
  実装前調査、read-only監査、責務境界・未使用コード・危険な前提の確認、
  docsと実装の整合確認、Issue化前調査で、編集せず根拠付きfindingを作る。
---

# read-only監査

## 目的

具体的なfile、symbol、参照経路、docs、testへ根拠を対応させ、修正判断に必要な
findingを作る。事実、推測、提案、未確認を分け、監査と実装の境界を守る。

## 使用する場面

- 実装前の現状調査
- 責務境界、owner、source of truthの監査
- 未使用コード、不要file、dormant経路の判定
- 暗黙のinvariantや危険な前提の棚卸し
- docs、tests、build設定、実装の整合確認
- Issue化やPR分割前の調査
- ユーザーが「調査だけ」「監査だけ」と指定した作業

修正まで依頼されている場合は、編集前フェーズとして使う。主要findingを固めたら
実装へ移り、監査結果と変更結果を混同しない。計画だけで停止しない。

## 調査境界

開始時に次を確定する。

- repository rootとbranch
- 対象directory、file、feature、symbol
- 依頼された問い
- 今回確認しない範囲
- file編集、外部write、runtime確認などのnon-goal

監査中はfileを編集しない。read-only操作がAGYのpermissionまたはworkspace境界で
拒否された場合は、境界を広げたり設定を変更したりせず、確認できた終点と
未確認範囲を記録する。

## 基本ワークフロー

1. `git status --short --branch` でbranchと既存変更を確認する。
2. `rg --files`、`git ls-files`等で関連fileを列挙する。
3. `rg`、include/import、build定義から参照元と参照先を追う。
4. 適用される`GEMINI.md`、repository固有指示、README、docs、tests、
   build設定、CI設定を確認する。
5. owner、source of truth、lifetime、invariant、責務境界を整理する。
6. 別build、生成処理、registration、外部入口など反証候補を確認する。
7. 根拠をfile path、symbol、行、call pathへ対応させる。
8. findingへSeverity、Confidence、最小検証、fix方向を付ける。
9. 必要な場合だけIssue化・PR分割候補を示す。

存在を確認していないtool、target、外部状態を前提にしない。GitHub側の調査が必要な
場合は`github` Skillも使い、取得不能な情報をローカルGitの事実で代用しない。

## finding形式

各findingには最低限、次を含める。

~~~text
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
~~~

Evidenceには可能な限り次を入れる。

- file pathと該当行
- function、class、variable、設定key等のsymbol
- callerからcalleeまでの参照経路
- 対応するdocs、test、build設定
- 実行したread-only commandと観測結果

### Severity

- Critical: データ消失、重大な安全性問題、広範な破壊につながる。
- High: 通常経路でcorrectnessや主要機能を壊す可能性が高い。
- Medium: 条件付き不具合、契約不整合、継続的な保守リスクがある。
- Low: 影響が限定的で、急がない改善候補である。

repository固有基準があれば、そちらを優先する。

### Confidence

- High: code path、契約、testまたは再現根拠が揃っている。
- Medium: 主要根拠はあるが、runtimeや別経路が未確認である。
- Low: 仮説段階で、追加調査なしには結論を確定できない。

## 未使用判定

grepの0件だけで削除可能と判断しない。次を分ける。

- 本当に未使用: 定義、参照、build、生成、外部入口に利用根拠がない。
- dormant: 現行経路では動かないが、意図的に残している可能性がある。
- 将来利用の根拠あり: docs、TODO、Issue、設定に具体的根拠がある。
- 別buildまたは生成物で利用: 通常検索に出にくい経路を確認できた。
- 判定保留: reflection、registration、runtime lookup等を否定できない。

## Issue・PR分割候補

作業単位へ落とす場合は、title候補、scope、non-goal、受け入れ条件、最小検証、
依存関係、分割理由を示す。GitHubへの作成や投稿は別の明示依頼がない限り行わない。

## 失敗・未確認

- 読めないfileや実行できないcommandは、理由とともに「未確認」とする。
- permission拒否、workspace外、dependency不足、network、repository外依存を分ける。
- call pathを追い切れない場合は、確認済みの終点と残る分岐を示す。
- 根拠が競合する場合は両方を示し、結論を判定保留にする。
- command失敗を対象コードの不具合と混同しない。

## 最終報告

次の順で簡潔にまとめる。

~~~text
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
~~~

findingがない場合も「問題なし」と断定せず、確認範囲、根拠、未確認範囲を示す。
