---
name: github
description: >-
  GitHub repository、Issue、PR、Actions、release、branch、tagをghで安全に
  調査・操作する。ghの存在と認証を実行時確認し、利用不能時はfail closedにする。
---

# GitHub作業

## 目的

GitHub上の対象とローカルrepositoryを対応させ、read-only調査とwriteを分離する。
このSkillは対象解決、`gh`の利用可否、操作境界、結果確認を担当する。AGYの
permission prompt自体は組み込みのpermission契約に従う。

## 使用する場面

- repository、Issue、PR、review、commentの確認・操作
- Actionsのworkflow、run、job、logの確認・操作
- release、asset、tag、branchの確認・操作
- GitHub APIが必要な調査
- local branch、remote、commitとGitHub対象の対応確認

ローカルGitだけで完結する確認では、不要なGitHub接続を行わない。

## 開始時確認

最初にlocal contextを確認する。

~~~bash
git status --short --branch
git remote -v
git rev-parse --show-toplevel
git branch --show-current
git rev-parse HEAD
~~~

必要な場合だけupstreamと直近commitも確認する。

~~~bash
git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'
git log -1 --oneline
~~~

対象repositoryは次の順で解決する。

1. ユーザーが指定したrepository、URL、Issue番号、PR番号
2. 現在repositoryのremote
3. 現在branchに対応するPR
4. 直前の会話で明示されたrepository

複数候補がある場合は推測でwriteしない。GitHub repositoryを特定できたら、
`HOST`と`OWNER/REPO`を保持する。repository対応の`gh` subcommandには
`-R [HOST/]OWNER/REPO`を付ける。`gh repo view`はrepositoryを位置引数で渡す。

## gh runtime gate

GitHubへ接続する前に毎回確認する。

~~~bash
command -v gh
gh --version
gh auth status --hostname HOST
~~~

次のいずれかなら`gh unavailable`としてfail closedにする。

- `gh` executableがない。
- `gh auth status --hostname HOST`が未認証、token無効等を返す。
- 実行環境の制約により認証状態を確認できない。

fail closed時は次を守る。

- GitHubへのreadとwriteを実行しない。
- `curl`、browser automation、独自script等の別のremote accessへ切り替えない。
- `gh auth login`、logout、refresh、switch、token取得を行わない。
- credential、keyring、environment variable、cookie、秘密鍵を調べない。
- local Gitで確認できる事実だけを報告する。
- Issue、PR、Actions等のGitHub状態は「未確認」とする。

認証失敗はAGY permission不足ではない。approvalを追加して押し通そうとしない。

## AGY permissionとapproval

`gh`と認証が利用可能な状態で、予定した`gh` commandがAGYのpermissionにより
拒否された場合だけ、組み込み契約に従って最小権限を求める。

- exactな`OWNER/REPO`とresourceを使う。不要な`*`を使わない。
- `ask_permission`はActionを`custom`、Targetを次の形式にする。
- permissionやworkspace境界を回避するoptionは設定しない。
- 拒否された元commandを、承認後に一度だけ再実行する。
- 承認されない、または権限を狭く表現できない場合は`environment blocked`とする。
- permission回避のためにAGY設定、workspace、remote、credentialを変更しない。

~~~text
gh.read({"org":"OWNER","repo":"REPO"})
gh.read({"org":"OWNER","repo":"REPO","pr":"123"})
gh.create({"org":"OWNER","repo":"REPO","issue":"*"})
gh.update({"org":"OWNER","repo":"REPO","issue":"123"})
gh.approve({"org":"OWNER","repo":"REPO","pr":"123"})
gh.merge({"org":"OWNER","repo":"REPO","pr":"123"})
~~~

AGYのGitHub permission判定を保つため、`gh` commandの出力をpipeやredirectしない。
必要なfieldは`--json`や`--jq`でcommand自身に絞らせる。

## read-only調査

### Repository

