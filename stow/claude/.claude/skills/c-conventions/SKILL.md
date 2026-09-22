---

name: c-conventions
description: Cコードの生成・編集・review、およびCから利用するABI headerやC/C++共有境界で使用し、C標準、宣言と定義の分離、共通命名、コメント、ownershipとlifetime、resource管理、pointer、整数変換、error処理、undefined behavior回避の全project共通baselineを適用する。repositoryにdocs/coding-conventions.md等のproject規約があれば必ず併読し、build設定とproject規約が本Skillと異なる部分はproject側を優先する。
---

# C共通規約

## 適用順

1. 作業対象に適用される`AGENTS.md`を読む。
2. repositoryの`docs/coding-conventions.md`のようなコーディング規約文書が存在すれば読む。
3. Makefile、CMake、Meson等の実際のbuild設定からcompiler、C標準、warning、optimization、freestanding / hosted等の条件を確認する。
4. project側に明示がない部分へ本Skillの共通baselineを適用する。

現在のcompile条件は実際のbuild設定を事実として扱い、project固有の意図はproject規約を正とする。両者が食い違う場合は片方を推測で正しいものとして扱わず、不整合を報告する。コード、docs、build設定の修正は今回のscopeに含まれる場合だけ行う。

本Skillは純粋なCコードを主対象とする。C/C++共有ABI headerでは両言語で有効な構文とABI上の制約を確認し、C++固有の規約をC側へ持ち込まない。

## C標準

* C17を共通baselineとする。
* repositoryのbuild設定またはproject規約が別の標準を明示する場合は、project側を優先する。
* 作業目的に含まれないC標準の引き上げ・引き下げを混ぜない。
* C17より新しい機能やcompiler拡張を、対応するcompiler設定とproject方針の確認なしに導入しない。
* GNU extension、compiler builtin、statement expression、attribute等は、既存利用または明確な必要性がある場合に限る。
* freestanding環境では、hosted Cで利用可能なstandard library機能が存在するとは仮定しない。

## 宣言と定義

* 複数translation unitから利用する型、定数、関数、公開interfaceは、原則としてheaderへ宣言を置き、実装を`.c`へ分離する。
* headerには利用者が必要とする契約と宣言だけを置き、implementation detailは可能な限り`.c`へ閉じ込める。
* translation unit内だけで使う関数・変数は`static`で内部linkageへ閉じる。
* header内で定義する関数は、用途を確認したうえで`static inline`等の適切なlinkageを使用する。
* tentative definitionやheader内の非`static`object定義によるmultiple definitionへ依存しない。
* compatibility契約のないinclude forwardingだけのheaderや、責務を持たない共通headerを増やさない。
* 既存の単一file構成を、分離自体を目的として一括変更しない。
* project規約が配置、header構成、internal header等を指定する場合は、その差分を優先する。

### Header

* include guardまたはprojectで採用している仕組みを使用する。
* header単体でinclude可能な状態を基本とし、利用者側のinclude順へ暗黙依存しない。
* 必要な型・macro・宣言を提供するheaderを直接includeし、偶然のtransitive includeへ依存しない。
* 公開headerへimplementation detailや不要な依存を漏らさない。
* C/C++共有headerでは必要に応じて`extern "C"`境界を設けるが、CコードそのものへC++構文を導入しない。

## 共通命名

* `struct`、`union`、`enum`、`typedef`、function、variable等の具体的な命名形式は、まずproject規約と周辺コードへ従う。
* project規約に別指定がなければ、関数、local変数、関数引数、struct memberはsnake_caseを基本とする。
* macroとcompile-time定数macroはUPPER_SNAKE_CASEを基本とする。
* bool相当の値やpredicate関数は`is_`、`has_`、`should_`、`can_`、`needs_`等、真偽の意味が読める名前を優先する。
* translation unit内だけで使う名前は`static`へ閉じ、不要なglobal symbolを公開しない。
* global mutable stateは避ける。必要な場合は寿命、ownership、初期化順序、thread / interrupt safety、副作用が読める構造と名前にする。
* `tmp`、`ret`、`val`、`obj`、`ptr`等の曖昧な名前は、短い局所処理以外で避ける。
* pointerであることだけを名前に重複させる`p_`等のHungarian notationは、project規約で採用されている場合を除き導入しない。
* typedefによってpointer性やresource ownershipを隠す設計は、抽象化上の明確な理由がある場合だけ使う。

