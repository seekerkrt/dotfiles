---
name: github
description: GitHub repository、Issue、PR、Actions、release、branch、tagを安全に調査・操作する。閲覧では利用可能ならghを優先し、認証変更や秘密情報の取得は行わない。
---

# GitHub作業Skill

## 目的

GitHub repository、Issue、Pull Request、Actions、release、branch、tag等を、安全かつ現在のローカル作業文脈と整合させながら調査・操作する。

このSkillでは次を重視する。

- ローカルrepositoryとGitHub側の対象を取り違えない
- 閲覧では利用可能なら`gh`を優先する
- `gh`が利用できなくても認証状態を変更しない
- 調査と書き込みを明確に分ける
- 書き込みはユーザーの明示依頼がある場合だけ行う
- 操作後はread-onlyで結果を確認する
- 不明な状態を推測で埋めない

---

## 使用条件

次の作業では、このSkillを使用する。

- GitHub repositoryの状態確認
- Issueの検索、閲覧、作成、更新、comment、close
- PRの検索、閲覧、diff確認、作成、更新、review、merge
- review commentやconversationの確認
- GitHub Actionsのworkflow、run、job、log確認
- release、asset、tag、branchの確認・操作
- GitHub APIによる情報取得
- repository設定やGitHub上のmetadata確認
- ローカルbranchとGitHub PRの対応確認

単なるローカルGit操作だけで完結する場合は、通常のGit運用ルールを優先する。

---

## 最重要ルール

- 日本語で報告する
- まず対象repository、branch、remote、working treeを確認する
- GitHub閲覧では、利用可能なら`gh`のread-only操作を優先する
- `gh`が失敗しても、認証を直そうとしない
- token、credential、cookie、秘密鍵を探索・表示・保存しない
- GitHub側への書き込みは、対象と操作内容の明示依頼がある場合だけ行う
- PR merge、削除、permission変更、force操作等は実行直前に再確認する
- 操作後は可能な範囲でread-only確認を行う
- 確認できなかった内容は「未確認」と明記する
- 一般論ではなく、対象repositoryの具体的なIssue、PR、commit、branch、workflowに対応させる

---

## 作業開始時の確認

GitHub作業を始める前に、可能な範囲で次を確認する。

```bash
git status --short --branch
git remote -v
git rev-parse --show-toplevel
git branch --show-current
```

必要に応じて次も確認する。

```bash
git log -1 --oneline
git rev-parse HEAD
git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
```

確認する内容:

- repository root
- 現在branch
- working treeの未コミット変更
- `origin`等のremote URL
- upstream branch
- 現在HEAD
- ユーザーが指定したrepository / Issue / PRとの一致

working treeに未コミット変更がある場合、それをユーザーの作業として尊重する。

GitHub閲覧のためだけに、branch切り替え、stash、restore、reset等を行わない。

---

## 対象repositoryの解決

対象repositoryは次の優先順位で解決する。

1. ユーザーが明示したrepository、URL、Issue番号、PR番号
2. 現在のローカルrepositoryとremote
3. 現在branchに対応するPR
4. 会話内で直前まで扱っていたrepository

複数repositoryが候補になる場合は、推測で書き込みを行わない。

read-only調査では、候補を絞れる場合は調査を進めてよいが、結果には対象repositoryを明記する。

書き込み時に対象が曖昧な場合は、repository名またはURLを確認する。

---

## `gh`利用方針

GitHub上の情報を確認する場合は、`gh`が利用可能なら優先する。

理由:

- 現在のrepository / remoteと対応しやすい
- PR、Issue、Actionsの構造化情報を取得できる
- private repositoryにも既存認証の範囲でアクセスできる
- Web検索よりローカル作業文脈と揃えやすい

ただし、`gh`の利用可否を確認するために認証状態を変更してはならない。

### 最初の確認

必要な場合のみ、次を使ってよい。

```bash
gh auth status
```

`gh auth status`が失敗した場合、または `gh` がBash allow/denylistでブロックされている場合:

- `gh auth login`しない
- `gh auth logout`しない
- `gh auth refresh`しない
- tokenを探さない
- keyringやcredential storeを調べない
- ユーザーへ再ログインを強制しない
- denylistを回避しようとしない
- ローカルの `git` で確認できる範囲に留める
- GitHub側を確認できない場合は「未確認」と報告する

---

## 認証・秘密情報に関する禁止事項

この環境では、明示依頼の有無にかかわらず、次を実行しない。

```text
gh auth login
gh auth logout
gh auth refresh
gh auth switch
gh auth setup-git
gh auth token
```

