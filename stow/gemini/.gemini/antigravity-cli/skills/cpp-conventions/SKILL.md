---
name: cpp-conventions
description: >-
  C/C++の実装・編集・reviewで使う共通baseline。project固有規約を優先しつつ、
  命名、WHY/POLICY/LANDMINE/NOTEコメント、cast、RAII等の判断基準を適用する。
---

# C/C++ 共通規約

## 位置づけ

このSkillは全project共通のbaselineである。実装やreviewの前に、対象scopeへ
適用されるrepository指示、近傍コード、`docs/CODING_CONVENTIONS.md`等の
project固有規約を確認する。矛盾する場合はproject側を優先する。

純粋なCではC++固有の機能・cast規則を適用せず、命名とコメント等の共通項目だけを
使う。C固有の方針はproject規約と近傍コードへ合わせる。

次はprojectごとに方針が分かれるため、このSkillだけで決めない。

- 例外の可否と失敗伝播
- hosted / freestandingと標準libraryの利用範囲
- function・method命名
- header / sourceの分割方針
- `reinterpret_cast`の許容範囲と閉じ込め先

## 実装前の確認

1. build target、language standard、compiler optionを確認する。
2. 近傍の命名、ownership、error処理、comment粒度を確認する。
3. public contract、ABI、hardware・OS・protocol制約を確認する。
4. 今回の変更が局所の足場か、他codeが依存する契約かを分ける。

## 命名

- type、class、struct、`enum class`はPascalCase。
- class memberは`_`接尾辞を付ける。必要なものだけpublicにする。
- struct memberは接尾辞なしとし、単純なdata集約として扱う。
- namespaceは原則小文字。
- constantとmacroはUPPER_SNAKE_CASE。magic numberは意味の残る
  `const`または`constexpr`へ寄せる。
- local variableとargumentはsnake_case。
- global variableは極力避ける。必要なら`g_`接頭辞を付け、翻訳単位内へ閉じる。
- function内`static`は原則避ける。必要なら`s_`接頭辞を付け、lifetimeと副作用が
  分かる名前にする。
- 翻訳単位限定のfunction、variable、constant、helper typeは無名namespaceへ閉じる。
- boolは`is_`、`has_`、`should_`、`can_`、`needs_`等、真偽の意味が読める名前を
  優先する。
- `tmp`、`ret`、`val`、`obj`等の曖昧な名前は、短い局所処理以外で避ける。

## コメント

コードを見れば分かるWHATの逐語説明ではなく、後から意図と制約を復元できる
コメントを残す。

- WHY: なぜこの実装、順序、構造なのか。
- POLICY: 継続して守る契約や方針は何か。
- LANDMINE: 移動、削除、共通化で壊れる条件は何か。
- NOTE: 暫定事情、補足、将来の整理観点は何か。

特に次へ短い意図コメントを置く。

- 一見不自然な順序、待機、retry、特殊case
- hardware、OS、protocol、external API都合に引かれる処理
- dependency order、initialization order、call orderに意味がある箇所
- state、flag、ownership、lifetimeがcodeだけでは読みにくい箇所
- 一時対応か恒久contractか分かりにくい箇所

file先頭の責務・前提・地雷コメントや、責務境界を示す見出しコメントは使ってよい。
コメントをimplementationの代わりにはしない。

## C++機能

積極的に使う。

- RAII: lock、後始末、状態復元。失敗時のcleanupをdestructorへ寄せる。
- `enum class`: 種別や状態を型安全に表す。
- `constexpr`と`static_assert`: compile-timeの定数と前提を検証する。
- ownershipとlifetimeが明確なmove semantics、`unique_ptr`相当の表現。
- 意図が明快でzero-cost寄りの薄いtemplate。

慎重に使う。

- inheritanceと`virtual`: 差し替え可能な抽象が必要な場合だけ。composition、
  責務分離、function分割を先に検討する。
- operator overload: domain上自然で、挙動を誤解しない場合だけ。

避ける。

- RTTIや`dynamic_cast`前提の設計
- 重いtemplate metaprogramming
- 処理を追いにくいgeneric wrapper
- 既存処理を薄く包むだけの互換function
- 「便利そう」だけを理由にしたglobal state

## cast

- C-style castは使わない。
- 意味のある変換には`static_cast`を使う。
- `const_cast`は必要性と安全条件を説明できる場合だけ使う。
- `dynamic_cast`は常用しない。
- `reinterpret_cast`はproject規約に従い、必要ならlow-level境界へ閉じ込める。

## 変更とreview

- 近傍のstyle、責務分割、error処理へ合わせる。
- 大規模整形、広範囲rename、unrelated cleanupを機能変更へ混ぜない。
- public contractを変える場合は、caller、test、docs、migration影響を確認する。
- reviewでは「何が問題か」「なぜ問題か」「どう直すか」を分ける。
- 差分をreview可能な論理単位に保つ。
