# Arch Linux Secure Boot 運用手順

このディレクトリには、Arch Linux環境でGRUBを維持したままSecure Bootを運用するための設定・スクリプトを置いている。

## 現在の構成

```text
UEFI Secure Boot
  ↓ 自前db鍵で署名確認
arch-grub-secure
  ├─ Arch Linux
  ├─ Arch Linux Zen
  ├─ Arch Linux LTS
  └─ Windows Boot Manager
```

* ブートローダー: GRUB
* ESP: `/boot/efi`
* Secure Boot管理: `sbctl`
* 自動署名対象:

  * `/boot/vmlinuz-linux`
  * `/boot/vmlinuz-linux-zen`
  * `/boot/vmlinuz-linux-lts`
  * `/boot/efi/EFI/arch-grub-secure/grubx64.efi`
* Microsoft 2011 / 2023証明書とASUS内蔵鍵を併用
* WindowsはGRUBからチェインロード可能

> NOTE:
> 現在の構成ではUEFIが署名済みGRUBを検証する。
> 独立したinitramfsまで含めた完全な信頼チェーンではない。
> 完全性をさらに高める場合は、将来的にUKI化を検討する。

---

## 関連ファイル

```text
setup-system.sh
system/secureboot/
├── README.md
├── sbctl.conf
├── secureboot-backup
├── secureboot-restore
├── secureboot-refresh-grub
└── secureboot-grub.hook
```

配置先:

```text
/etc/sbctl/sbctl.conf
/etc/pacman.d/hooks/95-secureboot-grub.hook
/usr/local/sbin/secureboot-backup
/usr/local/sbin/secureboot-restore
/usr/local/sbin/secureboot-refresh-grub
```

---

# 通常運用

## Secure Boot状態の確認

```bash
sudo sbctl status
```

正常時:

```text
Setup Mode:   Disabled
Secure Boot:  Enabled
```

## 署名状態の確認

```bash
sudo sbctl verify
```

すべてのGRUB・カーネルが `signed` なら正常。

---

# パッケージ更新時の自動署名

## カーネル更新

カーネル更新時は、mkinitcpioのsbctlポストフックが自動署名する。

```text
カーネル更新
→ mkinitcpio実行
→ sbctlポストフック
→ カーネル署名
```

通常は追加操作不要。

## GRUB更新

`grub` パッケージ更新時は、独自pacmanフックが次を自動実行する。

```text
既存の署名済みGRUBを一時退避
→ arch-grub-secureを再生成
→ sbctlで署名
→ 署名確認
→ 成功時に一時バックアップ削除
```

手動確認:

```bash
sudo /usr/local/sbin/secureboot-refresh-grub
sudo sbctl verify
```

> LANDMINE:
> `grub-install` を手動実行した場合、生成されたGRUBは未署名になる。
> 手動実行後は必ず再署名すること。

```bash
sudo /usr/local/sbin/secureboot-refresh-grub
```

---

# dotfilesからシステム設定を配置する

```bash
cd ~/dotfiles
./setup-system.sh
```

この処理では以下を行う。

* 必要パッケージの導入
* `sbctl.conf` の配置
* Secure Boot関連スクリプトの配置
* GRUB更新用pacmanフックの配置

Secure Boot秘密鍵の復元・UEFIへの鍵登録・Secure Boot有効化は自動実行しない。

---

# Secure Boot状態のバックアップ

バックアップには秘密鍵が含まれるため、公開Gitや共有クラウドへ置かないこと。

```bash
sudo secureboot-backup /linuxshare/SecureBoot
```

生成物:

```text
sbctl-state-YYYYMMDD-HHMMSS.tar.gz
sbctl-state-YYYYMMDD-HHMMSS.tar.gz.sha256
```

バックアップには `/var/lib/sbctl` 全体が含まれる。

* PK / KEK / db秘密鍵
* Owner GUID
* 署名対象ファイルDB

バックアップ確認:

```bash
sudo tar -tzf /linuxshare/SecureBoot/sbctl-state-*.tar.gz
sudo sha256sum -c /linuxshare/SecureBoot/sbctl-state-*.tar.gz.sha256
```

---

# 新規インストール・復旧時

## 1. dotfilesを配置