次も禁止する。

- `GH_TOKEN`の値を表示する
- `GITHUB_TOKEN`の値を表示する
- `GH_ENTERPRISE_TOKEN`の値を表示する
- GitHub認証用環境変数を列挙して秘密値を読む
- token、credential、cookie、秘密鍵をファイルから探す
- keyring、credential store、password storeを探索する
- GitHub tokenを標準出力やログへ出す
- tokenを一時ファイルへ保存する
- active accountを変更する
- 認証scopeを変更する
- Git credential helperを変更する
- Git protocol設定を変更する
- SSH keyやGPG keyを追加・削除する
- 認証失敗を直す目的で設定を書き換える

通常端末側では認証が正常な場合があるため、この実行環境内から認証状態を修復しようとしない。

---

## read-onlyで使用してよい主な操作

### Repository

```bash
gh repo view
gh repo view OWNER/REPO
gh repo view --json nameWithOwner,defaultBranchRef,isPrivate,url
```

### Issue

```bash
gh issue list
gh issue list --state open
gh issue view <number>
gh issue view <number> --comments
gh issue view <number> --json title,body,state,labels,assignees,comments,url
```

### Pull Request

```bash
gh pr list
gh pr list --state open
gh pr view <number>
gh pr view <number> --comments
gh pr view <number> --json title,body,state,baseRefName,headRefName,mergeable,statusCheckRollup,url
gh pr diff <number>
gh pr checks <number>
```

現在branchのPRを確認する場合:

```bash
gh pr view
```

ただし、現在branchにPRがない場合は失敗するため、失敗を異常と断定しない。

### Actions

```bash
gh workflow list
gh workflow view <workflow>
gh run list
gh run view <run-id>
gh run view <run-id> --log
gh run view <run-id> --log-failed
```

### Release

```bash
gh release list
gh release view <tag>
```

### API

read-only用途では必ずmethodを明示する。

```bash
gh api --method GET <endpoint>
```

---

## read-only調査の進め方

### Issue調査

1. Issueのtitle、body、state、labels、commentsを確認する
2. 関連Issue / PRリンクを確認する
3. close済みの場合はclose理由を確認する
4. 実装済みと書かれている内容を、必要に応じてPRやcommitで裏付ける
5. docsと実装の食い違いがある場合は分けて報告する

報告時は次を分ける。

- GitHub上で確認できた事実
- ローカルコードで確認できた事実
- 推測
- 未確認点
- 次の一手

### PR調査

1. base / head branchを確認する
2. title、body、state、merge状態を確認する
3. changed files / diffを確認する
4. review、comment、requested changesを確認する
5. checks / Actions結果を確認する
6. 必要に応じて関連Issueを確認する
7. ローカルbranchとPR headが一致しているか確認する

PRの状態を、titleや一覧表示だけで判断しない。

### Review comment調査

- top-level conversation
- inline review comment
- review submission
- requested changes
- resolved / unresolved

を混同しない。

何がactionableかを整理する場合は、次を分ける。

- 修正必須
- 質問への回答が必要
- 提案のみ
- 既に修正済み
- stale / outdated
- 判定保留

### Actions / CI調査

1. 失敗したworkflow runを特定する
2. jobを特定する
3. failure stepを確認する
4. logから最初の根本原因候補を探す
5. 後続の連鎖エラーと区別する
6. ローカル再現手順があるか確認する
7. workflow設定そのものの問題か、コードの問題かを分ける

Actions logを確認できない場合、CI原因を推測で断定しない。

---

## `gh`が使えない場合の扱い

この実行環境には、`gh`以外にGitHub側を直接参照できる代替手段（外部connector等）が用意されていないことが多い。`gh`が利用できない、または必要情報を取得できない場合は次を守る。

- ローカルの`git`で確認できる範囲（commit、branch、tag、diff等）はそちらで代替する
- GitHub側でしか分からない情報（Issue本文、PRのreview状態、Actions結果等）は「未確認」として報告する
- 未確認情報を推測で埋めない
- `gh`失敗後に、認証変更や設定変更で再試行しようとしない
- 必要であれば、ユーザー自身がブラウザ等でGitHub側を確認できる旨を伝える

---

## GitHub側への書き込み

GitHub側の状態を変更する操作は、ユーザーが対象と操作内容を明示した場合だけ行う。

### 書き込み依頼として扱える例

- 「Issueを立てて」
- 「このIssueにコメントして」
- 「PRを作って」
- 「PR本文を更新して」
- 「ラベルを付けて」
- 「このPRをマージして」
- 「releaseを作って」
- 「workflowを再実行して」