public / internal関数、型名、enum value、file名、prefix等の命名がprojectごとに異なる場合は、project規約と周辺コードへ従う。

## コメント

コードを見れば分かるWHATの逐語説明は量産せず、function数・行数・branch数等によるコメントquotaは設けない。

実装完了時に変更した非自明な処理を確認し、コードだけでは復元できない次の情報は必要な箇所へコメントとして残す。

* 設計理由・policy: 実装、構造、algorithm、分岐、処理順序の選択とalternativeを採用できない理由。
  correctness / safety / compatibility、fallbackや意図的に無視するerror、
  fail-open / fail-closed、user-visible behavior等の判断根拠を含む。
* contract: caller / calleeの事前・事後条件、保証・invariant、
  ownership / lifetime、buffer size、NULL可否、identity / ordering / provenance、
  state transition、thread / interrupt safetyと外部resourceの維持条件。
* 危険な簡略化: check・acquire・releaseの順序を変えられない理由、
  race / TOCTOU / double free / use-after-free / integer overflowの回避、
  filesystem / OS / hardware / ABI / protocol依存、compatibility workaround等。
* 非自明な値・tradeoff: magic threshold、sentinel value、security boundary、
  data-loss防止、performance上の意図。暫定事情や将来の整理観点は、必要な補足として残す。

該当項目があるだけで機械的にコメントを増やさない。一方、「コードが読める」を理由に設計意図やownership contractまで省略しない。

### 宣言と定義での配置

* 宣言側にはinterfaceとして必要なcontractを置く。
* 定義側にはimplementation固有の設計理由・policy・危険な簡略化の注意を置く。
* 同じ説明を両方へ複製せず、その場所で必要な情報だけを置く。

file headerや区切りコメントは、責務境界と編集時のlandmarkとして必要な場合に使う。
コメントをimplementationの代わりにしない。

## Ownershipとlifetime

Cではownershipを型システムだけで表現できないため、resourceの所有者とlifetimeをinterface、命名、構造、コメントから追跡可能にする。

* allocation、file descriptor、handle、lock、mapping、buffer等、releaseが必要なresourceには明確なownerを定める。
* resourceを取得する関数と解放する関数の対応を明確にする。
* caller-owned / callee-owned / borrowedの区別が自明でないinterfaceではcontractとして明示する。
* borrowed pointerをownerとして解放しない。
* ownership transferが発生する場合は、成功時・失敗時それぞれで誰がresourceを保持するかを明確にする。
* pointerが指すobjectより長くpointerを保持しない。
* stack object、temporary buffer、reallocation前のpointer等の寿命を越えて参照を残さない。
* `free()`、close、unmap等の後に同じresourceを再利用しない。
* cleanup後も変数が生存する場合、double release防止のためNULL化やinvalid sentinel化が有効かを周辺設計に応じて検討する。
* cleanup責務を複数箇所へ無秩序に分散させない。

## Resource管理とcleanup

* 複数resourceを段階的に取得する処理では、全error pathで取得済みresourceが正しく解放されることを確認する。
* cleanup順序に依存がある場合は、原則として取得と逆順にreleaseする。
* Cでの構造化cleanupとして`goto cleanup`等を用いることは許容する。重複cleanupや複雑なnested branchを減らせる場合は、無理に避けない。
* `goto`はresource cleanupや単一のerror exit等、制御フローを明確化する用途へ限定し、通常処理を不規則に飛び回る用途には使わない。
* cleanup helperを導入する場合は、ownershipや失敗条件を隠してかえって追跡困難にならないか確認する。
* allocation失敗、partial initialization、途中errorを正常系と同様に設計対象として扱う。

