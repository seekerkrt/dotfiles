#! zsh
###
#    zsh Setting File
###

# デフォルトファイルパーミッション
umask 022
# 変数未定義の使用時エラーにする
#set -u

# すべてのログインログアウトを監視する
#watch="all"
# 上記を通知する
#log

# ^Dでログアウトしない
#setopt ignore_eof
# Gentoo "eix"
export EIX_LIMIT=0

export EDITOR=nvim
export VISUAL=nvim
export DIFFPROG="nvim -d"

#export CROSSDEV=/opt/crossdev
export PATH="$PATH:$HOME/.local/bin/:$HOME/.cargo/bin:$HOME/.local/npm-global/bin"

#export ARCH_RUST_CROSS=x86_64-pc-windows-gnu
export GEM_HOME=$(ruby -e 'print Gem.user_dir')

export TERMINAL=wezterm

#export LANG=en_US.UTF-8
export LANG=ja_JP.UTF-8

export AWESOME_CONF=~/.config/awesome/rc.lua
export VSCODE_CONF=~/config/Code/User/settings.json
#export CFLAGS="-O2 -pipe -Wall -Wextra -Wno-unused-parameter -Wfloat-equal"
#export CXXFLAGS="-std=c++17 ${CFLAGS} -xc++"
#export MAKEFLAGS=-j$(($(nproc)+1))
#export CHOST=$(uname -m)-pc-linux-gnu


### User specific aliases and functions
### Aliases
alias ls="ls -F --color=auto"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias cat='bat --paging=never --style=plain'
alias ccat='command cat'
alias eza='eza -F'
#alias nvim='LC_MESSAGES=C nvim'
#alias emacs="emacs -nw"
#alias google-chrome-stable="google-chrome-stable --force-dark-mode"
#alias code="code --enable-features=UseOzonePlatform --ozone-platform=wayland"

### others

### for PAGER(less) source-highlight
export PAGER=less
export OUTPUT_CHARSET=utf-8
export LESSOPEN='| /usr/bin/src-hilite-lesspipe.sh %s'
#export LESSOPEN="| /usr/bin/source-highlight-esc.sh %s"
export LESS='-R '
export LESS_TERMCAP_me=$(printf '\e[0m')
export LESS_TERMCAP_se=$(printf '\e[0m')
export LESS_TERMCAP_ue=$(printf '\e[0m')
export LESS_TERMCAP_mb=$(printf '\e[1;32m')
export LESS_TERMCAP_md=$(printf '\e[1;34m')
export LESS_TERMCAP_us=$(printf '\e[1;32m')
export LESS_TERMCAP_so=$(printf '\e[1;44;1m')


########################################################
#   zsh - Settings
########################################################
setopt no_beep           # ビープ音を鳴らさないようにする
setopt auto_cd           # ディレクトリ名の入力のみで移動する
setopt auto_pushd        # cd時にディレクトリスタックにpushdする
#setopt correct           # コマンドのスペルを訂正する
setopt nocorrect         #コマンドのスペルを訂正しない
setopt prompt_subst      # プロンプト定義内で変数置換やコマンド置換を扱う

### Complement ###
#source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
autoload -U compinit; compinit -u # 補完機能を有効にする
setopt completealiases #エイリアスでも補完するようにする
setopt auto_list               # 補完候補を一覧で表示する(d)
setopt auto_menu               # 補完キー連打で補完候補を順に表示する(d)
setopt list_packed             # 補完候補をできるだけ詰めて表示する
setopt list_types              # 補完候補にファイルの種類も表示する
setopt magic_equal_subst # =以降も補完する(--prefix=/usrなど)
zstyle ':completion:*' menu select
# sudo時に補完が有効になる
zstyle ':completion:*:sudo:*' command-path $path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /usr/X11R6/bin

### Glob ###
setopt extended_glob # グロブ機能を拡張する
setopt nonomatch