### 書き込み依頼として扱わない例

- 「どう思う？」
- 「確認して」
- 「調べて」
- 「レビューして」
- 「PR作るならどんな内容？」
- 「Issueにしたほうがいい？」
- 「マージできそう？」

提案や相談だけでは書き込まない。

---

## Issue操作

### Issue作成前

確認する。

- repository
- title
- body
- 重複Issueの有無
- 関連Issue
- label
- assignee
- milestone
- scope
- acceptance criteria
- 非目標

重複確認ではtitleの完全一致だけでなく、同じ問題領域や親Issueも確認する。

Issue本文では可能な範囲で次を含める。

- 背景
- 目的
- 現在確認できている事実
- 調査対象または変更範囲
- 非目標
- 受け入れ条件
- 関連Issue / PR
- 実装前調査が必要か
- PR分割候補

### Issue更新

既存bodyを置換する場合は、現在のbodyを先に取得する。

ユーザーが「追記」と言っている場合、意図せず全文置換しない。

commentで残すべき経過と、bodyへ統合すべき仕様を区別する。

### Issue close

close理由を確認する。

- completed
- not planned
- duplicate

実装が未完了なのにcompletedでcloseしない。

関連PRがmergeされたことだけで自動的に完全完了と断定しない。

---

## PR操作

### PR作成前

確認する。

- repository
- current branch
- upstream
- working tree
- branchがpush済みか
- base branch
- head branch
- commit範囲
- diff
- tests
- 関連Issue
- draftにするか

PR作成前に可能な範囲で次を確認する。

```bash
git status --short --branch
git log --oneline <base>..HEAD
git diff --stat <base>...HEAD
git diff --check <base>...HEAD
```

pushされていないbranchを、push済みと仮定しない。

### PR本文

可能な範囲で次を含める。

- 概要
- 背景
- 変更内容
- 設計判断
- 検証
- 影響範囲
- 非目標
- 関連Issue
- follow-up
- reviewer向け注意点

確認していないtestを実行済みと書かない。

### PR review

review時は次を分ける。

- blocker
- correctness
- safety
- maintainability
- test不足
- docs不足
- optional suggestion
- question

指摘には可能な範囲で次を含める。

- 何が問題か
- なぜ問題か
- どこで起きるか
- どう直すか
- confidence
- 実害または将来リスク

### PR merge

PR mergeは重大操作として扱う。

実行直前に確認する。

- repository
- PR番号
- title
- base branch
- head branch
- checks
- review状態
- merge method
- branch削除の有無
- userが本当にmergeを依頼しているか

merge methodを勝手に変更しない。

repository運用でMerge commit方式が指定されている場合は、それを優先する。

`--admin`による保護回避は、ユーザーから明示的に依頼されない限り使用しない。

`--delete-branch`を勝手に付けない。

---

## Actions操作

次の操作はGitHub側への書き込みとして扱う。

- workflow dispatch
- rerun
- rerun failed jobs
- cancel
- enable
- disable
- run delete

ユーザーの明示依頼なしに実行しない。

特にworkflow disable、run cancel、run deleteは実行直前に対象を再確認する。

workflow dispatch時は入力parameterと対象branchを確認する。

---

## Release / tag / branch操作

### read-only

次は確認に使用してよい。

```bash
gh release list
gh release view <tag>
git tag --list
git show <tag>
git ls-remote --tags <remote>
git branch --all
```

### 書き込み

次は明示依頼が必要。

- release create / edit / delete
- asset upload / delete
- tag create / delete / push
- branch create / delete
- default branch変更
- branch protection変更
- ruleset変更

tagやreleaseを作成する前に、commit SHAと対象versionを確認する。

同名tag / releaseが既に存在しないか確認する。

release削除やtag削除は重大操作として再確認する。

---

## `gh api`の安全ルール

`gh api`はread-onlyとmutationの両方に使えるため、通常の`gh`サブコマンドより慎重に扱う。

### read-only

必ずmethodを明示する。

```bash
gh api --method GET <endpoint>
```

parameterを渡す場合もGETを明示する。

```bash
gh api --method GET \
  -f state='open' \
  repos/OWNER/REPO/issues
```

`-f` / `-F`を使うと、methodを省略した場合にPOST扱いになる可能性があるため、read-only調査ではmethodを省略しない。

### 書き込み

次はユーザーの明示依頼なしに使用しない。

```text
--method POST
--method PUT
--method PATCH
--method DELETE
--input
```

GraphQLの`mutation`も書き込みとして扱う。

書き込みAPI実行前に、次を明示する。

