# AI CLI Installation Notes

Last updated: 2026-08-23 JST

現在使用しているAI coding CLIの導入経路と更新方法。

| CLI | 導入経路 | Command |
| --- | --- | --- |
| Codex | npm global | `codex` |
| Claude Code | 公式native installer | `claude` |
| Grok | npm global | `grok` |
| Antigravity CLI | 公式installer + local wrapper | `agy` |

## Codex CLI

npm globalで導入。

```bash
npm install -g @openai/codex@latest
```

現在の配置:

```text
~/.local/npm-global/bin/codex
```

更新:

```bash
codex update
```

## Claude Code

以前はnpm版を使用していたが、現在は公式native installer版。

導入 / 再導入:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

現在の配置:

```text
~/.local/bin/claude
  -> ~/.local/share/claude/versions/<version>
```

更新:

```bash
claude update
```

## Grok CLI

npm globalで導入。

```bash
npm install -g @xai-official/grok@latest
```

現在の配置:

```text
~/.local/npm-global/bin/grok
```

更新:

```bash
grok update
```

## Antigravity CLI

以前はAURの`antigravity-cli`を使用していたが、現在は公式installerによる
user-local installへ移行済み。

実体:

```text
~/.local/opt/antigravity-cli/bin/agy
```

user-facing commandはdotfiles管理のwrapper:

```text
~/.local/bin/agy
  -> ~/dotfiles/stow/scripts/.local/bin/agy
```

wrapper:

```sh
#!/bin/sh
exec "$HOME/.local/opt/antigravity-cli/bin/agy" "$@"
```

公式installer:

```bash
curl -fsSLO https://antigravity.google/cli/install.sh
```

現在の構成では`~/.local/opt/antigravity-cli/bin/`へ配置する。

更新:

```bash
agy update
```

## 一括更新

dotfiles:

```text
~/dotfiles/stow/scripts/.local/bin/update-ai-cli.sh
```

対象:

```text
codex
claude
grok
agy
```

各CLIの`<command> update`を順番に実行する。
