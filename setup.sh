#! sh
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

# sshディレクトリのパーミッションを適切にする
chmod -v 700 ~/.ssh
chmod -v 600 ~/.ssh/*

# VSCodeの設定ファイル類をリンク置く
mkdir -pv ~/.config/Code/User/
ln -sfnv $THIS_DIR/vscode/settings.json ~/.config/Code/User/settings.json
