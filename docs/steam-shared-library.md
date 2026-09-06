# Steam 共有ライブラリ初期セットアップ

Arch Linux / Windows デュアルブート環境で、Steam のゲーム本体を共有 NTFS パーティションに配置し、両 OS から利用するためのセットアップ手順。

## プレースホルダー

このドキュメントでは環境固有の値を以下のように表記する。

```text
<shared-ntfs-device>
    Steam共有用NTFSパーティションのデバイス
    例: /dev/nvme0n1p1

<shared-ntfs-uuid>
    Steam共有用NTFSパーティションのUUID

<shared-mount>
    Linux側のマウントポイント
    例: /mnt/steam-shared

<uid>
    LinuxユーザーのUID

<gid>
    LinuxユーザーのGID

<windows-drive>
    Windows側で共有NTFSに割り当てられたドライブレター
    例: D:
```

UID / GID は以下で確認できる。

```bash
id -u
id -g
```

---

## 最終構成

```text
<shared-mount>/
└── SteamLibrary/
    └── steamapps/
        ├── common/       # ゲーム本体
        ├── appmanifest_*.acf
        ├── compatdata/   # Arch側ext4からbind mount
        └── shadercache/  # Arch側ext4からbind mount
```

Arch 側の Steam 既定ライブラリ:

```text
$HOME/.local/share/Steam/steamapps/
├── common/
├── compatdata/       # 実体
├── shadercache/      # 実体
└── appmanifest_*.acf
```

基本方針:

* ゲーム本体は共有 NTFS の `SteamLibrary` に置く
* Windows と Arch から同じゲーム本体を利用する
* Proton の `compatdata` は NTFS に置かない
* `shadercache` も NTFS に置かない
* `compatdata` / `shadercache` の実体は Arch 側の ext4 に置く
* 共有 Steam Library 側へ bind mount し、Steam から通常のライブラリ構成に見せる
* Arch の既定 Steam Library には Proton / Steam Linux Runtime / Steamworks Common Redistributables など Linux 側ランタイムを残す
* Windows でしか使用しないゲームは無理に共有ライブラリへ移さない

---

## 1. 共有 NTFS パーティションを確認

パーティションを確認する。

```bash
lsblk -f
```

対象となる共有 NTFS パーティションについて、以下を確認する。

```text
Device : <shared-ntfs-device>
UUID   : <shared-ntfs-uuid>
```

マウントポイントを作成する。

```bash
sudo mkdir -p <shared-mount>
```

---

## 2. 共有 NTFS を `/etc/fstab` に登録

`/etc/fstab` を編集する。

```bash
sudoedit /etc/fstab
```

以下を追加する。

```fstab
UUID=<shared-ntfs-uuid>  <shared-mount>  ntfs3  rw,uid=<uid>,gid=<gid>,dmask=022,fmask=133,noatime,windows_names,nofail  0  0
```

### オプション

```text
ntfs3
    Linux kernel の NTFS3 driver を使用する。

uid=<uid>,gid=<gid>
    通常ユーザーから書き込み可能にする。

dmask=022
    directory を実質 0755 とする。

fmask=133
    file を実質 0644 とする。

noatime
    access time の不要な更新を抑える。

windows_names
    Windows で使用できないファイル名の作成を防ぐ。

nofail
    共有パーティションのmount failureだけでbootを止めない。
```

`ntfs-3g` は使用しない。

また、Proton から Windows executable を起動するために、NTFS 上のファイルへ Linux の execute bit を付与する必要はない。

設定を反映する。

```bash
sudo mount -a
```

確認する。

```bash
findmnt <shared-mount>
```

期待する filesystem type:

```text
ntfs3
```

---

## 3. SteamLibrary を作成

Steam を終了した状態で作業する。

```bash
mkdir -p <shared-mount>/SteamLibrary/steamapps/common
mkdir -p <shared-mount>/SteamLibrary/steamapps/compatdata
mkdir -p <shared-mount>/SteamLibrary/steamapps/shadercache
```