### History ###
HISTFILE=~/.zsh_history   # ヒストリを保存するファイル
HISTSIZE=10000           # メモリに保存されるヒストリの件数
SAVEHIST=10000          # 保存されるヒストリの件数
setopt bang_hist          # !を使ったヒストリ展開を行う(d)
setopt extended_history   # ヒストリに実行時間も保存する
#setopt hist_ignore_dups   # 以前と同じコマンドはヒストリに追加しない
setopt share_history      # 他のシェルのヒストリをリアルタイムで共有する
setopt hist_reduce_blanks # 余分なスペースを削除してヒストリに保存する
setopt HIST_IGNORE_ALL_DUPS
setopt inc_append_history

### キーバインド設定
bindkey -e 	#キーバインドをemacsモードにする
bindkey "^?"    backward-delete-char
bindkey "^H"    backward-delete-char
bindkey "^[[3~" delete-char
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line
bindkey '5D' emacs-backward-word
bindkey '5C' emacs-forward-word
# マッチしたコマンドのヒストリを表示できるようにする
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# --- fzf key bindings / completion ---
if [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi
if [[ -r /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi

# すべてのヒストリを表示する
function history-all { history -E 1 }

# ------------------------------
# Look And Feel Settings
# ------------------------------
### Ls Color ###
# 色の設定
export LSCOLORS=Exfxcxdxbxegedabagacad
# 補完時の色の設定
export LS_COLORS='di=01;34:ln=01;35:so=01;32:ex=01;31:bd=46;34:cd=43;34:su=41;30:sg=46;30:tw=42;30:ow=43;30'
# ZLS_COLORSとは？
export ZLS_COLORS=$LS_COLORS
# lsコマンド時、自動で色がつく(ls -Gのようなもの？)
export CLICOLOR=true
# 補完候補に色を付ける
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}

### Prompt ###
# プロンプトに色を付ける
autoload -Uz colors; colors
#PROMPT="%F{cyan}[%f%F{magenta}%n%f%F{cyan}@%f%F{cyan}%m%f %F{yellow}%~%f%F{cyan}]%#%f "
local p_user="%(!,%F{red}%n%f,%F{cyan}%n%f)"
local p_host="%F{green}%M%f"
local p_mark="%B%(!,%F{red}#%f,%F{cyan}$%f)%b"
local p_pwd="%F{yellow}%(!,%d,%~)%f"
# Git対応
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true #formats 設定項目で %c,%u が使用可
zstyle ':vcs_info:git:*' stagedstr "%F{yellow}!" #commit されていないファイルがある
zstyle ':vcs_info:git:*' unstagedstr "%F{magenta}+" #add されていないファイルがある
zstyle ':vcs_info:*' formats "%F{green}%c%u(%b)%f" #通常
zstyle ':vcs_info:*' actionformats '[%b|%a]' #rebase 途中,merge コンフリクト等 formats 外の表示
# %b ブランチ情報
# %a アクション名(mergeなど)
# %c changes
# %u uncommit
precmd() { vcs_info }
### PROMPT変数
PROMPT='[${p_user}@${p_host} ${p_pwd}]:${vcs_info_msg_0_}${p_mark} '


# Editor Ctrl-x Ctrl-e (コマンドラインをエディタで編集)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^e' edit-command-line


# ---- user functions (autoload) ----
fpath=("$HOME/.zsh/functions" $fpath)
typeset -U path fpath
autoload -Uz cpfunc cpc cins csrc cfn csrcq cplines cplinesn


ff() {
  fd -t f . | fzf --preview "bat --style=plain --color=always {}" --preview-window=right:60%
}

ffv() {
  local base="${1:-.}"
  local f
  f="$(fd -t f . "$base" | fzf --preview "bat --style=plain --color=always {}" --preview-window=right:60%)" || return
  nvim "$f"
}

fcd() { cd "$(fd -t d . | fzf)" }

eval "$(zoxide init zsh)"
