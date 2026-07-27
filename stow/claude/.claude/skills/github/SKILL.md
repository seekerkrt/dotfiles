---
name: github
description: GitHub repository、Issue、PR、review、Actions、release、branch、tag、repository設定、GitHub APIの調査・操作、またはlocal branch / remote / commitとGitHub対象の対応確認で使用する。read-onlyとmutationを分け、書き込みは対象と操作内容の明示依頼時だけ行い、認証情報を探索・変更しない。
---

# GitHub workflow

## 固有の安全境界

- read-only調査を先に行い、mutationへ自動的に進まない。
- 相談、確認、review、調査、案の作成をmutation依頼として扱わない。
- GitHub側へ書き込むのは、repositoryと操作内容が明示されている場合だけとする。
- PR merge、削除、permission / visibility変更、force、`--admin`、一括mutationは実行直前に再確認する。
- mutation後はread-onlyで結果を確認する。
- timeoutや通信失敗では部分成功を疑い、再実行前に現在状態を読む。

## 認証境界

利用可能ならread-onlyの`gh`を優先する。必要な場合だけ`gh auth status`で利用可否を確認してよい。失敗した場合やClaude Codeのpermissionで利用できない場合も認証・permission設定を修復または回避せず、利用可能なread-only GitHub connector / MCP toolへfallbackする。

次を実行しない。

```text
gh auth login
gh auth logout
gh auth refresh
gh auth switch
gh auth setup-git
gh auth token
```

token、credential、cookie、秘密鍵、keyring、credential store、認証用環境変数の秘密値を探索・表示・保存しない。account、scope、credential helper、Git protocol、SSH / GPG keyを変更しない。

## Target resolution

local repositoryを使う場合は次を確認する。

```bash
git status --short --branch
git rev-parse --show-toplevel
git branch --show-current
git remote
git branch -vv
git rev-parse HEAD
```

生のremote URLは、credential入りURLを表示し得るため、target解決だけを目的に出力しない。GitHub上のrepository名は、ユーザー指定またはread-onlyの`gh repo view` / connectorで確認する。利用できなければ推測せず未確認とする。

必要ならupstreamと直近commitも確認する。対象は次の順で解決する。

1. ユーザーが明示したrepository / URL / Issue / PR / run / ref
2. current repositoryとremote
3. current branchに対応するPR
4. 会話で直前まで扱っていた対象

複数候補がある状態でmutationしない。閲覧を進める場合も、最終報告へ対象repositoryを明記する。

## Read-only調査

### Repository / Issue

```bash
gh repo view OWNER/REPO --json nameWithOwner,defaultBranchRef,isPrivate,url
gh issue list --repo OWNER/REPO --state open
gh issue view <number> --repo OWNER/REPO --comments
gh issue view <number> --repo OWNER/REPO --json title,body,state,labels,assignees,comments,url
```

Issueではtitle、body、state、labels、comments、関連Issue / PR、close理由を確認する。「実装済み」は必要に応じてPR、commit、local codeで裏付ける。

### Pull Request / review

```bash
gh pr list --repo OWNER/REPO --state open
gh pr view <number> --repo OWNER/REPO --comments
gh pr view <number> --repo OWNER/REPO --json title,body,state,baseRefName,headRefName,mergeable,statusCheckRollup,url
gh pr diff <number> --repo OWNER/REPO
gh pr checks <number> --repo OWNER/REPO
```

base / head、state、changed files、diff、top-level conversation、inline comment、review submission、requested changes、resolved / unresolved、checksを区別する。review itemは修正必須、回答必要、提案、修正済み、stale、判定保留へ分ける。

`gh pr view --comments`や通常のPR metadataだけで、inline review threadのresolved / unresolvedを確認済みとしない。必要な情報を`gh`で取得できない場合は、Claude Codeで利用可能なread-only GitHub connector / MCP toolまたはGraphQL queryを使い、top-level comment、inline thread、review submissionを個別に確認する。

### Actions