Arch 側の Steam データディレクトリも用意する。

```bash
mkdir -p "$HOME/.local/share/Steam/steamapps/compatdata"
mkdir -p "$HOME/.local/share/Steam/steamapps/shadercache"
```

実体:

```text
$HOME/.local/share/Steam/steamapps/compatdata
$HOME/.local/share/Steam/steamapps/shadercache
```

---

## 4. `compatdata` を ext4 から bind mount

`/etc/fstab` に以下を追加する。

```fstab
$HOME/.local/share/Steam/steamapps/compatdata  <shared-mount>/SteamLibrary/steamapps/compatdata  none  bind  0  0
```

### 注意

`/etc/fstab` では通常 `$HOME` は展開されない。

実際に設定するときは `$HOME` の実パスへ置き換える。

例:

```text
/home/<username>/.local/share/Steam/steamapps/compatdata
```

Steam からは以下に見える。

```text
<shared-mount>/SteamLibrary/steamapps/compatdata
```

実データは Arch 側の ext4 に保存される。

```text
$HOME/.local/share/Steam/steamapps/compatdata
```

---

## 5. `shadercache` を ext4 から bind mount

同様に `/etc/fstab` へ追加する。

```fstab
$HOME/.local/share/Steam/steamapps/shadercache  <shared-mount>/SteamLibrary/steamapps/shadercache  none  bind  0  0
```

実際の `/etc/fstab` では `$HOME` を実パスに置き換える。

実体:

```text
$HOME/.local/share/Steam/steamapps/shadercache
```

Steam から見えるパス:

```text
<shared-mount>/SteamLibrary/steamapps/shadercache
```

---

## 6. mount を反映

Steam が終了していることを確認してから実行する。

```bash
sudo mount -a
```

確認:

```bash
findmnt <shared-mount>
findmnt <shared-mount>/SteamLibrary/steamapps/compatdata
findmnt <shared-mount>/SteamLibrary/steamapps/shadercache
```

`compatdata` と `shadercache` がそれぞれ Arch 側 Steam ディレクトリから bind mount されていれば完了。

再起動後も同じ状態になることを確認する。

---

## 7. Arch Steam に共有ライブラリを登録

Arch で Steam を起動する。

Steam の:

```text
Settings
  → Storage
```

から Steam Library を追加する。

追加するパス:

```text
<shared-mount>/SteamLibrary
```

以後、Windows / Arch で共有したいゲームのインストール先にはこのライブラリを使用する。

---

## 8. Arch 側の既存ゲームを移動

既存ゲームについては、ファイルマネージャや `mv` で直接移動せず、Steam の Storage 管理から移動する。

移動元:

```text
$HOME/.local/share/Steam
```

移動先:

```text
<shared-mount>/SteamLibrary
```

Steam 自身に移動させることで、

```text
steamapps/common/
appmanifest_*.acf
```

などの整合性を保つ。

---

## 9. Arch 既定ライブラリを整理

移動完了後、Arch 側の既定 Steam Library には基本的に共有対象ゲーム本体を残さない。

主に以下のような Linux 側ランタイムを残す。

```text
Proton Experimental
Steam Linux Runtime
Steamworks Common Redistributables
```

役割分担:

```text
Arch ext4
    ↓
Linux / Proton runtime
compatdata
shadercache

共有 NTFS
    ↓
Windows game payload
共有するゲーム本体
```

残っている appmanifest を確認する場合:

```bash
for mf in "$HOME/.local/share/Steam/steamapps"/appmanifest_*.acf; do
    [ -e "$mf" ] || continue

    appid=$(awk -F'"' '/"appid"/ {print $4; exit}' "$mf")
    name=$(awk -F'"' '/"name"/ {print $4; exit}' "$mf")

    printf '%s\t%s\n' "$appid" "$name"
done
```

意図していないゲームの manifest やゲーム本体が残っていないか確認する。

---

## 10. Windows 側の Steam を設定

