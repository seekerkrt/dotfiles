###
# ZSH Setting File
###
#デフォルトファイルパーミッション
umask 022
#変数未定義の使用時エラーにする
set -u 

export EDITOR=nano
export LANG=ja_JP.UTF-8
export TRIZEN_CONF=~/.config/trizen/trizen.conf
export AWESOME_CONF=~/.config/awesome/rc.lua
export VSCODE_CONF=~/config/Code/User/settings.json
#export CFLAGS="-O2 -pipe -Wall -Wextra -Wno-unused-parameter -Wfloat-equal"
#export CXXFLAGS="-std=c++17 ${CFLAGS} -xc++"
export MAKEFLAGS=-j9
export CROSSTOOLCHAIN=/opt/crosstoolchain
#export CHOST=$(uname -m)-pc-linux-gnu
#export GEM_HOME=$(ruby -e 'print Gem.user_dir')
export PATH="$CROSSTOOLCHAIN/bin:/usr/lib/ccache/bin:$PATH"



### User specific aliases and functions
### Aliases
alias ls="ls -F --color=auto"
alias grep="grep --color=auto"
alias egrep="egrep --color=auto"
alias emacs="emacs -nw"
alias vscode="code"


### others




### for PAGER(less) source-highlight 
export PAGER=less
export OUTPUT_CHARSET=utf-8
export LESS='-R '
#export LESSOPEN="| /usr/bin/source-highlight-esc.sh %s"
#export LESSOPEN='| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'
export LESSOPEN='| /usr/bin/src-hilite-lesspipe.sh %s'
export LESS_TERMCAP_me=$(printf '\e[0m')
export LESS_TERMCAP_se=$(printf '\e[0m')
export LESS_TERMCAP_ue=$(printf '\e[0m')
export LESS_TERMCAP_mb=$(printf '\e[1;32m')
export LESS_TERMCAP_md=$(printf '\e[1;34m')
export LESS_TERMCAP_us=$(printf '\e[1;32m')
export LESS_TERMCAP_so=$(printf '\e[1;44;1m')


########################################################
#  zsh - Settings
########################################################
setopt no_beep           # ビープ音を鳴らさないようにする
setopt auto_cd           # ディレクトリ名の入力のみで移動する 
setopt auto_pushd        # cd時にディレクトリスタックにpushdする
setopt correct           # コマンドのスペルを訂正する
setopt magic_equal_subst # =以降も補完する(--prefix=/usrなど)
setopt prompt_subst      # プロンプト定義内で変数置換やコマンド置換を扱う

### Complement ###
autoload -U compinit; compinit -u # 補完機能を有効にする
setopt auto_list               # 補完候補を一覧で表示する(d)
setopt auto_menu               # 補完キー連打で補完候補を順に表示する(d)
setopt list_packed             # 補完候補をできるだけ詰めて表示する
setopt list_types              # 補完候補にファイルの種類も表示する

### Glob ###
setopt extended_glob # グロブ機能を拡張する

### History ###
HISTFILE=~/.zsh_history   # ヒストリを保存するファイル
HISTSIZE=10000            # メモリに保存されるヒストリの件数
SAVEHIST=10000            # 保存されるヒストリの件数
setopt bang_hist          # !を使ったヒストリ展開を行う(d)
setopt extended_history   # ヒストリに実行時間も保存する
setopt hist_ignore_dups   # 直前と同じコマンドはヒストリに追加しない
setopt share_history      # 他のシェルのヒストリをリアルタイムで共有する
setopt hist_reduce_blanks # 余分なスペースを削除してヒストリに保存する

# マッチしたコマンドのヒストリを表示できるようにする
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

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
autoload -U colors; colors
PROMPT="%F{cyan}[%f%F{magenta}%n%f%F{cyan}@%f%F{cyan}%m%f %F{yellow}%~%f%F{cyan}]%#%f "


### キーバインド設定
bindkey -e 	#キーバインドをemacsモードにする
bindkey "^?"    backward-delete-char
bindkey "^H"    backward-delete-char
bindkey "^[[3~" delete-char
bindkey "^[[1~" beginning-of-line
bindkey "^[[4~" end-of-line
bindkey '5D' emacs-backward-word
bindkey '5C' emacs-forward-word