```bash
gh workflow list --repo OWNER/REPO
gh run list --repo OWNER/REPO
gh run view <run-id> --repo OWNER/REPO
gh run view <run-id> --repo OWNER/REPO --log-failed
```

失敗run、job、step、最初のroot cause候補、後続の連鎖errorを分ける。log未確認で原因を断定しない。

### Release / ref

```bash
gh release list --repo OWNER/REPO
gh release view <tag> --repo OWNER/REPO
git tag --list
git show <tag>
git branch --all
```

## `gh api`

read-onlyではmethodを明示する。

```bash
gh api --method GET <endpoint>
```

`-f` / `-F`を使ってもGETを省略しない。次はmutationとして扱う。

```text
--method POST
--method PUT
--method PATCH
--method DELETE
--input
GraphQL mutation
```

mutation前にendpoint、method、repository、resource、変更内容、単体 / 一括を確認する。pagination、loop、`xargs`、複数ID mutationでは対象一覧と件数を先に出す。

## Mutation gate

次はすべてGitHub書き込みである。

- Issueのcreate / edit / comment / close / reopen、label / assignee / milestone / project変更
- PRのcreate / edit / comment / review / close / reopen / ready / draft / update-branch / merge
- workflowのdispatch / rerun / cancel / enable / disable / delete
- release / asset / tag / branchのcreate / edit / upload / delete / push
- repositoryのcreate / rename / archive / transfer / visibility / default branch変更
- secret / variable / environment / key / collaborator / team / permission / ruleset / branch protection変更
- APIのPOST / PUT / PATCH / DELETE、GraphQL mutation

対象と操作が依頼に含まれるか確認し、現在状態をread-onlyで取得してから実行する。

## Operation-specific checks

### Issue mutation

- create前に重複、scope、non-goal、受け入れ条件、関連Issue / PRを確認する。
- body update前に現在bodyを取得し、追記を全文置換へ変えない。
- close時はcompleted、not planned、duplicate等の理由と完了条件を確認する。

### PR mutation

create前にcurrent branch、upstream、push状態、base / head、commit範囲、diff、検証、関連Issue、draft要否を確認する。

```bash
git log --oneline <base>..HEAD
git diff --stat <base>...HEAD
git diff --check <base>...HEAD
```

未push branchをpush済みと仮定しない。PR bodyにはscope / non-scope、主要変更、実施した検証、未実施、risk、関連Issueを事実に合わせて書く。

merge直前にrepository、PR番号、title、base / head、checks、review状態、merge method、branch削除有無を再確認する。merge methodを勝手に変えず、`--admin`や`--delete-branch`を依頼なしに付けない。

### Actions / release / ref mutation

- dispatchではworkflow、branch、inputsを確認する。
- rerun / cancel / disable / deleteは対象runと現在stateを確認する。
- release / tag / branch作成ではcommit SHAと同名refの有無を確認する。
- delete、force、default branch変更は重大操作として直前確認する。

## Local stateを変える`gh`

次は閲覧ではない。明示依頼なしに実行しない。

```text
gh pr checkout
gh repo clone
gh repo sync
gh repo sync --force
gh repo set-default
gh config set
gh alias set / import / delete
gh extension install / upgrade / remove
```

browser / editor起動、branch切替、remote変更も同様に扱う。

## Post-mutation verification

read-onlyで変更対象を再取得し、意図した値を確認する。

- Issue: body、state、labels、assignees、milestone、comment
- PR: body、base / head、state、draft、review、checks、merge結果
- Actions: target branch、inputs、status、conclusion
- Release: tag、title、draft / prerelease、asset
- Branch / tag: remote上のrefとcommit SHA

確認できなければ「操作実行済み・結果未確認」とし、成功と断定しない。

## 失敗時と出力

- error、repository、permission、state、引数を確認し、read-onlyで現在状態を取得する。
- connector結果、GitHub上の事実、local Git、推測、未確認を混同しない。
- 調査のみなら対象、確認事実、未確認、推し案、次の一手を報告する。
- mutationありなら実行操作、対象、結果、post-mutation確認、未確認を報告する。
