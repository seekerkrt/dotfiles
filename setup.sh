#! /bin/bash
set -u

THIS_DIR=$(cd $(dirname $0); pwd)

cd $THIS_DIR
echo "Start setup..."
for dotfile in .??*; do
# 指定のファイルやディレクトリを除外
    [ "$dotfile" = ".git" ] && continue
    [ "$dotfile" = ".gitconfig.local.template" ] && continue
    [ "$dotfile" = ".gitmodules" ] && continue
# リンクを貼る  
    ln -sfnv ~/dotfiles/"$dotfile" ~/
done