```bash
git clone <dotfiles-repository>
cd dotfiles

./setup.sh
./setup-system.sh
```

## 2. sbctl状態を復元

```bash
sudo secureboot-restore \
  /linuxshare/SecureBoot/sbctl-state-YYYYMMDD-HHMMSS.tar.gz
```

復元処理では次を行う。

* 現在のsbctl状態を退避
* 保存済みsbctl状態を復元
* Secure Boot用GRUBを再生成・署名
* 存在するカーネルを署名・追跡登録
* 全署名対象を検証

復元後:

```bash
sudo sbctl status
sudo sbctl verify
```

---

# UEFIへ鍵を再登録する場合

UEFI設定の初期化やマザーボード交換などで鍵が消えた場合のみ実施する。

## 1. UEFIでPlatform Keyだけを削除

UEFI設定で次を実行する。

```text
Delete Platform Key
```

次は触らない。

```text
Clear All Secure Boot Keys
Restore Factory Keys
Install Default Keys
```

Arch起動後に確認:

```bash
sudo sbctl status
```

期待値:

```text
Setup Mode:   Enabled
Secure Boot:  Disabled
```

## 2. 自前鍵・Microsoft鍵・ファームウェア内蔵鍵を登録

```bash
sudo sbctl enroll-keys \
  --microsoft \
  --firmware-builtin=db,KEK
```

`immutable` エラーが出た場合のみ、表示されたKEK/db変数から属性を外して再実行する。

```bash
sudo chattr -i \
  /sys/firmware/efi/efivars/KEK-* \
  /sys/firmware/efi/efivars/db-*
```

> LANDMINE:
> efivars全体に対して無差別に`chattr`しないこと。
> 必要なKEK/db変数だけを対象にする。

登録後:

```bash
sudo sbctl status
sudo sbctl list-enrolled-keys
```

期待値:

```text
Setup Mode:   Disabled
Secure Boot:  Disabled
```

## 3. UEFIでSecure Bootを有効化

ASUS UEFIでは概ね次の設定を使用する。

```text
Launch CSM:        Disabled
OS Type:           Windows UEFI Mode
Secure Boot Mode:  Custom
Secure Boot:       Enabled
```

鍵管理画面では、既存鍵を削除・工場出荷状態へ戻さないこと。

起動後:

```bash
sudo sbctl status
```

期待値:

```text
Setup Mode:   Disabled
Secure Boot:  Enabled
```

---

# 動作確認

## Arch起動確認

```bash
sudo sbctl status
sudo sbctl verify
```

## Windows起動確認

GRUBメニューからWindows Boot Managerを選択し、Windowsが起動することを確認する。

## 自動署名確認

カーネル側:

```bash
sudo mkinitcpio -P
sudo sbctl verify
```

GRUB側:

```bash
sudo pacman -S grub
sudo sbctl verify
```

---

# 緊急時

## Secure Boot有効後にArchが起動しない

1. UEFI設定でSecure Bootを一時無効化する
2. 既存のGRUBまたはVentoy USBから起動する
3. 次を確認する

```bash
sudo sbctl status
sudo sbctl verify
sudo /usr/local/sbin/secureboot-refresh-grub
```

## GRUB更新に失敗した

`secureboot-refresh-grub` は、処理失敗時に直前の署名済みGRUBを自動復元する。

一時バックアップ先:

```text
/var/lib/secureboot-backups/
```

## 秘密鍵を失った

保存済みバックアップから復元する。

```bash
sudo secureboot-restore \
  /linuxshare/SecureBoot/sbctl-state-YYYYMMDD-HHMMSS.tar.gz
```

バックアップが存在しない場合は、新しい鍵を作成し、UEFIをSetup Modeへ切り替えて再登録する必要がある。

---

# 注意事項

* Secure Boot秘密鍵をdotfilesリポジトリへ入れない
* `Install Default Keys` や `Restore Factory Keys` を安易に実行しない
* 手動で`grub-install`した後は必ず再署名する
* Secure Boot設定変更前にVentoyなどの復旧USBを準備する
* WindowsでBitLockerを使用している場合、回復キーを事前に確保する
* マザーボード交換時はUEFI鍵の再登録が必要

