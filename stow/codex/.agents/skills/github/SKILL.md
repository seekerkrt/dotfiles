---
name: github
description: GitHub repository、Issue、PR、Actions、release、branch、tagの調査・操作、ローカルbranchとの対応確認、GitHub API利用が必要な場面で使う。閲覧では利用可能ならghを優先し、認証変更や秘密情報の取得を行わず、書き込みは明示依頼がある場合だけ実行する。
---

# 目的

GitHub上の対象と現在のローカル作業文脈を対応させ、安全に調査・操作する。

調査と書き込みを分け、書き込み後や通信失敗時もread-onlyで現在状態を確認し、不明な状態を推測で埋めない。

# 使用条件

次の作業で使用する。

- repository、Issue、PR、review commentの検索・閲覧・操作
- Actionsのworkflow、run、job、logの確認・操作
- release、asset、tag、branchの確認・操作
- GitHub APIによる情報取得やmutation
- repository設定やGitHub上のmetadata確認
- ローカルbranch、remote、commitとGitHub上の対象の対応確認

ローカルGitだけで完結する作業には、通常のGit安全規則を優先する。

# 最重要ルール

- 日本語で報告する。
- まず対象repository、branch、remote、working treeを確認する。
- 閲覧では利用可能なら`gh`のread-only操作を優先する。
- `gh`が失敗しても認証を修復しない。
- token、credential、cookie、秘密鍵を探索・表示・保存しない。
- GitHub側への書き込みは、対象と操作内容の明示依頼がある場合だけ行う。
- 相談、レビュー、調査依頼を、書き込み依頼として扱わない。
- PR merge、削除、permission変更、force操作、`--admin`、一括操作は実行直前に再確認する。
- 書き込み後はread-onlyで結果を確認する。
- 確認できない内容は「未確認」と明記する。
- 一般論ではなく、対象repositoryの具体的なIssue、PR、commit、branch、workflowに対応させる。

# 開始時確認

可能な範囲で次を確認する。

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

- repository root、現在branch、working tree
- remote URL、upstream、現在HEAD
- ユーザーが指定したrepository / Issue / PRとの一致

未コミット変更はユーザーの作業として尊重する。閲覧のためだけにbranch切り替え、stash、restore、resetを行わない。

# 対象repositoryの解決

次の優先順で解決する。

1. ユーザーが明示したrepository、URL、Issue番号、PR番号
2. 現在のローカルrepositoryとremote
3. 現在branchに対応するPR
4. 会話内で直前まで扱っていたrepository

複数候補がある場合、推測で書き込まない。read-only調査を進められる場合も、報告に対象repositoryを明記する。

# 閲覧方針

GitHub閲覧では、利用可能なら`gh`を優先する。必要な場合のみ次で現在の認証可否を確認してよい。

```bash
gh auth status
```

失敗した場合は認証を変更せず、利用可能なGitHub連携機能へ切り替える。ローカルGit状態と連携機能の取得結果を混同せず、取得できない情報は「未確認」とする。

## read-only操作例

### Repository

```bash
gh repo view
gh repo view OWNER/REPO
gh repo view --json nameWithOwner,defaultBranchRef,isPrivate,url
```

### Issue

```bash
gh issue list --state open
gh issue view <number> --comments
gh issue view <number> --json title,body,state,labels,assignees,comments,url
```

### Pull Request

```bash
gh pr list --state open
gh pr view <number> --comments
gh pr view <number> --json title,body,state,baseRefName,headRefName,mergeable,statusCheckRollup,url
gh pr diff <number>
gh pr checks <number>
```

現在branchのPRは `gh pr view` で確認できるが、PRがない場合の失敗を異常と断定しない。

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

read-onlyでは必ずmethodを明示する。

```bash
gh api --method GET <endpoint>
```

`-f` / `-F`を使う場合も省略しない。method省略によりPOST扱いになる可能性がある。

# 認証・秘密情報に関する常時禁止

明示依頼の有無にかかわらず、次を実行しない。

```text
gh auth login
gh auth logout
gh auth refresh
gh auth switch
gh auth setup-git
gh auth token
```

次も禁止する。

- `GH_TOKEN`、`GITHUB_TOKEN`、`GH_ENTERPRISE_TOKEN`等の秘密値の読み出し・表示
- 認証用環境変数の秘密値の列挙
- token、credential、cookie、秘密鍵の探索・表示・コピー・保存
- keyring、credential store、password storeの探索
- active accountや認証scopeの変更
- Git credential helperやGit protocol設定の変更
- SSH keyやGPG keyの追加・削除
- 認証失敗を修復するための設定変更
- ユーザーへの再ログイン要求

