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
GNU Stowによるホームディレクトリへの展開、Secure Boot運用スクリプト、
パッケージ一覧のバックアップなどを含みます。

### プロジェクトの主な構造

```text
.
├── stow/                     # GNU Stowで展開するユーザー設定
│   ├── alacritty/            # Alacritty設定
│   ├── bash/                 # Bash設定
│   ├── btop/                 # btop設定
│   ├── claude/               # Claude用ルール
│   ├── codex/                # Codex用ルール
│   ├── hypr/                 # Hyprland設定
│   ├── kde/                  # KDE設定
│   ├── nvim/                 # Neovim設定
│   ├── scripts/              # 個人用スクリプト
│   ├── tmux/                 # tmux設定
│   ├── vscode/               # VS Code設定
│   ├── waybar/               # Waybar設定
│   ├── wezterm/              # WezTerm設定
│   └── zsh/                  # Zsh設定
├── system/secureboot/        # Secure Boot関連の設定とスクリプト
├── pkglist/                  # 明示インストール済みパッケージ一覧
├── apply-stow.sh             # Stowリンクを作成
├── remove-stow.sh            # Stowリンクを削除
├── update-pkglist.sh         # パッケージ一覧を更新
├── restore-pkglist.sh        # パッケージ一覧から復元
├── backup-ssh-allowlist.sh   # SSH設定を暗号化バックアップ
└── setup-system.sh           # システム側設定を配置
```

### 主要スクリプトの使い方

#### 1. ドットファイルの適用・同期

ホームディレクトリ（$HOME）に設定ファイルのシンボリックリンクを展開します。

```sh
./apply-stow.sh
```

（展開時、vscode パッケージのみディレクトリ構造を維持するため
--no-folding オプションが自動適用されます。）

#### 2. パッケージリストの更新と復元

普段インストールしているパッケージの一覧を管理します。
・リストの更新（現在の状態を保存）:

```sh
./update-pkglist.sh
```

・パッケージの復元（クリーンインストール時など）:

```sh
./restore-pkglist.sh
```

（自動的に公式パッケージは pacman、AURパッケージは yay または paru を検出して
--needed でインストールします）

#### 3. SSH設定のバックアップと復元

秘密鍵を含むため、リポジトリにコミットしたくない ~/.ssh 以下の重要ファイルを
別ディレクトリへGPG暗号化して退避します。
・バックアップ（known_hosts 等は除外）:

```sh
./backup-ssh-allowlist.sh /path/to/secure-backup-dir
```

・復元:

```sh
./restore-ssh-allowlist.sh /path/to/secure-backup-dir
```

#### 4. システム側 Secure Boot 構成の配置

```sh
sudo ./setup-system.sh
```

これにより、GRUB更新時に自動で署名をやり直す pacman フックや、
専用のバックアップ・リストアスクリプトが /usr/local/sbin に入ります。
詳細な復旧手順は system/secureboot/README.md を参照してください。

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
It includes GNU Stow deployment, Secure Boot maintenance scripts,
and package-list backups.

### Repository Structure

```text
.
├── stow/                     # User config deployed by GNU Stow
│   ├── alacritty/            # Alacritty config
│   ├── bash/                 # Bash config
│   ├── btop/                 # btop config
│   ├── claude/               # Claude rules
│   ├── codex/                # Codex rules
│   ├── hypr/                 # Hyprland config
│   ├── kde/                  # KDE config
│   ├── nvim/                 # Neovim config
│   ├── scripts/              # Local scripts
│   ├── tmux/                 # tmux config
│   ├── vscode/               # VS Code config
│   ├── waybar/               # Waybar config
│   ├── wezterm/              # WezTerm config
│   └── zsh/                  # Zsh config
├── system/secureboot/        # Secure Boot config and scripts
├── pkglist/                  # Explicit package lists
├── apply-stow.sh             # Create Stow links
├── remove-stow.sh            # Remove Stow links
├── update-pkglist.sh         # Update package lists
├── restore-pkglist.sh        # Restore packages from lists
├── backup-ssh-allowlist.sh   # Back up SSH config with GPG
└── setup-system.sh           # Install system-side config
```

### Usage of Core Scripts

#### 1. Deploy Dotfiles

Creates symlinks from the stow/ directory to your $HOME.

```sh
./apply-stow.sh
```

（Note: The vscode profile automatically triggers --no-folding to keep the
inner directory architecture intact.）

#### 2. Package Management

Track and sync installed packages across installations.
・To Save Current Packages:

```sh
./update-pkglist.sh
```

・To Restore Packages:

```sh
./restore-pkglist.sh
```

（Automatically detects yay or paru for foreign/AUR packages and applies
--needed）

#### 3. SSH Configuration Backup

Securely backs up critical SSH files into a GPG-encrypted archive outside the
git history.
・Backup:

```sh
./backup-ssh-allowlist.sh /path/to/secure-backup-dir
```

・Restore:

```sh
./restore-ssh-allowlist.sh /path/to/secure-backup-dir
```

#### 4. Secure Boot Setup (System-wide)

```sh
sudo ./setup-system.sh
```

This deploys tools to /usr/local/sbin and handles automatic sbctl re-signing
whenever grub updates via a post-transaction pacman hook.
For recovery details, refer to system/secureboot/README.md.
