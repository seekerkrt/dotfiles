# seekerkrt's Dotfiles

[日本語](#日本語) | [English](#english)

---

## 日本語

> [!CAUTION]
> **【重要】これは個人専用のバックアップリポジトリです**
> 本リポジトリは、作者の特定のハードウェアおよび環境（Arch Linux / Windows 11 デュアルブート）に完全に依存した個人用設定です。汎用的なテンプレートや、他人がそのまま導入して動かすためのリポジトリではありません。
> 
> 特にSecure Boot関連の設定やハードウェア固有のスクリプトは、そのまま実行すると最悪の場合**システムが起動しなくなる、あるいはデータが破損する恐れ（ランドマイン）**があります。内容を十分に理解せずにコピー＆ペーストしたり、スクリプトを実行したりしないでください。

### 概要
このリポジトリは、作者（seekerkrt）の設定ファイル（ドットファイル）を管理・同期するためのものです。GNU Stowを利用したホームディレクトリへの展開システムと、GRUB/sbctlを維持したSecure Bootの運用スクリプト、パフォーマンステスト用のパーツなどが含まれています。

### プロジェクトの主な構造
.
├── stow/   （GNU Stowで展開するアプリ別設定ディレクトリ）
│   ├── alacritty/   （端末：Myrica Mフォント、不透明度0.6）
│   ├── bash/   （環境変数・エイリアスなど最小限定義）
│   ├── btop/   （TTYテーマ、Vimキー無効の基本設定）
│   ├── claude/   （CLAUDE.md カスタムルール）
│   ├── codex/   （AGENTS.md カスタムルール）
│   ├── hypr/   （Hyprlandデュアルモニタ、ピン留め設定）
│   ├── kde/   （KDE Plasma：Krohnkite有効、ショートカット）
│   ├── nvim/   （Pure v0.11 Native LSP + Lazy.nvim、monokai常用）
│   ├── scripts/   （個人用スクリプト群：Chrome起動、cpfuncなど）
│   ├── tmux/   （zshデフォルト起動、Viコピーモード、ペイン分割パス維持）
│   ├── vscode/   （VS Code設定：Myrica Mフォント、clangd用query-driver）
│   ├── waybar/   （タスクバー、Hyprland連携）
│   ├── wezterm/   （メイン端末：WebGpu有効、copy-on-select、Monokai Dark）
│   └── zsh/   （メインシェル、プロンプトにvcs_infoによるGit情報連携）
├── system/secureboot/   （Secure Boot運用関連のコア設定・フック）
├── pkglist/   （pacmanで明示的に導入したパッケージの記録）
├── apply-stow.sh   （全 stowed パッケージのリンク生成スクリプト）
├── remove-stow.sh   （全 stowed パッケージのリンク削除スクリプト）
├── update-pkglist.sh   （現在のインストール済みパッケージを pkglist/ に保存）
├── restore-pkglist.sh   （pkglist/ からパッケージを再現）
├── backup-ssh-allowlist.sh   （~/.ssh から特定の鍵とconfigのみを暗号化バックアップ）
└── setup-system.sh   （root所有のシステム設定を配置）

### 主要スクリプトの使い方

#### 1. ドットファイルの適用・同期
ホームディレクトリ（$HOME）に設定ファイルのシンボリックリンクを展開します。
$ ./apply-stow.sh
（展開時、vscode パッケージのみディレクトリ構造を維持するため --no-folding オプションが自動適用されます。）

#### 2. パッケージリストの更新と復元
普段インストールしているパッケージの一覧を管理します。
・リストの更新（現在の状態を保存）:
  $ ./update-pkglist.sh
・パッケージの復元（クリーンインストール時など）:
  $ ./restore-pkglist.sh
  （自動的に公式パッケージは pacman、AURパッケージは yay または paru を検出して --needed でインストールします）

#### 3. SSH設定のバックアップと復元
秘密鍵を含むため、リポジトリにコミットしたくない ~/.ssh 以下の重要ファイルを別ディレクトリへGPG暗号化して退避します。
・バックアップ（known_hosts 等は除外）:
  $ ./backup-ssh-allowlist.sh /path/to/secure-backup-dir
・復元:
  $ ./restore-ssh-allowlist.sh /path/to/secure-backup-dir

#### 4. システム側 Secure Boot 構成の配置
$ sudo ./setup-system.sh
これにより、GRUBがアップデートされた際に自動で署名をやり直す pacman フックや、専用のバックアップ・リストアスクリプトが /usr/local/sbin にインストールされます。詳細な復旧手順は system/secureboot/README.md を参照してください。

---

## English

> [!CAUTION]
> **[CRITICAL] Personal Backup Repository Only**
> This repository contains personal configuration files fully tailored to the author's specific hardware and environment (Arch Linux / Windows 11 dual-boot). It is **NOT** a general-purpose template, nor is it meant to be used by anyone else.
> 
> In particular, the Secure Boot recovery scripts and hardware-specific configurations could **render your system unbootable or cause data loss** if executed blindly. Do not copy-paste or execute these scripts unless you thoroughly understand the code.

### Overview
This repository manages and syncs the author's (seekerkrt) dotfiles. It features a home directory deployment system using GNU Stow, advanced UEFI Secure Boot signing scripts combined with GRUB/sbctl, and local environment state backups.

### Repository Structure
.
├── stow/                     # App-specific dotfiles managed by GNU Stow
│   ├── alacritty/            # Terminal (Myrica M font, opacity 0.6)
│   ├── bash/                 # Minimal fallback shell configuration
│   ├── btop/                 # System monitor (TTY theme, Vim keys disabled)
│   ├── claude/               # AI Agent assistant rules (CLAUDE.md)
│   ├── codex/                # AI Agent assistant rules (AGENTS.md)
│   ├── hypr/                 # Hyprland (DP-1 144Hz / HDMI-A-1 144Hz dual-monitor)
│   ├── kde/                  # KDE Plasma (Krohnkite tiling script enabled)
│   ├── nvim/                 # Neovim (Native LSP + Lazy.nvim, monokai theme)
│   ├── scripts/              # Local scripts (Chrome launcher, cpfunc, etc.)
│   ├── tmux/                 # vi-mode, path persistence on splits, renumbering
│   ├── vscode/               # VS Code (Myrica M font, clangd query-driver settings)
│   ├── waybar/               # Status bar for Hyprland workspace tracking
│   ├── wezterm/              # Main terminal (WebGpu frontend, Monokai Dark)
│   └── zsh/                  # Main interactive shell with custom vcs_info prompt
├── system/secureboot/        # Secure Boot automated hooks and maintenance scripts
├── pkglist/                  # Explicitly installed package cache (official / foreign)
├── apply-stow.sh             # Symlink deployment script using GNU Stow
├── remove-stow.sh            # Removes symlinks created by Stow
├── update-pkglist.sh         # Backs up the list of explicitly installed packages
├── restore-pkglist.sh        # Restores packages via pacman and yay/paru automatically
├── backup-ssh-allowlist.sh   # GPG-encrypted archive backup tool for allowlisted SSH keys
└── setup-system.sh           # Installs system-wide scripts and pacman hooks as root

### Usage of Core Scripts

#### 1. Deploy Dotfiles
Creates symlinks from the stow/ directory to your $HOME.
$ ./apply-stow.sh
（Note: The vscode profile automatically triggers the --no-folding option to keep the inner directory architecture intact.）

#### 2. Package Management
Track and sync installed packages across installations.
・To Save Current Packages:
  $ ./update-pkglist.sh
・To Restore Packages:
  $ ./restore-pkglist.sh
  （Automatically detects yay or paru for foreign/AUR packages and applies --needed）

#### 3. SSH Configuration Backup
Securely backs up critical SSH files (config, id_ed25519, id_ed25519.pub) into a GPG-encrypted archive outside the git history.
・Backup:
  $ ./backup-ssh-allowlist.sh /path/to/secure-backup-dir
・Restore:
  $ ./restore-ssh-allowlist.sh /path/to/secure-backup-dir

#### 4. Secure Boot Setup (System-wide)
$ sudo ./setup-system.sh
This deploys customized tools to /usr/local/sbin and handles automatic sbctl re-signing whenever grub updates via a post-transaction pacman hook. For deep-dive recovery steps, refer to system/secureboot/README.md.
