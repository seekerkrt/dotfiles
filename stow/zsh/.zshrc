#! zsh

# ~/.zshrc
# 対話シェル向けの設定を上から順に初期化する。

# -----------------------------------------------------------------------------
# 基本設定
# -----------------------------------------------------------------------------

umask 022

# 未定義変数をエラーにしたい場合に有効化する。
# set -u

# ログイン/ログアウト監視が必要な場合に有効化する。
# watch="all"
# log

# ^D でログアウトしたくない場合に有効化する。
# setopt ignore_eof

setopt no_beep              # ビープ音を鳴らさない
setopt auto_cd              # ディレクトリ名だけで cd する
setopt auto_pushd           # cd 時にディレクトリスタックへ積む
setopt nocorrect            # コマンドのスペル訂正をしない
setopt prompt_subst         # PROMPT 内で変数/コマンド置換を使う
setopt interactive_comments # 対話入力でも # 以降をコメントとして扱う

# setopt correct            # コマンドのスペル訂正を有効化する場合

# -----------------------------------------------------------------------------
# 環境変数
# -----------------------------------------------------------------------------

export EDITOR=nvim
export VISUAL=nvim
export DIFFPROG="nvim -d"

export TERMINAL=wezterm
export BROWSER=google-chrome-stable

export LANG=ja_JP.UTF-8
# export LANG=en_US.UTF-8

export PATH="$PATH:$HOME/.local/bin/:$HOME/.cargo/bin:$HOME/.local/npm-global/bin"
export GEM_HOME=$(ruby -e 'print Gem.user_dir')

# systemd user service で起動する ssh-agent の socket を参照する。
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Gentoo eix
export EIX_LIMIT=0

export AWESOME_CONF=~/.config/awesome/rc.lua
export VSCODE_CONF=~/config/Code/User/settings.json

# export CROSSDEV=/opt/crossdev
# export ARCH_RUST_CROSS=x86_64-pc-windows-gnu
# export CFLAGS="-O2 -pipe -Wall -Wextra -Wno-unused-parameter -Wfloat-equal"
# export CXXFLAGS="-std=c++17 ${CFLAGS} -xc++"
# export MAKEFLAGS=-j$(($(nproc)+1))
export MAKEFLAGS="-j6"
# export CHOST=$(uname -m)-pc-linux-gnu

export LIBVIRT_DEFAULT_URI='qemu:///system'

# -----------------------------------------------------------------------------
# Alias
# -----------------------------------------------------------------------------

alias ls="ls -F --color=auto"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"

alias bat='bat --paging=auto'
alias b='bat -n --paging=never'
alias bl='bat -n --paging=always'

alias eza='eza -F'

# alias ccat='command cat'
# alias nvim='LC_MESSAGES=C nvim'
# alias emacs="emacs -nw"
# alias google-chrome-stable="google-chrome-stable --force-dark-mode"
# alias code="code --enable-features=UseOzonePlatform --ozone-platform=wayland"

# -----------------------------------------------------------------------------
# Pager / 色
# -----------------------------------------------------------------------------

export PAGER=less
export OUTPUT_CHARSET=utf-8
export LESSOPEN='| /usr/bin/src-hilite-lesspipe.sh %s'
export LESS='-R '

# export LESSOPEN="| /usr/bin/source-highlight-esc.sh %s"

export LESS_TERMCAP_me=$(printf '\e[0m')
export LESS_TERMCAP_se=$(printf '\e[0m')
export LESS_TERMCAP_ue=$(printf '\e[0m')
export LESS_TERMCAP_mb=$(printf '\e[1;32m')
export LESS_TERMCAP_md=$(printf '\e[1;34m')
export LESS_TERMCAP_us=$(printf '\e[1;32m')
export LESS_TERMCAP_so=$(printf '\e[1;44;1m')

export LSCOLORS=Exfxcxdxbxegedabagacad
export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
export ZLS_COLORS=$LS_COLORS
export CLICOLOR=true

# -----------------------------------------------------------------------------
# 補完 / glob
# -----------------------------------------------------------------------------

# source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

autoload -U compinit
compinit -u

setopt completealiases    # alias 展開後のコマンドも補完する
setopt auto_list          # 補完候補を一覧表示する
setopt auto_menu          # 補完キー連打で候補を順に選ぶ
setopt list_packed        # 補完候補を詰めて表示する
setopt list_types         # 補完候補にファイル種別を表示する
setopt magic_equal_subst  # = 以降も補完する

