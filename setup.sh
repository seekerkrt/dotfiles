#! /bin/bash
set -u

THIS_DIR=$(cd $(dirname $0); pwd)
# ".??* => ２文字以上の.がついたファイルやフォルダを、ホームディレクトリ以下にリンクを置く"
cd $THIS_DIR
echo "Start setup..."
for dotfile in .??*; do
# 指定のファイルやディレクトリを除外
    [ "$dotfile" = ".git" ] && continue
    [ "$dotfile" = ".gitconfig.local.template" ] && continue
    [ "$dotfile" = ".gitmodules" ] && continue
# リンクを貼る
    ln -sfnv $THIS_DIR/"$dotfile" ~/
done

# VSCodeの設定ファイル類をリンク置く
ln -fnsv $THIS_DIR/vscode/settings.json ~/.config/Code/User/settings.json