- endpoint
- method
- repository
- resource
- 変更内容
- 単体操作か一括操作か

### 一括操作

pagination、shell loop、`xargs`、複数IDを組み合わせたmutationは、対象件数と対象一覧を確認してから行う。

dry-run相当がない操作では、最初に1件だけ試す必要があるか検討する。

---

## ローカル状態を変更する`gh`操作

次はGitHub閲覧ではなく、ローカル状態や設定を変更するため、明示依頼なしに実行しない。

```text
gh pr checkout
gh repo clone
gh repo sync
gh repo sync --force
gh repo set-default
gh config set
gh alias set
gh alias import
gh alias delete
gh extension install
gh extension upgrade
gh extension remove
```

次も同様に扱う。

- browserを開く`--web`
- editorを開く操作
- 未確認のextension実行
- remote変更
- branch切り替え
- checkout
- credential helper変更
- protocol設定変更

`gh repo sync --force`は特に危険なため、通常は使用しない。

これらのコマンドはBash allow/denylistの対象になっている場合がある。denylistで止まっている場合は、それを回避しようとせず、必要ならユーザーに許可を依頼する。

---

## 重大操作

次は、ユーザーの依頼があっても実行直前に対象と内容を再確認する。

- PR merge
- branch削除
- tag削除
- release削除
- repository delete
- repository transfer
- repository archive / unarchive
- repository visibility変更
- default branch変更
- secret変更
- key変更
- collaborator / team / permission変更
- ruleset変更
- branch protection変更
- workflow disable
- workflow run cancel / delete
- forceを伴う更新
- 複数対象の一括変更
- 複数対象の一括削除
- `--admin`による保護回避

再確認時は最低限、次を示す。

- repository
- 対象番号または名前
- 現在状態
- 実行する操作
- 影響
- 戻せるかどうか

---

## 書き込み後の確認

GitHub側への書き込みを行った場合、可能な範囲で直後にread-only確認する。

### Issue

- title
- body
- state
- labels
- assignees
- milestone
- comment

### PR

- title
- body
- base / head
- state
- draft / ready
- merge状態
- review
- checks
- comment

### Actions

- workflow runが作成されたか
- target branch
- inputs
- status
- conclusion

### Release

- tag
- title
- body
- draft / prerelease
- asset

### Branch / tag

- remoteに存在するか
- 対象commit SHA
- 意図したrefか

確認できない場合は、成功したと断定せず「操作実行済み・結果未確認」と報告する。

---

## 失敗時の扱い

コマンドやGitHub操作が失敗した場合:

1. error messageを確認する
2. 対象repository / permission / state /引数を確認する
3. read-onlyで現在状態を確認する
4. 同じ書き込みを無条件に繰り返さない
5. 認証変更で直そうとしない
6. 部分成功の可能性を確認する
7. 何が成功し、何が失敗したかを分けて報告する

timeoutや通信失敗時は、GitHub側で操作が成立している可能性がある。

再実行前にread-only確認する。

---

## 報告形式

GitHub作業後は、必要に応じて次の形で報告する。

### 調査のみ

```text
現状:
- repository:
- branch:
- Issue / PR:
- state:

確認できた事実:
- ...

未確認:
- ...

推し案:
- ...

次の一手:
- ...
```

### 書き込みあり

```text
実行した操作:
- ...

対象:
- repository:
- Issue / PR / branch / release:

結果:
- ...

確認:
- ...

未確認:
- ...
```

長い機械的な報告にせず、ユーザーが次の判断をしやすい情報を優先する。

---

## やってはいけない判断

- `gh`が失敗したので`gh auth login`する
- private repositoryが見えないのでtokenを探す
- Issue番号だけでrepositoryを推測して書き込む
- 「PR作ってもいい？」への返答前にPRを作る
- review依頼をmerge依頼として扱う
- merge済みという推測だけでIssueをcloseする
- Actions失敗原因をlogなしで断定する
- userの未コミット変更をstash / restoreしてPR checkoutする
- `gh api -f`をGETのつもりでmethod省略する
- 一括mutationを対象一覧確認なしで実行する
- operation timeout後に状態確認せず再実行する
- `--admin`や`--force`を便利だから使う
- 書き込み後の結果を確認せず成功扱いする
- `gh`がBash denylistで止まっているのを設定変更で回避する

---

## 迷ったとき

迷った場合は次を優先する。

1. ローカルrepositoryとbranchを確認する
2. read-onlyでGitHub状態を確認する
3. 事実と未確認点を分ける
4. まだ書き込まない
5. 最小の次の一手を1つ提案する