通常端末側で認証が正常な場合があるため、Codex環境内から認証を修復しない。

# 基本ワークフロー

1. ローカルrepository、branch、remote、working treeを確認する。
2. GitHub上の対象とローカル文脈が一致するか確認する。
3. `gh`またはGitHub連携機能でread-only調査する。
4. GitHub上の事実、ローカルコード上の事実、推測、未確認を分ける。
5. 書き込みが必要な場合は、対象と操作内容が明示依頼に含まれるか確認する。
6. 重大操作は実行直前に対象、現在状態、影響、復旧可能性を再確認する。
7. 書き込み後はread-onlyで結果を確認する。
8. timeoutや部分成功の可能性がある場合は、再実行前に現在状態を確認する。

# 対象別の調査

## Issue

1. title、body、state、labels、commentsを確認する。
2. 関連Issue / PRとclose理由を確認する。
3. 実装済みという記述を、必要に応じてPRやcommitで裏付ける。
4. GitHub上の事実、ローカルコード、推測、未確認、次の一手を分ける。

## Pull Request

1. base / head、title、body、state、merge状態を確認する。
2. changed files、diff、review、comment、requested changesを確認する。
3. checks、Actions、関連Issueを確認する。
4. ローカルbranchとPR headの対応を確認する。

一覧やtitleだけで状態を判断しない。top-level conversation、inline comment、review submission、requested changes、resolved / unresolvedを混同しない。

review commentは「修正必須」「回答必要」「提案のみ」「修正済み」「stale / outdated」「判定保留」に分ける。

## Actions / CI

1. 失敗したworkflow run、job、stepを特定する。
2. logから最初の根本原因候補を探し、後続の連鎖エラーと分ける。
3. ローカル再現手順の有無を確認する。
4. workflow設定、コード、環境の問題を分ける。

logを確認できない場合、原因を推測で断定しない。

# GitHub連携機能へのfallback

`gh`が利用できない、または必要情報を取得できない場合は、利用可能なGitHub連携機能を使用する。

- 対象repository、Issue番号、PR番号、branch、commitを可能な限り特定する。
- 連携機能の結果とローカルGit状態を混同しない。
- 書き込みは明示依頼時だけ行う。
- 取得できない情報は「未確認」とする。

`gh`失敗後に認証を変更して再試行しない。

# 書き込み境界

GitHub側の状態変更は、ユーザーが対象と操作内容を明示した場合だけ行う。

次はすべて書き込みとして扱う。

- Issueのcreate、edit、comment、close、reopenとlabel、assignee、milestone、project変更
- PRのcreate、edit、comment、close、reopen、review、ready / draft、update-branch、merge
- workflowのdispatch、rerun、cancel、enable、disable、delete
- release / asset / tag / branchの作成、編集、upload、delete、push
- repositoryの作成、rename、archive、delete、transfer、visibility、default branch変更
- secret、variable、environment、key、collaborator、team、permission、ruleset、branch protection変更
- GitHub APIのPOST / PUT / PATCH / DELETEとGraphQL mutation

書き込み依頼の例:

- 「Issueを立てて」「このIssueにコメントして」
- 「PRを作って」「PR本文を更新して」「このPRをマージして」
- 「releaseを作って」「workflowを再実行して」

書き込み依頼ではない例:

- 「どう思う？」「確認して」「調べて」「レビューして」
- 「PRを作るならどんな内容？」「Issueにしたほうがいい？」「マージできそう？」

# Issue操作

作成前にrepository、title、body、重複、関連Issue、label、assignee、milestone、scope、acceptance criteria、非目標を確認する。重複はtitleの完全一致だけでなく、同じ問題領域や親Issueも確認する。

本文には可能な範囲で背景、目的、確認済み事実、scope、非目標、受け入れ条件、関連Issue / PR、実装前調査、PR分割候補を含める。

更新前に現在bodyを取得し、「追記」を意図せず全文置換しない。commentで残す経過とbodyへ統合する仕様を分ける。

close時はcompleted、not planned、duplicate等の理由を確認する。未完了をcompletedにせず、関連PRのmergeだけで完全完了と断定しない。

# PR操作

作成前にrepository、current branch、upstream、working tree、push状態、base / head、commit範囲、diff、tests、関連Issue、draft要否を確認する。

```bash
git status --short --branch
git log --oneline <base>..HEAD
git diff --stat <base>...HEAD
git diff --check <base>...HEAD
```

pushされていないbranchをpush済みと仮定しない。PR本文には可能な範囲で概要、背景、変更内容、設計判断、検証、影響範囲、非目標、関連Issue、follow-up、reviewer向け注意点を含める。未実施testを書かない。

