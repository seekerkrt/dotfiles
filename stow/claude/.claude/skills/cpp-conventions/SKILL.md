---
name: cpp-conventions
description: C++コードの生成・編集・review、およびC++から利用するC互換headerやC/C++共有境界で使用し、C++標準、宣言と定義の分離、共通命名、コメント、所有権、C++機能、castの全project共通baselineを適用する。repositoryにdocs/CODING_CONVENTIONS.mdがあれば必ず併読し、build設定とproject規約が本Skillと異なる部分はproject側を優先する。
---

# C++共通規約

## 適用順

1. 作業対象に適用される`CLAUDE.md`を読む。
2. repositoryの`docs/CODING_CONVENTIONS.md`が存在すれば読む。
3. Makefile、CMake等の実際のbuild設定からcompiler、C++標準、例外、RTTI、warningを確認する。
4. project側に明示がない部分へ本Skillの共通baselineを適用する。

現在のcompile条件は実際のbuild設定を事実として扱い、project固有の意図はproject規約を正とする。両者が食い違う場合は片方を推測で正しいものとして扱わず、不整合を報告する。コード、docs、build設定の修正は今回のscopeに含まれる場合だけ行う。

本SkillはC++を主対象とする。C互換headerやC/C++共有ABI境界では適用可能な項目だけを使い、純粋なCコードの命名、cast、配置はproject規約と周辺コードを優先する。

## C++標準

- C++20を共通baselineとする。
- repositoryのbuild設定またはproject規約が別の標準を明示する場合は、project側を優先する。
- 作業目的に含まれないC++標準の引き上げ・引き下げを混ぜない。
- C++20より新しい機能やcompiler拡張を、対応するcompiler設定の確認なしに導入しない。

## 宣言と定義

- 非自明なclass、複数箇所から利用する型、公開interfaceは、原則として宣言を`.hpp`、定義を`.cpp`へ分離する。
- headerには公開契約と必要な宣言を置き、実装詳細と重い依存は可能な限り`.cpp`へ閉じ込める。
- template、`constexpr`、`inline`、trivialな定義、C互換ABI header等、header側に定義が必要なものは例外とする。
- 既存の単一file構成を、分離自体を目的として一括変更しない。
- compatibility契約のないinclude forwardingだけのheaderや、責務を持たない共通headerを増やさない。
- project規約が分離を必須化、緩和、または別配置を指定する場合は、その差分を優先する。

## 共通命名

- 型、class、struct、`enum class`はPascalCaseを基本とする。
- namespaceは小文字を基本とする。
- local変数と関数引数はsnake_caseを基本とする。
- class memberは`_`接尾辞、単純なdata aggregateのstruct memberは接尾辞なしを基本とする。
- classの状態は`private` / `protected`を基本とし、単純なdata aggregateだけをpublic member中心で扱う。意味のないaccessorを形式的に増やさない。
- 定数とmacroはUPPER_SNAKE_CASEを基本とし、magic numberは意味が残る`constexpr`等へ寄せる。
- global stateは避ける。必要なら翻訳単位へ閉じ、project規約に従って寿命と副作用が分かる名前を付ける。
- project規約に別指定がなければ、必要なglobal変数は`g_`、function-local staticは`s_`を付ける。どちらも導入理由、寿命、再入性への影響を確認する。
- translation unit限定の関数、変数、定数、補助型は無名namespaceへ閉じることを基本とする。
- boolは`is_`、`has_`、`should_`、`can_`、`needs_`等、真偽の意味が読める名前を優先する。
- `tmp`、`ret`、`val`、`obj`等の曖昧な名前は、短い局所処理以外で避ける。

public / internal関数、enum value、file名等の命名がprojectごとに異なる場合は、project規約と周辺コードへ従う。

## コメント

コードを見れば分かるWHATの逐語説明は量産せず、function数・行数・branch数等によるコメントquotaは設けない。
実装完了時に変更した非自明な処理を確認し、コードだけでは復元できない次の情報は必要な箇所へコメントとして残す。

