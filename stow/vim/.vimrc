filetype plugin indent on

" set t_Co=256は256色対応のターミナルソフトでのみ作用するので、Winのコマンドプロンプト使っている人などは ダブルコーテーションでコメントアウトしといて
set t_Co=256
" 色づけを on にする
syntax on

set noswapfile

set nowrap
set autoindent
set shiftwidth=4
set softtabstop=4
set expandtab
set tabstop=4
set smarttab
set ruler

" 行番号
set number
" クリップボード連携
set clipboard=unnamedplus






" Wayland clipboard (KDE/Plasma Wayland向け)
if executable('wl-copy') && executable('wl-paste')
  let g:clipboard = {
        \ 'name': 'wl-clipboard',
        \ 'copy': {
        \   '+': 'wl-copy --foreground --type text/plain',
        \   '*': 'wl-copy --foreground --primary --type text/plain',
        \ },
        \ 'paste': {
        \   '+': 'wl-paste --no-newline',
        \   '*': 'wl-paste --primary --no-newline',
        \ },
        \ 'cache_enabled': 0,
        \ }
  set clipboard=unnamedplus
endif