reviewではblocker、correctness、safety、maintainability、test不足、docs不足、optional suggestion、questionを分ける。指摘には問題、理由、発生箇所、修正方向、confidence、実害または将来リスクを含める。

PR mergeは重大操作として、実行直前にrepository、PR番号、title、base / head、checks、review状態、merge method、branch削除有無、明示依頼を再確認する。

- merge methodを勝手に変更しない。
- repository指定の方式を優先する。
- 明示依頼なしに`--admin`を使わない。
- `--delete-branch`を勝手に付けない。

# Actions操作

workflow dispatch、rerun、rerun failed jobs、cancel、enable、disable、run deleteは書き込みとして扱う。

明示依頼なしに実行しない。workflow disable、run cancel、run deleteは直前に再確認し、dispatchでは入力parameterと対象branchを確認する。

# Release / tag / branch操作

read-onlyでは次を使用してよい。

```bash
gh release list
gh release view <tag>
git tag --list
git show <tag>
git ls-remote --tags <remote>
git branch --all
```

release / asset / tag / branchの作成・編集・削除・push、default branch、branch protection、rulesetの変更には明示依頼が必要である。

作成前にcommit SHA、version、同名tag / releaseの有無を確認する。releaseやtagの削除は重大操作として再確認する。

# `gh api`の安全ルール

read-onlyでは、parameterを渡す場合もGETを明示する。

```bash
gh api --method GET \
  -f state='open' \
  repos/OWNER/REPO/issues
```

次は書き込みとして扱い、明示依頼なしに使用しない。

```text
--method POST
--method PUT
--method PATCH
--method DELETE
--input
GraphQL mutation
```

書き込み前にendpoint、method、repository、resource、変更内容、単体か一括かを明示する。

pagination、shell loop、`xargs`、複数IDのmutationは、対象件数と一覧を確認する。dry-run相当がなければ、最初に1件だけ試す必要があるか検討する。

# ローカル状態を変更する`gh`操作

次はGitHub閲覧ではないため、明示依頼なしに実行しない。

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

browserを開く`--web`、editor起動、未確認extension、remote変更、branch切り替え、checkout、credential helper変更、protocol変更も同様に扱う。`gh repo sync --force`は特に危険なため通常は使用しない。

# 重大操作

次は依頼があっても実行直前に再確認する。

- PR merge、`--admin`による保護回避
- branch / tag / release削除
- repository delete / transfer / archive / unarchive / visibility変更
- default branch変更
- secret / key / collaborator / team / permission変更
- ruleset / branch protection変更
- workflow disable、run cancel / delete
- forceを伴う更新
- 複数対象の一括変更・一括削除

再確認時はrepository、対象番号または名前、現在状態、実行操作、影響、復旧可能性を示す。

# 操作後確認

書き込み後は、操作対象をread-onlyで確認する。

- Issue: title、body、state、labels、assignees、milestone、comment
- PR: title、body、base / head、state、draft / ready、merge、review、checks、comment
- Actions: run作成、target branch、inputs、status、conclusion
- Release: tag、title、body、draft / prerelease、asset
- Branch / tag: remote上の存在、commit SHA、意図したref

確認できない場合は「操作実行済み・結果未確認」と報告し、成功と断定しない。

# 失敗時・未確認時の扱い

1. error message、repository、permission、state、引数を確認する。
2. read-onlyで現在状態を確認する。
3. 同じ書き込みを無条件に繰り返さない。
4. 認証変更で直そうとしない。
5. 部分成功を確認し、成功・失敗・未確認を分ける。

timeoutや通信失敗時は、GitHub側で成立している可能性がある。再実行前に現在状態を確認する。

# 禁止事項

- 認証変更や秘密情報探索
- repositoryを推測した書き込み
- 調査、相談、review依頼からの書き込み
- log未確認でのActions原因断定
- ユーザー変更をstash / restoreしてのPR checkout
- `gh api -f`をGETのつもりでmethod省略すること
- 対象一覧未確認の一括mutation
- timeout後に状態確認せず再実行すること
- 便利さを理由にした`--admin`や`--force`
- 書き込み後の確認なしに成功扱いすること

# 最終報告

調査のみ:

```text
現状:
- repository / branch / Issue・PR / state

確認できた事実:
- ...

未確認:
- ...

推し案:
- ...

次の一手:
- ...
```

書き込みあり:

```text
実行した操作:
- ...

対象:
- repository / Issue・PR・branch・release

結果:
- ...

read-only確認:
- ...

未確認:
- ...
```

長い機械的な報告にせず、ユーザーが次の判断をしやすい情報を優先する。