- 設計理由・policy: 実装、構造、algorithm、分岐、処理順序の選択とalternativeを採用できない理由。
  correctness / safety / compatibility、fallbackや意図的に無視するerror、
  fail-open / fail-closed、user-visible behavior等の判断根拠を含む。
- contract: caller / calleeの事前・事後条件、保証・invariant、ownership / lifetime、
  identity / ordering / provenance、state transition、thread safetyと
  外部resourceの維持条件。
- 危険な簡略化: guard・check・releaseの順序を変えられない理由、race / TOCTOU / double freeの回避、
  filesystem / OS / hardware / ABI / protocol依存、compatibility workaround等。
- 非自明な値・tradeoff: magic threshold、sentinel value、security boundary、data-loss防止、
  performance上の意図。暫定事情や将来の整理観点は、必要な補足として残す。

該当項目があるだけで機械的にコメントを増やさない。一方、「コードが読める」を理由に設計意図まで省略しない。

### 宣言と定義での配置

- 宣言側にはinterfaceとして必要なcontractを置く。
- 定義側にはimplementation固有の設計理由・policy・危険な簡略化の注意を置く。
- 同じ説明を両方へ複製せず、その場所で必要な情報だけを置く。

file headerや区切りコメントは、責務境界と編集時のlandmarkとして必要な場合に使う。
コメントをimplementationの代わりにしない。

## C++機能と所有権

- RAIIでlock、resource、temporary state、cleanupをscopeへ束ねる。
- `enum class`で状態・種別を型安全に表現する。
- `constexpr`と`static_assert`で定数とcompile-time invariantを表現する。
- C++内の単なる定数は`constexpr`等を使い、`#define`は条件compile、C / asm共有、token操作等、preprocessorである必要がある用途へ限定する。
- 所有者、borrow、寿命、move後の状態をinterfaceと型から読めるようにする。
- owning pointerには`unique_ptr`相当の単一所有表現を優先し、生pointerを暗黙のownerにしない。
- 継承と`virtual`は差し替え可能な抽象が必要な場合に限り、合成や責務分割を先に検討する。
- RTTI、`dynamic_cast`、例外の可否はproject規約とbuild設定を確認する。許可されていても、具体型へ戻さないと成立しない設計や不明瞭な制御フローを常用しない。
- templateは型安全や重複削減の効果が明確な薄い用途に留め、追跡しにくいmetaprogrammingを増やさない。
- operator overloadはdomain上自然で、挙動を誤解しない場合だけ使う。
- 別名を増やすだけのforwarding functionや薄いcompatibility wrapperは、移行契約や利用者が明確な場合だけ作る。

## cast

- C++コードではC-style castを使わない。
- 通常の値変換、enumと整数、前提を確認済みの継承階層変換には`static_cast`を使う。具体型へのdowncastは、その前提をinterfaceで表せないか先に確認する。
- `const_cast`は外す必要と安全性を説明できる境界だけで使う。
- `dynamic_cast`はRTTIが許可され、runtime型判定が設計上必要な場合だけ使う。
- `reinterpret_cast`の可否と閉じ込め先はproject規約へ従う。明示がなければ新規導入せず、hardware、ABI、生memory等の境界を先に特定する。

## Project側で決める事項

本Skillでは次を断定しない。

- freestanding / hosted
- 例外とRTTIの可否
- 標準libraryの利用範囲
- public / internal関数の命名
- `reinterpret_cast`を許可する層
- directory構成とABI headerの配置
- `.hpp` / `.cpp`分離を必須化する範囲
- formatter、compiler、warning policy

## 差分の作り方

- 変更対象の周辺で、命名、責務、error処理、comment粒度、include順を確認する。
- 実装前に、公開契約、ABI、hardware / OS / protocol制約への影響範囲を確認する。
- project全体の整形、広範囲rename、unrelated cleanupを機能変更へ混ぜない。
- 既存違反を、この作業と無関係に一括修正しない。
- 新しい公開契約を作る場合は、project docsとtestへ反映する必要性を確認する。
- reviewでは、何が問題か、なぜ問題か、どう直すかを分けて示す。
