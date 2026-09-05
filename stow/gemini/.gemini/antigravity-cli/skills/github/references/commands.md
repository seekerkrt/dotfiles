# GitHub command examples

安全境界、API分類、操作前後の確認は`../SKILL.md`を正とする。
必要なcommand例だけを参照し、この一覧を一括実行するpreflightやmutation許可として扱わない。

## Target resolution

```bash
git status --short --branch
git rev-parse --show-toplevel
git branch --show-current
git remote
git branch -vv
git rev-parse HEAD
```

## Repository / Issue

```bash
gh repo view OWNER/REPO --json nameWithOwner,defaultBranchRef,isPrivate,url
gh issue list --repo OWNER/REPO --state open
gh issue view <number> --repo OWNER/REPO --comments
gh issue view <number> --repo OWNER/REPO --json \
  title,body,state,labels,assignees,comments,url
```

## Pull Request / review

```bash
gh pr list --repo OWNER/REPO --state open
gh pr view <number> --repo OWNER/REPO --comments
gh pr view <number> --repo OWNER/REPO --json \
  title,body,state,baseRefName,headRefName,mergeable,statusCheckRollup,url
gh pr diff <number> --repo OWNER/REPO
gh pr checks <number> --repo OWNER/REPO
```

## Actions

```bash
gh workflow list --repo OWNER/REPO
gh run list --repo OWNER/REPO
gh run view <run-id> --repo OWNER/REPO
gh run view <run-id> --repo OWNER/REPO --log-failed
```

## Release / ref

```bash
gh release list --repo OWNER/REPO
gh release view <tag> --repo OWNER/REPO
git tag --list
git show <tag>
git branch --all
```

## PR mutationのlocal確認

```bash
git log --oneline <base>..HEAD
git diff --stat <base>...HEAD
git diff --check <base>...HEAD
```
