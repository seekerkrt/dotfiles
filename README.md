# seekerkrt's Dotfiles

[日本語](#日本語) | [English](#english)

---

## 日本語

> [!CAUTION]
> **【重要】これは個人専用のバックアップリポジトリです**
> 本リポジトリは、作者の特定のハードウェアおよび環境
> （Arch Linux / Windows 11 デュアルブート）に依存した個人用設定です。
> 汎用テンプレートや、他人がそのまま導入するためのものではありません。
>
> 特にSecure Boot関連の設定やハードウェア固有のスクリプトは、
> そのまま実行すると最悪の場合**システムが起動しなくなる、
> あるいはデータが破損する恐れ（ランドマイン）**があります。
> 内容を十分に理解せずにコピー＆ペーストしたり、
> スクリプトを実行したりしないでください。

### 概要

このリポジトリは、作者（seekerkrt）の設定ファイルを管理・同期するためのものです。
GNU Stowによるホームディレクトリへの展開、自作systemd unit / drop-inの配置、
Secure Boot運用スクリプト、パッケージ一覧のバックアップなどを含みます。

本リポジトリはGitHubを本家として運用されており、GitLab上の同名リポジトリはバックアップミラーです。主な更新元はGitHubです。
また、秘密鍵やトークンなどの機密情報は管理対象外となっています。

### プロジェクトの主な構造

```text
.
├── stow/                     # GNU Stowで展開するユーザー設定
│   ├── alacritty/            # Alacritty設定
│   ├── antigravity/          # Antigravity IDE設定
│   ├── bash/                 # Bash設定
│   ├── btop/                 # btop設定
│   ├── cargo/                # Cargo設定
│   ├── ccache/               # ccache設定
│   ├── chrome/               # Chrome設定
│   ├── clang-format/         # clang-format設定
│   ├── claude/               # Claude Code設定（→ エージェント設定の参照先）
│   ├── codex/                # Codex設定（→ エージェント設定の参照先）
│   ├── conky/                # Conky設定
│   ├── copilot/              # GitHub Copilot指示
│   ├── editorconfig/         # EditorConfig設定
│   ├── emacs/                # Emacs設定
│   ├── env/                  # 環境変数設定
│   ├── fonts/                # フォント設定
│   ├── foot/                 # footターミナル設定
│   ├── gemini/               # Antigravity CLI設定（→ エージェント設定の参照先）
│   ├── git/                  # Git設定
│   ├── grok/                 # Grok設定（→ エージェント設定の参照先）
│   ├── hypr/                 # Hyprland設定
│   ├── kde/                  # KDE設定
│   ├── mako/                 # mako通知ツール設定
│   ├── markdownlint/         # markdownlint設定
│   ├── npm/                  # npm設定
│   ├── nvim/                 # Neovim設定
│   ├── scripts/              # 個人用スクリプト（agy / update-ai-cli.sh / sync-handoff など）
│   ├── sway/                 # Sway設定
│   ├── tmux/                 # tmux設定
│   ├── tmuxp/                # tmuxp設定
│   ├── vim/                  # Vim設定
│   ├── vscode/               # VS Code設定
│   ├── waybar/               # Waybar設定
│   ├── wezterm/              # WezTerm設定
│   ├── xorg/                 # X.Org設定
│   ├── yazi/                 # yaziファイラー設定
│   ├── zsh/                  # Zsh設定
│   └── zsh-functions/        # Zsh関数
├── systemd/                  # 自作systemd unit / drop-in（Stow管理対象外）
│   ├── system/               # → /etc/systemd/system/ へ配置
│   │   └── clamav-clamonacc.service.d/
│   │       └── override.conf
│   └── user/                 # → ~/.config/systemd/user/ へ配置
│       └── ssh-agent.service
├── system/secureboot/        # Secure Boot関連の設定とスクリプト
├── pkglist/                  # 明示インストール済みパッケージ一覧
├── vscode/                   # VS Code拡張一覧（Stow管理対象外）
├── sample/                   # システム設定ファイルのサンプル
├── docs/                     # 補助ドキュメント
│   └── AI-CODINGAGENTS-INSTALLATIONS.md  # AI CLIの導入経路と更新方法
├── github/                   # GitHub rulesetテンプレート（手動適用、Stow対象外）
│   └── rulesets/
│       ├── protect-main.json
│       ├── protect-main-develop.json
│       └── dotfiles-protect-main.json
├── apply-stow.sh             # Stowリンクを作成
├── remove-stow.sh            # Stowリンクを削除
├── setup-systemd-services.sh # systemd unit / drop-inの配置とenable状態の再現
├── save-pkglist.sh           # パッケージ一覧を保存
├── setup-pkglist.sh          # パッケージ一覧から導入
├── save-vscode-extensions-list.sh  # VS Code拡張一覧を保存
├── setup-vscode-extensions-list.sh # VS Code拡張一覧から導入
├── backup-ssh-allowlist.sh   # SSH鍵と設定を暗号化バックアップ
├── restore-ssh-allowlist.sh  # 暗号化したSSH鍵と設定を復元
├── backup-ssh-config.sh      # SSH設定のみを暗号化バックアップ
├── restore-ssh-config.sh     # 暗号化したSSH設定のみを復元
└── setup-system.sh           # システム側設定を配置
```

### GitHub rulesetテンプレート

`github/rulesets/` は GitHub の branch ruleset を手動適用するための JSON テンプレートです。
Stow 対象外で、リポジトリへ自動適用するスクリプトはありません。
`bypass_actors` は作者アカウント向けなので、他リポジトリへ流用する場合は書き換えてください。

| ファイル | 対象branch | 内容 |
| --- | --- | --- |
| `protect-main.json` | `main` | 削除禁止、non-fast-forward禁止、PR必須（承認0、未解決スレッドのresolve必須） |
| `protect-main-develop.json` | `main` と `develop` | 同上 |
| `dotfiles-protect-main.json` | `main` | 削除禁止のみ（ruleset名 `private-protect-main`） |

### コーディングエージェント設定の参照先

> [!IMPORTANT]
> **共通契約の正本は `stow/codex/.codex/AGENTS.md` の1つだけです。**
> `CLAUDE.md` は `@~/.codex/AGENTS.md` でCodex正本をimportし、
> `GEMINI.md` はそこからの一方向同期による移植版です。
> どちらもエージェント固有の差分だけを局所的に持ちます。
> 共通ルールを変更する場合は、必ずCodex正本を先に直してください。

各エージェントが実際に読むファイルと、このリポジトリ内での実体の対応は次のとおりです。

| エージェント | リポジトリ内の実体 | 実際の参照先 | 内容 |
| --- | --- | --- | --- |
| Codex | `stow/codex/.codex/AGENTS.md` | `~/.codex/AGENTS.md` | **共通契約の正本** |
| Codex | `stow/codex/.agents/skills/` | `~/.agents/skills/` | Skill 9種（directory symlink） |
| Codex | `stow/codex/.codex/config.toml` | `~/.codex/config.toml` | 常用デフォルト |
| Codex | `stow/codex/.codex/*.config.toml` | `~/.codex/` | モデル別プロファイル（astra / luna / sol / terra / spark / safe） |
| Codex | `stow/codex/.codex/config.toml.example` | `~/.codex/config.toml.example` | 最小構成の例 |
| Codex | `stow/codex/.codex/rules/` | `~/.codex/rules/` | prefix_rule（実ファイルcopy。現在は `default.rules`） |
| Claude Code | `stow/claude/.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Codex正本のimport＋固有差分 |
| Claude Code | `stow/claude/.claude/skills/` | `~/.claude/skills/` | Skill 9種 |
| Claude Code | `stow/claude/.claude/settings.json` | `~/.claude/settings.json` | 権限、モデル、hooks、プラグイン等 |
| Claude Code | `stow/claude/.claude/hooks/` | `~/.claude/hooks/` | Codex rulesをBash PreToolUseへ流用するゲート |
| Antigravity CLI | `stow/gemini/.gemini/GEMINI.md` | `~/.gemini/GEMINI.md` | Codex正本からの移植 |
| Antigravity CLI | `stow/gemini/.gemini/antigravity-cli/skills/` | `~/.gemini/antigravity-cli/skills/` | Skill 9種 |
| Antigravity CLI | `stow/gemini/.gemini/settings.json` | `~/.gemini/settings.json` | Gemini CLI設定 |
| Antigravity CLI | `stow/gemini/.gemini/antigravity-cli/settings.json` | `~/.gemini/antigravity-cli/settings.json` | Antigravity CLI設定 |
| Grok | `stow/grok/.grok/AGENTS.md` | `~/.grok/AGENTS.md` | Codex正本へのsymlink |
| Grok | `stow/grok/.grok/config.toml` | `~/.grok/config.toml` | CLI / UI / marketplace 設定（未配置時seed） |
| GitHub Copilot | `stow/copilot/.copilot/instructions/global.instructions.md` | `~/.copilot/instructions/global.instructions.md` | Codex正本への参照 |

SkillはCodex・Claude Code・Antigravity CLIの3エージェント共通で次の9種を配置しています。

```text
audit  commit-prep  cpp-conventions  github
handoff  handoff-inline  handoff-archive  issue-slice  verify
```

> [!NOTE]
> **Claude Codeだけは `verify` ではなく `verify-diff` という名前です。**
> `verify` が組み込みコマンドと衝突するため、意図的にリネームしています。
> 中身の契約は他エージェントの `verify` と同じです。

`issue-slice`はGitHub Issueまたは明示されたPR単位でscope / non-scopeを固定し、
既存の`audit`、`cpp-conventions`、`verify`（Claude Codeでは`verify-diff`）、
`commit-prep`、`github`、`handoff`へ必要な段階でroutingしながら、
最小実装と検証を進めてcommit前で停止するオーケストレータです。

長いtest、build、release-check、compiler、runtime、diff等の作業logは、
repositoryへ追加せず`~/handoff/<repo>/<scope>/`へtimestamp付きfilenameで保存します。
最終報告にはraw logを貼らず、pass / fail、保存path、重要な要点だけを記載します。
`~/handoff` を `~/PrivateDocs/handoff/` へ `*.md` / `*.txt` だけ同期するスクリプトは
`stow/scripts/.local/bin/sync-handoff` です（Stow展開後は `sync-handoff`）。

handoff系3種（`handoff` / `handoff-inline` / `handoff-archive`）の本文と、
`handoff/references/common.md`を3エージェントで一致させる運用です。
SKILL.mdのfront matterと、`handoff-inline`の共通reference参照パスはエージェント固有差分として許容します。

verificationの詳細workflowは`verify`（Claude Codeでは`verify-diff`）を正とし、
`issue-slice`はacceptance criteria・impact / riskを渡して必要な検証の完了を確認します。
`handoff`と`handoff-inline`は共通referenceを使い、inlineは通常保存のSKILL.mdを読む必要がありません。
`github/references/commands.md`はCLI例が必要な場合だけ参照し、安全境界は`github/SKILL.md`に残します。

supporting referenceは各Skill directory内に置き、同じStow treeで配布します。
CodexのSkill directory symlinkとClaudeの既存fold配置ではsource内の追加fileが参照可能になります。
Geminiの`--no-folding`配置では、新規reference追加後にStowを再適用してfile symlinkを作成します。
参照pathはsource側だけでなく、配置先からの解決も確認します。

> [!WARNING]
> **`gemini` パッケージは `--no-folding` です。**
> `~/.gemini` は実ディレクトリのまま残り、追跡対象（`GEMINI.md`、
> `settings.json`、`antigravity-cli/settings.json`、`skills/`）だけがfile symlinkになります。
> `history.jsonl`、`log/`、`conversations/`、`brain/` などの実行時データは
> ホーム側へ書き込まれます。古いfold配置向けの除外が `.gitignore` に残っています。
>
> **Grokの `config.toml` はfile symlinkではなく、未配置時だけcopyするseedです。**
> 既存のlive configはGrok自身が書き換えるため上書きしません。
> `~/.grok` は実ディレクトリのまま残り、`AGENTS.md` だけがfile symlinkです。
> Skill 9種の複製は `stow/grok` には置いていません。
> `auth.json`、`sessions/`、`logs/` などの実行時データはホーム側に残り、
> このリポジトリの追跡対象外です。

### AI CLIの導入経路と一括更新

各CLIの導入経路、現在の配置、更新コマンドは
`docs/AI-CODINGAGENTS-INSTALLATIONS.md` を正本とします。

| CLI | 導入経路 | Command |
| --- | --- | --- |
| Codex | npm global | `codex` |
| Claude Code | 公式native installer | `claude` |
| Grok | npm global | `grok` |
| Antigravity CLI | 公式installer + dotfiles管理のwrapper | `agy` |

4種をまとめて更新するスクリプトは `stow/scripts/.local/bin/update-ai-cli.sh` です。
Stow展開後は `~/.local/bin/update-ai-cli.sh` として実行できます。

```sh
update-ai-cli.sh
```

CLIごとにPATH上の実体と更新前後のversionを表示し、`<command> update` を
`codex` → `claude` → `grok` → `agy` の順で実行します。
PATHに無いCLIはSKIP扱いで中断せず、1つでも失敗した場合は終了コード1を返します。

### 主要スクリプトの使い方

新規Arch環境での初期構築は、各スクリプトの責務に沿って次の順で実行します。

1. パッケージの導入: `./setup-pkglist.sh`
2. $HOME側設定の適用: `./apply-stow.sh`
3. システム側（Secure Boot）設定の配置: `sudo ./setup-system.sh`
4. systemd unit / drop-inの配置とenable: `./setup-systemd-services.sh --apply`
5. 必要に応じてSSH設定の復元: `./restore-ssh-config.sh BACKUP_DIR`
   （鍵も含める場合は `./restore-ssh-allowlist.sh BACKUP_DIR`）
6. 必要に応じてVS Code拡張の導入: `./setup-vscode-extensions-list.sh`

全部をまとめて実行するbootstrapスクリプトはありません。上記を個別に実行します。

#### 1. ドットファイルの適用・同期

ホームディレクトリ（$HOME）に設定ファイルのシンボリックリンクを展開します。

```sh
./apply-stow.sh
```

（`vscode` / `gemini` / `antigravity` / `grok` パッケージ全体と、
`codex` パッケージの `.codex` subtreeには `--no-folding` が適用されます。
Codex Skillは `~/.agents/skills/<skill>` のdirectory symlinkとして展開されます。
Codexの `~/.codex/rules/*.rules` はStow symlinkではなく、
`apply-stow.sh` がリポジトリ側を実ファイルとしてcopyします（既存fileは上書き）。
`remove-stow.sh` は、リポジトリ側と内容が一致するcopyだけを削除し、
配置後に変更されたrulesは残します。
Grokの `config.toml` はStow対象外で、未配置時だけ実ファイルとしてseedされます。）

> [!IMPORTANT]
> **systemd unit / drop-in / enable状態はStowの管理対象外です。**
> これらは `systemd/` と `setup-systemd-services.sh` が管理元です。
> `apply-stow.sh` / `remove-stow.sh` は旧パッケージ名 `systemd-user` を
> `SKIP_PACKAGES` として除外しています。パッケージ自体は削除済みで、
> この指定は誤ってStow管理へ戻さないためのガードとして残しています。
> Stowが同じパスへsymlinkを張ると、setupスクリプトが配置した実ファイルと
> conflictするためです。

#### 2. パッケージリストとVS Code拡張一覧の保存と導入

普段インストールしているパッケージの一覧を管理します。
・リストの保存（現在の状態を保存）:

```sh
./save-pkglist.sh
```

・パッケージの導入（クリーンインストール時など）:

```sh
./setup-pkglist.sh
```

（自動的に公式パッケージは pacman、AURパッケージは yay または paru を検出して
--needed でインストールします）

VS Code拡張も同様に一覧で管理します。
・拡張一覧の保存:

```sh
./save-vscode-extensions-list.sh
```

・拡張の導入:

```sh
./setup-vscode-extensions-list.sh
```

保存先は `$DOTFILES/vscode/extensions-list.txt` です。
`$DOTFILES` が未設定のときは `$HOME/dotfiles` を使います。
導入側は既に入っている拡張をスキップします。

#### 3. SSH設定のバックアップと復元

秘密鍵を含むため、リポジトリにコミットしたくない ~/.ssh 以下の重要ファイルを、
ユーザーが指定した外部ディレクトリ（`BACKUP_DIR`）へGPG暗号化して退避します。
どちらのスクリプトも `BACKUP_DIR` が必須引数で、リポジトリ内には保存しません。

・バックアップ（`~/.ssh/config`、`id_ed25519`、`id_ed25519.pub` のみ。
`authorized_keys` / `known_hosts` / `known_hosts.old` は除外）:

```sh
./backup-ssh-allowlist.sh /path/to/secure-backup-dir
```

・復元:

```sh
./restore-ssh-allowlist.sh /path/to/secure-backup-dir
```

対象ファイルは `BACKUP_DIR/ssh-backup.tar.gz.gpg` です。
バックアップ側は `BACKUP_DIR` が存在しない場合は中止し、既存バックアップは
タイムスタンプ付き `.bak` へローテーションしてから置き換えます。
復元側はアーカイブ内容をallowlistで検証し、`~/.ssh` が存在して空でない場合は
上書きを拒否します。

また、`~/.ssh/config` のみを取り扱うバックアップ・復元スクリプトも用意されています。

・SSH設定のみバックアップ:

```sh
./backup-ssh-config.sh /linuxshare/Backup
```

・SSH設定のみ復元:

```sh
./restore-ssh-config.sh /linuxshare/Backup
```

`/linuxshare/Backup` は例であり固定パスではありません。
対象ファイルは一般形で `BACKUP_DIR/ssh-config.tar.gz.gpg` です。

バックアップ側の挙動:

- `BACKUP_DIR` は必須引数
- 指定ディレクトリは事前に存在している必要がある（スクリプトは自動作成しない）
- 対象は `~/.ssh/config` のみ
- GPG symmetric encryption（`gpg -c`）で暗号化する
- 出力先は `BACKUP_DIR/ssh-config.tar.gz.gpg`

復元側の挙動:

- `BACKUP_DIR` は必須引数
- `BACKUP_DIR/ssh-config.tar.gz.gpg` から復元する
- 復元先は `~/.ssh/config` のみ
- アーカイブ内容を検証し、`.ssh/config` 以外を含む場合は中止する
- 既存の `~/.ssh/config` はタイムスタンプ付き `.bak` へ退避してから上書きする
- `~/.ssh` を700、`~/.ssh/config` を600へ設定する
- `~/.ssh` や `~/.ssh/config` がsymlinkの場合は拒否する

#### 4. システム側 Secure Boot 構成の配置

```sh
sudo ./setup-system.sh
```

これにより、GRUB更新時に自動で署名をやり直す pacman フックや、
専用のバックアップ・リストアスクリプトが /usr/local/sbin に入ります。
詳細な復旧手順は system/secureboot/README.md を参照してください。

#### 5. systemd unit / drop-in の配置とenable

`systemd/` 配下の自作unitとdrop-inを配置し、明示管理しているunitの
永続enable状態を再現します。
**systemd unit / drop-in / enable状態はGNU Stowではなく、
`systemd/` と `setup-systemd-services.sh` が管理元です。**

・dry-run（引数なし・既定）:

```sh
./setup-systemd-services.sh
```

ファイルシステムもsystemdの状態も変更せず、何が行われるかだけを表示します。

・適用:

```sh
./setup-systemd-services.sh --apply
```

自作unit / drop-inを配置し、必要なunitの永続enable状態を再現します。
処理順は次で固定です。

```text
custom system / user unit・drop-inの配置
→ 必要な場合だけdaemon-reload
→ system unitのenable
→ user unitのenable
```

・適用後にinactiveなunitだけ起動:

```sh
./setup-systemd-services.sh --apply --now
```

`--now` はinactiveなunitのstartだけを行い、restart / stopはしません。

現在の実装の安全方針:

- パッケージのインストールは行わない
- disableしない
- mask / unmaskしない
- stopしない
- restartしない
- masked unitは手動対応としてskipし、勝手に変更しない
- 存在しないunitはパッケージ未導入の可能性として記録し、中断しない
- 配置するのはdotfilesが持つ自作unitとdrop-inだけで、
  パッケージ提供のunit本体はshadowしない

---

## English

> [!CAUTION]
> **[CRITICAL] Personal Backup Repository Only**
> This repository contains personal configuration files tailored to the
> author's hardware and environment (Arch Linux / Windows 11 dual-boot).
> It is **NOT** a general-purpose template or a reusable setup guide.
>
> In particular, the Secure Boot recovery scripts and hardware-specific
> configuration could **render your system unbootable or cause data loss**
> if executed blindly. Do not copy-paste or execute these scripts unless
> you thoroughly understand the code.

### Overview

This repository manages and syncs the author's (seekerkrt) dotfiles.
It includes GNU Stow deployment, custom systemd unit / drop-in installation,
Secure Boot maintenance scripts, and package-list backups.

This repository is primarily hosted on GitHub, and the same-named repository
on GitLab serves as a backup mirror. GitHub is the primary upstream for
updates.
Additionally, sensitive information such as private keys and tokens is
excluded from this repository.

### Repository Structure

```text
.
├── stow/                     # User config deployed by GNU Stow
│   ├── alacritty/            # Alacritty config
│   ├── antigravity/          # Antigravity IDE config
│   ├── bash/                 # Bash config
│   ├── btop/                 # btop config
│   ├── cargo/                # Cargo config
│   ├── ccache/               # ccache config
│   ├── chrome/               # Chrome config
│   ├── clang-format/         # clang-format config
│   ├── claude/               # Claude Code config (see: Agent Configuration)
│   ├── codex/                # Codex config (see: Agent Configuration)
│   ├── conky/                # Conky config
│   ├── copilot/              # GitHub Copilot instructions
│   ├── editorconfig/         # EditorConfig
│   ├── emacs/                # Emacs config
│   ├── env/                  # Environment variables config
│   ├── fonts/                # Fonts config
│   ├── foot/                 # foot terminal config
│   ├── gemini/               # Antigravity CLI config (see: Agent Configuration)
│   ├── git/                  # Git config
│   ├── grok/                 # Grok config (see: Agent Configuration)
│   ├── hypr/                 # Hyprland config
│   ├── kde/                  # KDE config
│   ├── mako/                 # mako notification daemon config
│   ├── markdownlint/         # markdownlint config
│   ├── npm/                  # npm config
│   ├── nvim/                 # Neovim config
│   ├── scripts/              # Local scripts (agy, update-ai-cli.sh, sync-handoff, …)
│   ├── sway/                 # Sway config
│   ├── tmux/                 # tmux config
│   ├── tmuxp/                # tmuxp config
│   ├── vim/                  # Vim config
│   ├── vscode/               # VS Code config
│   ├── waybar/               # Waybar config
│   ├── wezterm/              # WezTerm config
│   ├── xorg/                 # X.Org config
│   ├── yazi/                 # yazi terminal file manager config
│   ├── zsh/                  # Zsh config
│   └── zsh-functions/        # Zsh functions
├── systemd/                  # Custom systemd units / drop-ins (not Stow-managed)
│   ├── system/               # deployed to /etc/systemd/system/
│   │   └── clamav-clamonacc.service.d/
│   │       └── override.conf
│   └── user/                 # deployed to ~/.config/systemd/user/
│       └── ssh-agent.service
├── system/secureboot/        # Secure Boot config and scripts
├── pkglist/                  # Explicit package lists
├── vscode/                   # VS Code extension list (not Stow-managed)
├── sample/                   # System configuration samples
├── docs/                     # Supplementary documentation
│   └── AI-CODINGAGENTS-INSTALLATIONS.md  # AI CLI install paths and updates
├── github/                   # GitHub ruleset templates (manual apply, not Stow-managed)
│   └── rulesets/
│       ├── protect-main.json
│       ├── protect-main-develop.json
│       └── dotfiles-protect-main.json
├── apply-stow.sh             # Create Stow links
├── remove-stow.sh            # Remove Stow links
├── setup-systemd-services.sh # Install systemd units and enable state
├── save-pkglist.sh           # Save package lists
├── setup-pkglist.sh          # Install packages from lists
├── save-vscode-extensions-list.sh  # Save VS Code extension list
├── setup-vscode-extensions-list.sh # Install VS Code extensions from list
├── backup-ssh-allowlist.sh   # Back up SSH keys and config with GPG
├── restore-ssh-allowlist.sh  # Restore SSH keys and config from GPG
├── backup-ssh-config.sh      # Back up only SSH config with GPG
├── restore-ssh-config.sh     # Restore only SSH config from GPG
└── setup-system.sh           # Install system-side config
```

### GitHub Ruleset Templates

`github/rulesets/` holds JSON templates for GitHub branch rulesets.
They are not Stow-managed, and this repository has no script that applies
them automatically. `bypass_actors` is scoped to the author's account;
rewrite it before reusing a template on another repository.

| File | Target branches | Contents |
| --- | --- | --- |
| `protect-main.json` | `main` | No deletion, no non-fast-forward, PR required (0 approvals, unresolved threads must be resolved) |
| `protect-main-develop.json` | `main` and `develop` | Same as above |
| `dotfiles-protect-main.json` | `main` | Deletion blocked only (ruleset name `private-protect-main`) |

### Agent Configuration

> [!IMPORTANT]
> **`stow/codex/.codex/AGENTS.md` is the single source of truth for the shared contract.**
> `CLAUDE.md` imports the Codex source via `@~/.codex/AGENTS.md`, and
> `GEMINI.md` is a one-way port of it. Both carry only agent-specific
> deltas. Always edit the Codex source first when changing a shared rule.

Each agent reads the following files, backed by this repository:

| Agent | Source in this repo | Resolved path | Contents |
| --- | --- | --- | --- |
| Codex | `stow/codex/.codex/AGENTS.md` | `~/.codex/AGENTS.md` | **Canonical shared contract** |
| Codex | `stow/codex/.agents/skills/` | `~/.agents/skills/` | 9 skills (directory symlinks) |
| Codex | `stow/codex/.codex/config.toml` | `~/.codex/config.toml` | Default config |
| Codex | `stow/codex/.codex/*.config.toml` | `~/.codex/` | Per-model profiles (astra / luna / sol / terra / spark / safe) |
| Codex | `stow/codex/.codex/config.toml.example` | `~/.codex/config.toml.example` | Minimal example config |
| Codex | `stow/codex/.codex/rules/` | `~/.codex/rules/` | prefix_rule files (copied as real files; currently `default.rules`) |
| Claude Code | `stow/claude/.claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Imports the Codex source + deltas |
| Claude Code | `stow/claude/.claude/skills/` | `~/.claude/skills/` | 9 skills |
| Claude Code | `stow/claude/.claude/settings.json` | `~/.claude/settings.json` | Permissions, model, hooks, plugins |
| Claude Code | `stow/claude/.claude/hooks/` | `~/.claude/hooks/` | Gate that reuses Codex rules on Bash PreToolUse |
| Antigravity CLI | `stow/gemini/.gemini/GEMINI.md` | `~/.gemini/GEMINI.md` | Port of the Codex source |
| Antigravity CLI | `stow/gemini/.gemini/antigravity-cli/skills/` | `~/.gemini/antigravity-cli/skills/` | 9 skills |
| Antigravity CLI | `stow/gemini/.gemini/settings.json` | `~/.gemini/settings.json` | Gemini CLI settings |
| Antigravity CLI | `stow/gemini/.gemini/antigravity-cli/settings.json` | `~/.gemini/antigravity-cli/settings.json` | Antigravity CLI settings |
| Grok | `stow/grok/.grok/AGENTS.md` | `~/.grok/AGENTS.md` | Symlink to the Codex source |
| Grok | `stow/grok/.grok/config.toml` | `~/.grok/config.toml` | CLI, UI, and marketplace settings (seed if missing) |
| GitHub Copilot | `stow/copilot/.copilot/instructions/global.instructions.md` | `~/.copilot/instructions/global.instructions.md` | Points to the Codex source |

Codex, Claude Code, and Antigravity CLI carry the same nine skills:

```text
audit  commit-prep  cpp-conventions  github
handoff  handoff-inline  handoff-archive  issue-slice  verify
```

> [!NOTE]
> **On Claude Code the skill is named `verify-diff`, not `verify`.**
> It is renamed deliberately because `verify` collides with a built-in command.
> The contract itself matches the other agents' `verify`.

`issue-slice` is the orchestrator for a GitHub Issue or an explicitly selected
PR-sized implementation slice. It fixes scope and non-scope, routes to the
existing `audit`, `cpp-conventions`, `verify` (`verify-diff` on Claude Code),
`commit-prep`, `github`, and `handoff` skills when needed, performs the minimum
implementation and verification, and stops before commit.

Long test, build, release-check, compiler, runtime, and diff logs are kept
outside the repository under `~/handoff/<repo>/<scope>/` with timestamped
filenames. Final responses report pass / fail, the saved path, and key points
instead of embedding raw logs.
`stow/scripts/.local/bin/sync-handoff` copies `*.md` and `*.txt` from
`~/handoff` to `~/PrivateDocs/handoff/` (available as `sync-handoff` after Stow).

The bodies of the three handoff skills (`handoff` / `handoff-inline` /
`handoff-archive`) and `handoff/references/common.md` are kept identical
across all three agents. SKILL.md front matter and the common-reference
path in `handoff-inline` are permitted per-agent differences.

`verify` (`verify-diff` on Claude Code) owns the detailed verification
workflow. `issue-slice` supplies acceptance criteria and impact / risk,
then checks that the required verification is complete.
`handoff` and `handoff-inline` use the common reference; inline does not
need to read the normal-save SKILL.md.
`github/references/commands.md` is read only when CLI examples are needed;
safety boundaries remain in `github/SKILL.md`.

Supporting references live inside each skill directory and are deployed
through the same Stow tree. Codex skill directory symlinks and the current
Claude folded layout expose new source files directly. Gemini's
`--no-folding` layout needs Stow reapplied to create links for new references.
Check reference resolution from the deployed paths as well as the sources.

> [!WARNING]
> **The `gemini` package uses `--no-folding`.**
> `~/.gemini` remains a real directory; only tracked files (`GEMINI.md`,
> `settings.json`, `antigravity-cli/settings.json`, and `skills/`) are file
> symlinks.
> Runtime data such as `history.jsonl`, `log/`, `conversations/`, and
> `brain/` is written on the home side. `.gitignore` still has exclusions
> left over from the older folded layout.
>
> **Grok's `config.toml` is a seed copy, not a Stow symlink.**
> If a live config already exists, it is left alone because Grok rewrites
> it. `~/.grok` remains a real directory; only `AGENTS.md` is a file
> symlink. This repository does not keep a copy of the nine skills under
> `stow/grok`. Runtime data such as `auth.json`, `sessions/`, and `logs/`
> stays in the home directory and is not tracked.

### AI CLI Installation and Bulk Update

`docs/AI-CODINGAGENTS-INSTALLATIONS.md` is the source of truth for how each
CLI is installed, where it currently lives, and how it is updated.

| CLI | Install path | Command |
| --- | --- | --- |
| Codex | npm global | `codex` |
| Claude Code | Official native installer | `claude` |
| Grok | npm global | `grok` |
| Antigravity CLI | Official installer + wrapper in this repo | `agy` |

`stow/scripts/.local/bin/update-ai-cli.sh` updates all four at once. After Stow
deployment it is available as `~/.local/bin/update-ai-cli.sh`.

```sh
update-ai-cli.sh
```

For each CLI it prints the resolved path and the version before and after, then
runs `<command> update` in the order `codex` → `claude` → `grok` → `agy`.
A CLI missing from PATH is skipped without aborting the run; the script exits
with 1 if any update failed.

### Usage of Core Scripts

On a fresh Arch install, run the scripts in this order, matching their
respective responsibilities:

1. Install packages from lists: `./setup-pkglist.sh`
2. Deploy $HOME config: `./apply-stow.sh`
3. Install system-side (Secure Boot) config: `sudo ./setup-system.sh`
4. Install systemd units / drop-ins and enable them:
   `./setup-systemd-services.sh --apply`
5. Restore SSH config if needed: `./restore-ssh-config.sh BACKUP_DIR`
   (or `./restore-ssh-allowlist.sh BACKUP_DIR` to include the keys)
6. Install VS Code extensions if needed: `./setup-vscode-extensions-list.sh`

There is no single all-in-one bootstrap script; run the steps individually.

#### 1. Deploy Dotfiles

Creates symlinks from the stow/ directory to your $HOME.

```sh
./apply-stow.sh
```

(The `vscode`, `gemini`, `antigravity`, and `grok` packages, and the
`.codex` subtree of the `codex` package, use `--no-folding`. Codex Skills
are deployed as directory symlinks at `~/.agents/skills/<skill>`.
`~/.codex/rules/*.rules` are not Stow symlinks; `apply-stow.sh` copies them
from the repository as real files and overwrites existing copies.
`remove-stow.sh` deletes a copied rule only when it still matches the
repository source, and leaves rules that were edited after deployment.
Grok's `config.toml` is excluded from Stow and seeded as a real file only
when it is missing.)

> [!IMPORTANT]
> **systemd units, drop-ins, and enable state are out of Stow's scope.**
> They are owned by `systemd/` and `setup-systemd-services.sh`.
> `apply-stow.sh` and `remove-stow.sh` list the former package name
> `systemd-user` in `SKIP_PACKAGES`. The package itself is already deleted;
> the entry remains as a guard against accidentally putting systemd back
> under Stow, because a Stow symlink at the same path would conflict with
> the real files installed by the setup script.

#### 2. Package Lists and VS Code Extensions

Track and sync installed packages across installations.
・To save current packages:

```sh
./save-pkglist.sh
```

・To install packages from the lists:

```sh
./setup-pkglist.sh
```

（Automatically detects yay or paru for foreign/AUR packages and applies
--needed）

VS Code extensions are managed the same way.
・To save the extension list:

```sh
./save-vscode-extensions-list.sh
```

・To install extensions from the list:

```sh
./setup-vscode-extensions-list.sh
```

The list is `$DOTFILES/vscode/extensions-list.txt`. If `$DOTFILES` is
unset, `$HOME/dotfiles` is used. Already-installed extensions are skipped.

#### 3. SSH Configuration Backup and Restore

Securely backs up critical SSH files (including private keys) into a
GPG-encrypted archive stored in a user-specified external directory
(`BACKUP_DIR`), outside the git history. `BACKUP_DIR` is a required argument
for every script below; nothing is ever written inside this repository.

・Backup (only `~/.ssh/config`, `id_ed25519`, and `id_ed25519.pub`;
`authorized_keys`, `known_hosts`, and `known_hosts.old` are excluded):

```sh
./backup-ssh-allowlist.sh /path/to/secure-backup-dir
```

・Restore:

```sh
./restore-ssh-allowlist.sh /path/to/secure-backup-dir
```

The archive is `BACKUP_DIR/ssh-backup.tar.gz.gpg`. The backup script aborts if
`BACKUP_DIR` does not exist, and rotates an existing archive to a timestamped
`.bak` before replacing it. The restore script validates the archive against
the same allowlist and refuses to overwrite `~/.ssh` if it exists and is not
empty.

Additionally, scripts to back up and restore only the `~/.ssh/config` file are
available.

・Backup SSH Config only:

```sh
./backup-ssh-config.sh /linuxshare/Backup
```

・Restore SSH Config only:

```sh
./restore-ssh-config.sh /linuxshare/Backup
```

`/linuxshare/Backup` is only an example, not a fixed path. In general terms the
archive is `BACKUP_DIR/ssh-config.tar.gz.gpg`.

Backup behavior:

- `BACKUP_DIR` is a required argument
- The directory must already exist; the script never creates it
- Only `~/.ssh/config` is included
- GPG symmetric encryption (`gpg -c`) is used
- The output is `BACKUP_DIR/ssh-config.tar.gz.gpg`

Restore behavior:

- `BACKUP_DIR` is a required argument
- Restores from `BACKUP_DIR/ssh-config.tar.gz.gpg`
- Only `~/.ssh/config` is restored
- The archive contents are validated; anything other than `.ssh/config` aborts
- An existing `~/.ssh/config` is moved to a timestamped `.bak` before overwrite
- `~/.ssh` is set to 700 and `~/.ssh/config` to 600
- A symlinked `~/.ssh` or `~/.ssh/config` is rejected

#### 4. Secure Boot Setup (System-wide)

```sh
sudo ./setup-system.sh
```

This deploys tools to /usr/local/sbin and handles automatic sbctl re-signing
whenever grub updates via a post-transaction pacman hook.
For recovery details, refer to system/secureboot/README.md.

#### 5. systemd Units and Drop-ins

Installs the custom units and drop-ins under `systemd/` and reproduces the
persistent enable state of the explicitly managed units.
**systemd units, drop-ins, and enable state are owned by `systemd/` and
`setup-systemd-services.sh`, not by GNU Stow.**

・Dry run (no arguments, the default):

```sh
./setup-systemd-services.sh
```

It changes neither the filesystem nor any systemd state; it only reports what
would happen.

・Apply:

```sh
./setup-systemd-services.sh --apply
```

Installs the custom units / drop-ins and reproduces the persistent enable state
of the required units. The order is fixed:

```text
install custom system / user units and drop-ins
→ daemon-reload only when unit files actually changed
→ enable system units
→ enable user units
```

・Start inactive units after applying:

```sh
./setup-systemd-services.sh --apply --now
```

`--now` only starts units that are currently inactive; it never restarts or
stops anything.

Safety policy of the current implementation:

- Never installs packages
- Never disables units
- Never masks or unmasks units
- Never stops units
- Never restarts units
- Skips masked units for manual handling instead of changing them
- Records missing units as possibly-uninstalled packages and keeps going
- Installs only the custom units and drop-ins owned by this repository,
  never shadowing a package-provided unit file