Arch 側の作業が終わったら Windows を起動する。

Steam の:

```text
Settings
  → Storage
```

から、共有 NTFS 上の `SteamLibrary` を登録する。

```text
<windows-drive>\SteamLibrary
```

重要なのは、Linux で:

```text
<shared-mount>/SteamLibrary
```

として使用しているものと**同じ SteamLibrary ディレクトリ**を登録すること。

---

## 11. Windows 側の既存ゲームを移動

Windows 側の既存 Steam Library に入っているゲームについても、Steam の Storage UI を使って移動する。

共有したいゲーム:

```text
Windows側既存ライブラリ
        ↓
<windows-drive>\SteamLibrary
```

Windows でしか使用しないゲームは移動しなくてよい。

つまり:

```text
Windows / Arch の両方で使う
    → 共有NTFSのSteamLibrary

Windowsでしか使わない
    → Windows側専用ライブラリ

Linux / Proton runtime
    → Arch ext4
```

と分ける。

---

## 12. 最終状態

### 共有 NTFS

```text
<shared-mount>/SteamLibrary/
└── steamapps/
    ├── appmanifest_*.acf
    ├── common/
    │   ├── Game A/
    │   ├── Game B/
    │   └── ...
    │
    ├── compatdata/
    │   └── bind mount → Arch ext4
    │
    └── shadercache/
        └── bind mount → Arch ext4
```

### Arch

```text
$HOME/.local/share/Steam/steamapps/
├── common/
│   ├── Proton*/
│   ├── SteamLinuxRuntime*/
│   └── Steamworks*/
│
├── compatdata/
│   └── Proton prefix
│
└── shadercache/
    └── shader cache
```

### Windows

```text
<windows-drive>\SteamLibrary
    ↑
    └── Archの<shared-mount>/SteamLibraryと同一
```

---

## 13. 再起動後の確認

Arch 起動後:

```bash
findmnt <shared-mount>
findmnt <shared-mount>/SteamLibrary/steamapps/compatdata
findmnt <shared-mount>/SteamLibrary/steamapps/shadercache
```

Steam:

```text
Settings
  → Storage
```

で:

```text
<shared-mount>/SteamLibrary
```

が認識されていることを確認する。

共有ライブラリ上のゲームを一つ起動し、Proton が正常に動作することも確認する。

---

## 14. 移行後に容量を確認

Arch 側に旧ゲームデータなどを Trash 経由で退避していた場合は、内容を確認してから Trash を空にする。

```bash
gio trash --empty
```

root filesystem の空き容量確認:

```bash
df -h /
```

---

# `/etc/fstab` 関連部分

テンプレート:

```fstab
UUID=<shared-ntfs-uuid>  <shared-mount>  ntfs3  rw,uid=<uid>,gid=<gid>,dmask=022,fmask=133,noatime,windows_names,nofail  0  0

/home/<username>/.local/share/Steam/steamapps/compatdata   <shared-mount>/SteamLibrary/steamapps/compatdata   none  bind  0  0
/home/<username>/.local/share/Steam/steamapps/shadercache  <shared-mount>/SteamLibrary/steamapps/shadercache  none  bind  0  0
```

`<username>` は `$USER` 相当の実ユーザー名へ置き換える。

---

# 設計意図

Steam の Windows ゲーム本体は数十〜数百 GB になることが多いため、Windows と Arch で二重に保持しない。

一方で Proton prefix (`compatdata`) や shader cache は Linux 固有のデータであり、NTFS に保存するメリットがない。

そのため:

```text
Game payload
    → NTFS / Windows・Arch共有

Proton prefix
Shader cache
Linux runtime
    → ext4 / Arch専用
```

という構成にする。

これにより:

* Windows / Arch 間で巨大なゲーム本体を共有できる
* Proton prefix を ext4 上で扱える
* shader cache も ext4 上に置ける
* NTFS 上の Linux permission 問題を最小化できる
* Windows 専用ゲームを無理に共有する必要がない

という構成になる。