~~~bash
gh repo view OWNER/REPO
gh repo view OWNER/REPO --json nameWithOwner,defaultBranchRef,isPrivate,url
~~~

### Issue

~~~bash
gh issue list -R OWNER/REPO --state open
gh issue view 123 -R OWNER/REPO --comments
gh issue view 123 -R OWNER/REPO --json title,body,state,labels,assignees,comments,url
~~~

### Pull Request

~~~bash
gh pr list -R OWNER/REPO --state open
gh pr view 123 -R OWNER/REPO --comments
gh pr view 123 -R OWNER/REPO --json title,body,state,baseRefName,headRefName,mergeable,statusCheckRollup,url
gh pr diff 123 -R OWNER/REPO
gh pr checks 123 -R OWNER/REPO
~~~

### Actions・release

~~~bash
gh workflow list -R OWNER/REPO
gh run list -R OWNER/REPO
gh run view RUN_ID -R OWNER/REPO --log-failed
gh release list -R OWNER/REPO
gh release view TAG -R OWNER/REPO
~~~

Actionsでは失敗run、job、step、最初の根本原因候補、後続の連鎖errorを分ける。
logを取得できない場合は原因を断定しない。

## API

通常のsubcommandで取得できない情報だけ`gh api`を使う。read-onlyではmethodを
必ず明示し、endpoint内に`OWNER/REPO`を含める。

~~~bash
gh api --method GET repos/OWNER/REPO/issues
~~~

`-f`または`-F`を使う場合も`--method GET`を省略しない。
POST、PUT、PATCH、DELETE、`--input`、GraphQL mutationはwriteとして扱う。

## write境界

GitHub側の状態変更は、対象と操作内容がユーザー依頼に明示されている場合だけ行う。
相談、review、調査、「作るならどんな内容か」はwrite依頼ではない。

writeには次を含む。

- Issueのcreate、edit、comment、close、reopen、label等の変更
- PRのcreate、edit、comment、review、ready化、close、merge
- workflow dispatch、rerun、cancel、enable、disable、delete
- release、asset、tag、branchのcreate、edit、upload、delete、push
- repository設定、permission、ruleset、branch protectionの変更
- APIのPOST、PUT、PATCH、DELETEとGraphQL mutation

write前にrepository、resource、現在状態、実行command、影響を示す。必要な
AGY permissionは、最初の拒否後に最小scopeで求める。

## 重大操作

次は明示依頼があっても、実行直前に対象と内容を再確認する。

- PR mergeと`--admin`
- branch、tag、release、workflow runの削除
- repository delete、transfer、archive、visibility変更
- default branch、permission、secret、key、ruleset、branch protection変更
- workflow disable、run cancel
- force操作と複数対象の一括操作

確認項目はrepository、対象番号または名前、base/head、current state、checks、
実行操作、影響、復旧可能性である。`--delete-branch`、`--admin`、`--force`を
便宜で追加しない。

## local stateを変えるgh操作

次はGitHub閲覧ではないため、明示依頼なしに実行しない。

~~~text
gh pr checkout
gh repo clone
gh repo sync
gh repo set-default
gh config set
gh alias set
gh extension install
~~~

browserやeditorを開くoption、branch切り替え、remote変更も同様に扱う。

## 失敗と操作後確認

- timeoutや通信失敗後は、同じwriteを再実行する前にread-onlyで現在状態を確認する。
- partial successの可能性があれば、成功、失敗、未確認を分ける。
- permission拒否、認証失敗、network、GitHub API errorを混同しない。
- write後は対象をread-onlyで再取得し、意図したstateを確認する。
- 再取得できなければ「操作実行済み・結果未確認」とし、成功と断定しない。

## 最終報告

調査のみ:

~~~text
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
~~~

writeあり:

~~~text
実行した操作:
- ...

対象:
- repository / resource

結果:
- ...

read-only確認:
- ...

未確認:
- ...
~~~