## Pointerとbuffer

* pointerのNULL可否、参照可能な要素数、alignment、lifetime、ownershipをinterfaceから判断できるようにする。
* dereference前に、そのpointerが有効である根拠を確認する。
* pointer arithmeticは対象objectまたはarrayの範囲内で行う。
* one-past pointerは比較等の規定された用途に限定し、dereferenceしない。
* buffer処理ではcapacity、現在length、terminatorの有無を区別する。
* byte数と要素数を混同しない。`sizeof`を使う際は対象がarrayかpointerかを確認する。
* `memcpy`は領域がoverlapしないことを確認し、overlapし得る場合は`memmove`等を使う。
* 文字列APIを使う際はNUL終端の保証とbuffer sizeを確認する。
* function parameterのarray記法が実際にはpointer parameterであることを踏まえ、size情報が必要なら別途明示する。
* 型の異なるpointer間変換、alignment依存アクセス、object representationへのアクセスはC標準・ABI・hardware要件を確認する。

## Allocation

* allocation sizeの計算で整数overflowが起きないことを確認する。
* `malloc(count * sizeof(*ptr))`等では`count`との乗算overflowを必要に応じて事前検証する。
* object型に合わせて`sizeof(*ptr)`を使える場合は、型名の重複より優先する。
* Cコードでは`malloc`等の戻り値を不要にcastしない。ただしprojectや特殊な共有headerの事情がある場合はその規約に従う。
* `realloc`の失敗時に元pointerが有効なままであることを踏まえ、戻り値を直接元変数へ上書きしてresourceを失わない。
* zero-size allocationの挙動へportableでない前提を置かない。
* allocationとdeallocation APIのfamilyを対応させる。

## 整数と変換

* signed / unsigned、幅、promotion、overflow、truncationを意識して型を選ぶ。
* size、index、object sizeでは、APIとproject規約に適した型を使う。機械的にすべて`int`または`size_t`へ寄せない。
* signed値をunsigned型へ暗黙変換する前に、負値があり得ないことを確認する。
* より狭い型への変換では値域を確認する。
* integer overflowをwraparound前提で利用する場合は、unsigned arithmetic等、C標準上その意味が定義されている型と文脈へ限定する。
* signed integer overflowへ依存しない。
* bit shiftではshift幅、signedness、値域を確認する。
* sentinelとして負値とunsigned値を混在させない。
* comparisonでsigned / unsigned conversionにより意味が変わらないことを確認する。
* ABI、hardware register、protocol等で幅が契約となる場合は`stdint.h`の固定幅型等をproject方針に従って使う。

## Cast

* castは型不整合を隠すためではなく、変換の意図と安全性を確認した境界で使う。
* 不要なcastを追加してcompiler warningを黙らせない。
* pointerとinteger間の変換は、ABI、OS、hardware等で必要性が明確な場合に限定する。
* object pointer間の変換ではalignment、effective type、strict aliasing、object lifetimeへの影響を確認する。
* `const`をcastで外す場合は、元objectが実際にmodifiableであり、API境界上どうしても必要であることを確認する。
* function pointerとobject pointerの相互変換をportableと仮定しない。
* C/C++共有境界では両言語の変換規則を混同しない。

## Error処理

* projectで採用しているerror表現を優先する。戻り値、errno、enum、status code等を無秩序に混在させない。
* functionの成功・失敗条件をcallerが判定できるinterfaceにする。
* errorを握り潰す場合は、それが意図されたpolicyであることを確認する。
* cleanup時の副次errorがprimary errorを不必要に上書きしないようにする。
* `errno`を使うAPIでは、その値が有効となる条件を確認し、成功時の残存値をerrorとして扱わない。
* partial resultを返すinterfaceでは、成功・部分成功・失敗の区別を明確にする。
* recover不能な内部invariant violationと、外部入力・resource不足等の通常errorを区別する。
* `assert`をuser input validationや通常発生可能なruntime error処理の代替にしない。