setopt extended_glob      # 拡張 glob を使う
setopt nonomatch          # match しない glob をエラーにしない

zstyle ':completion:*' menu select
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:sudo:*' command-path $path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

if [[ -r /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

# -----------------------------------------------------------------------------
# 履歴
# -----------------------------------------------------------------------------

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt bang_hist            # ! による履歴展開を使う
setopt extended_history     # 実行時刻と所要時間を保存する
setopt share_history        # 他の zsh と履歴を共有する
setopt hist_reduce_blanks   # 余分な空白を削って保存する
setopt HIST_IGNORE_ALL_DUPS # 重複する履歴を残しすぎない
setopt inc_append_history   # 実行後すぐに履歴へ追記する

# setopt hist_ignore_dups   # 直前と同じコマンドを履歴に追加しない

history-all() {
  history -E 1
}

# -----------------------------------------------------------------------------
# キーバインド
# -----------------------------------------------------------------------------

bindkey -e
bindkey "^?" backward-delete-char
bindkey "^H" backward-delete-char
bindkey "^[[3~" delete-char
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line
bindkey '5D' emacs-backward-word
bindkey '5C' emacs-forward-word

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line

if [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi

# -----------------------------------------------------------------------------
# Prompt
# -----------------------------------------------------------------------------

autoload -Uz colors
colors

local p_user="%(!,%F{red}%n%f,%F{cyan}%n%f)"
local p_host="%F{green}%M%f"
local p_mark="%B%(!,%F{red}#%f,%F{cyan}$%f)%b"
local p_pwd="%F{yellow}%(!,%d,%~)%f"

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!"
zstyle ':vcs_info:git:*' unstagedstr "%F{magenta}+"
zstyle ':vcs_info:*' formats "%F{green}%c%u(%b)%f"
zstyle ':vcs_info:*' actionformats '[%b|%a]'

precmd() {
  vcs_info
}

PROMPT='[${p_user}@${p_host} ${p_pwd}]:${vcs_info_msg_0_}${p_mark} '

# -----------------------------------------------------------------------------
# ユーザー関数
# -----------------------------------------------------------------------------

fpath=("$HOME/.zsh/functions" $fpath)
typeset -U fpath

for func_file in "$HOME"/.zsh/functions/*(.N); do
  autoload -Uz "${func_file:t}"
done
unset func_file

ff() {
  fd -t f . | fzf --preview "bat --style=plain --color=always {}" --preview-window=right:60%
}

ffv() {
  local base="${1:-.}"
  local f
  f="$(fd -t f . "$base" | fzf --preview "bat --style=plain --color=always {}" --preview-window=right:60%)" || return
  nvim "$f"
}

fcd() {
  cd "$(fd -t d . | fzf)"
}

codex-plan() {
  codex "$@"
}

codex-api() {
  CODEX_HOME="$HOME/.codex-api" codex "$@"
}

codex-kvm() {
  if (( ! $+commands[codex] )); then
    print -u2 'codex-kvm: codex コマンドが見つかりません'
    return 127
  fi

  if [[ ! -c /dev/kvm ]]; then
    print -u2 'codex-kvm: /dev/kvm が存在しません'
    return 1
  fi

  if [[ ! -r /dev/kvm || ! -w /dev/kvm ]]; then
    print -u2 'codex-kvm: /dev/kvm への読み書き権限がありません'
    return 1
  fi

  command codex --sandbox danger-full-access "$@"
}

claude-api-on() {
  local model="${1:-sonnet}"

  export ANTHROPIC_API_KEY="$(
    gpg --quiet --decrypt "$HOME/secrets/claude-code-api-key.txt.gpg" | tr -d '\r\n'
  )"
  export ANTHROPIC_MODEL="$model"

  echo "ANTHROPIC_API_KEY set"
  echo "ANTHROPIC_MODEL=$ANTHROPIC_MODEL"
}

claude-api-off() {
  unset ANTHROPIC_API_KEY
  unset ANTHROPIC_MODEL
  echo "Claude API env unset"
}

# -----------------------------------------------------------------------------
# 外部ツール初期化
# -----------------------------------------------------------------------------

eval "$(zoxide init zsh)"
eval "$(atuin init zsh --disable-up-arrow)"