## Undefined behaviorと未規定動作

次のような箇所では、動作がC標準、compiler、ABI、hardwareのどこで保証されているかを確認する。

* signed integer overflow
* out-of-bounds access
* NULLまたはinvalid pointerのdereference
* use-after-free / double free
* uninitialized valueの利用
* invalid shift
* alignment違反
* strict aliasing / effective type違反
* object lifetime外のaccess
* sequence / evaluation orderへ依存する式
* format stringとargument型の不一致
* data race
* incompatible function pointer経由のcall
* library APIの事前条件違反

compilerが偶然期待どおり動くことをcorrectnessの根拠にしない。

implementation-defined、unspecified、undefinedの違いを区別し、implementation-defined behaviorへ依存する場合は対象platformとcompilerの契約を確認する。

## Preprocessor

* `#define`は条件compile、feature detection、Cで必要な定数・token操作、C / asm共有等、preprocessorである必要がある用途に使う。
* function-like macroより通常のfunctionまたは`static inline`で表現できる場合はそちらを優先する。
* function-like macroではargumentの複数評価、副作用、operator precedence、型安全性に注意する。
* macro parameterと展開式には必要な括弧を付ける。
* statement風macroが必要な場合はproject規約と既存patternに従い、制御フローへの副作用を明確にする。
* macro名はglobal namespaceを汚染するため、公開headerではproject prefix等の既存規約へ従う。
* 条件compileを通常のruntime logicの代替として過剰利用しない。

## Struct、Union、Enum

* `struct`はdataとそのinvariantが追跡できる責務単位として使う。
* 単なるfield集合と、lifecycleや状態遷移を持つobjectを区別する。
* initialization methodが複数存在する場合は、どのfieldが有効かを明確にする。
* paddingやlayoutをserialization、disk format、network protocolへ暗黙利用しない。
* ABIやhardwareでlayoutが契約となる場合は、alignment、padding、endianness、compiler extensionの要否を確認する。
* `union`によるtype punningは、C標準、compiler保証、project方針を確認する。
* enumのunderlying representationやsizeをportableに固定されていると仮定しない。
* stateを整数magic valueで表現するより、意味のあるenumを優先する。ただしABI、protocol、hardware registerの数値契約は維持する。

## Project側で決める事項

本Skillでは次を断定しない。

* freestanding / hosted
* C11 / C17 / C23等の実際のlanguage standard
* libcやstandard libraryの利用範囲
* malloc等のdynamic allocation可否
* public / internal symbolのprefixと命名
* typedefの利用方針
* opaque structの利用範囲
* `goto`、compiler extension、attributeの許容範囲
* integer型、size型、error型のproject固有policy
* thread / interrupt / signal safety
* hardware register accessの表現方法
* packed structやbit-fieldの利用方針
* directory構成とABI headerの配置
* formatter、compiler、warning policy

## 差分の作り方

* 変更対象の周辺で、命名、ownership、lifetime、error処理、comment粒度、include順を確認する。
* 実装前に、公開契約、ABI、buffer size、resource lifetime、hardware / OS / protocol制約への影響範囲を確認する。
* functionを変更した場合は、success pathだけでなく各error pathとcleanup pathを確認する。
* pointer、size、integer conversionを変更した場合は、境界値とfailure caseを確認する。
* project全体の整形、広範囲rename、unrelated cleanupを機能変更へ混ぜない。
* 既存違反を、この作業と無関係に一括修正しない。
* 新しい公開契約を作る場合は、project docsとtestへ反映する必要性を確認する。
* reviewでは、何が問題か、なぜ問題か、どう直すかを分けて示す。
