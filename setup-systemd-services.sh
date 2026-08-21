#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "[setup-systemd] ERROR: 予期しない失敗 (line %s)\n" "$LINENO" >&2' ERR

# -----------------------------------------------------------------------------
# 責務:
#   新規Arch Linux環境で、dotfilesが持つ自作systemd unitを配置し、
#   意図的に有効化しているsystemd unitのenable状態を再現する。
#
# POLICY:
#   - --apply時の処理順は「自作unit配置 → daemon-reload → enable」で固定する。
#   - daemon-reloadはunit fileを実際に配置・更新した時だけ実行する。
#   - 配置対象はdotfilesが持つ自作unitとdrop-inだけ。package提供unitはshadowingしない。
#   - package install、user/group変更、unit以外の設定file生成は行わない。
#   - disable / mask / unmask / stop / restart は行わない。
#   - 引数なしはdry-run。file systemもsystemd状態も変更しない。
#
# 使い方:
#   ./setup-systemd-services.sh              # dry-run（既定・何も変更しない）
#   ./setup-systemd-services.sh --apply      # 自作unitを配置し、未enableのunitをenableする
#   ./setup-systemd-services.sh --apply --now  # enable後、inactiveなunitだけstartする
# -----------------------------------------------------------------------------

DOTFILES_DIR="$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly DOTFILES_DIR

# -----------------------------------------------------------------------------
# 自作unitのSSOT
#
#   systemd/system/ 配下の相対pathをそのまま /etc/systemd/system/ へ写す。
#   systemd/user/   配下の相対pathをそのまま ~/.config/systemd/user/ へ写す。
#   UNIT.d/*.conf のdrop-inも同じ規則で配置される。
#
#   systemd関連はGNU Stowでは管理しない。unit file、drop-in、enable状態はすべてこのscriptが持つ。
#   enable状態を表すsymlink（default.target.wants/ 等）はrepositoryへ保存せず、
#   systemctl enable に生成させる。
# -----------------------------------------------------------------------------

readonly CUSTOM_SYSTEM_SRC_DIR="${DOTFILES_DIR}/systemd/system"
readonly CUSTOM_USER_SRC_DIR="${DOTFILES_DIR}/systemd/user"
readonly CUSTOM_SYSTEM_DEST_DIR="/etc/systemd/system"
readonly CUSTOM_USER_DEST_DIR="${HOME}/.config/systemd/user"

# 旧方式のStow package。配置先がここへ解決される間は、移行前とみなして配置しない。
readonly LEGACY_STOW_USER_DIR="${DOTFILES_DIR}/stow/systemd-user"

# -----------------------------------------------------------------------------
# 管理対象unit
#
# 選定基準:
#   - 新規Arch Linux環境でenable状態を明示的に再現する必要があるprimary unitを挙げる。
#   - 他unitの[Install] Also=で連鎖するunitは、親unitだけを挙げる。
#   - packageが/etc/systemd/user配下へ配置するuser unitは対象外とする。
#
# 対象外にしたunit（現在enabledだが明示管理しない）:
#   getty@.service / remote-fs.target / systemd-userdbd.socket
#     ... systemd同梱の90-systemd.presetでenable指定される基盤unit。
#   NetworkManager-dispatcher.service / NetworkManager-wait-online.service
#     ... NetworkManager.serviceのAlso=で連鎖する。
#   clamav-daemon.socket
#     ... clamav-daemon.serviceのAlso=で連鎖する。
#   libvirtd*.socket / virtlockd*.socket / virtlogd*.socket
#     ... libvirtd.serviceのAlso=から連鎖する（-admin側もsocket同士のAlso=で繋がる）。
#   systemd-resolved-monitor.socket / systemd-resolved-varlink.socket
#     ... systemd-resolved.serviceのAlso=で連鎖する。
#   wireplumber.service / xdg-user-dirs.service / gnome-keyring-daemon.socket
#   p11-kit-server.socket / pipewire.socket / pipewire-pulse.socket
#     ... enable symlinkを/etc/systemd/user配下へpackageが配置する。
#   kb-backlight.service
#     ... G512向け自作unitだが、依存していたkeyleds-gitが2026-08-04に削除済みで
#         keyledsctlが存在せず、実質何もせずsuccess終了していたため再構築対象から外した。
#         2026-08-21に現環境のunitと/usr/local/bin/kb-backlightもユーザー操作で撤去済み。
# -----------------------------------------------------------------------------

readonly SYSTEM_UNITS=(
    # Networking
    # NetworkManager-dispatcher.service と NetworkManager-wait-online.service は
    # NetworkManager.service の Also= で連鎖するため挙げない。
    NetworkManager.service
    # Archにはpresetを適用するpacman hookがないため、systemd標準presetがenable指定でも
    # 明示enableが要る。関連socketはAlso=で連鎖する。
    systemd-resolved.service
    systemd-timesyncd.service

    # Security
    ufw.service
    # clamav-daemon.socket は clamav-daemon.service の Also= で連鎖する。
    clamav-daemon.service
    clamav-freshclam.service
    # unit本体はclamav package提供。ExecStartを差し替える手動drop-inだけをdotfilesが持ち、
    # systemd/system/clamav-clamonacc.service.d/override.conf として step 1 で配置される。
    clamav-clamonacc.service

    # Virtualization / container
    docker.service
    # libvirtd.socket / libvirtd-ro / libvirtd-admin / virtlockd* / virtlogd* は
    # libvirtd.service の Also= から連鎖してenableされる。
    libvirtd.service

    # Desktop / display manager
    # [Install]はAlias=display-manager.serviceのみ。display manager選択そのものなので必須。
    sddm.service

    # Hardware
    bluetooth.service
    # [Install]はAlias=のみ。D-Bus activation用のalias作成が目的で、WantedBy=は持たない。
    ratbagd.service

    # Maintenance
    fstrim.timer
)

readonly USER_UNITS=(
    # 自作unit。systemd/user/ssh-agent.service から step 1 で配置され、
    # enable symlink（default.target.wants/）は step 5 の systemctl --user enable が作る。
    ssh-agent.service
)

APPLY=0
START_NOW=0

ENABLED_COUNT=0
ALREADY_COUNT=0
MISSING_COUNT=0
SKIPPED_COUNT=0
STARTED_COUNT=0
FAILED_COUNT=0

INSTALLED_COUNT=0
UPDATED_COUNT=0
ALREADY_INSTALLED_COUNT=0
LEGACY_COUNT=0

# unit fileを実際に配置・更新した時だけdaemon-reloadする。
SYSTEM_RELOAD_NEEDED=0
USER_RELOAD_NEEDED=0

MISSING_UNITS=()

log() {
    printf '[setup-systemd] %s\n' "$*"
}

die() {
    printf '[setup-systemd] ERROR: %s\n' "$*" >&2
    exit 1
}

log_unit() {
    local scope="$1"
    local message="$2"

    # [system] / [user] は幅を揃え、幅を超える [systemd] はそのまま1スペース区切りにする。
    printf '%-8s %s\n' "[${scope}]" "$message"
}

log_summary() {
    printf '[summary] %s\n' "$*"
}

usage() {
    cat <<'EOF'
使い方:
  ./setup-systemd-services.sh                # dry-run（既定・systemd状態を変更しない）
  ./setup-systemd-services.sh --apply        # 未enableのunitだけenableする
  ./setup-systemd-services.sh --apply --now  # enable後、inactiveなunitだけstartする
  ./setup-systemd-services.sh --help

このscriptはdisable / mask / unmask / stop / restart を行わない。
EOF
}

# dotfiles側の自作unit fileを、src rootからの相対pathでNUL区切り列挙する。
collect_unit_files() {
    local root="$1"

    [[ -d "$root" ]] || return 0

    find "$root" -type f -printf '%P\0' | sort -z
}

# pathの解決先がdir自身、またはdir配下かを判定する。
resolves_into() {
    local path="$1"
    local dir="$2"
    local resolved

    resolved="$(readlink -f -- "$path" 2>/dev/null)" || return 1
    [[ -n "$resolved" ]] || return 1

    case "$resolved" in
        "$dir" | "$dir"/*)
            return 0
            ;;
    esac

    return 1
}

install_one_unit_file() {
    local scope="$1"
    local rel_label="$2"
    local src="$3"
    local dest="$4"
    local dest_dir=""
    local action="install"
    local past="installed"
    local replace_legacy=0
    local -a cmd=()

    dest_dir="$(dirname -- "$dest")"

    # 旧Stow方式が残っている間に配置すると、tree-folding symlink越しにdotfiles自身を書き換える。
    # 中身全体へ影響するため自動では外さず、移行手順を示して止める。
    if resolves_into "$dest_dir" "$LEGACY_STOW_USER_DIR"; then
        log_unit "systemd" "legacy Stow-managed symlink detected: ${dest_dir}"
        log_unit "systemd" "  旧package stow/systemd-user を指すため配置しない: ${rel_label}"
        log_unit "systemd" "  先に stow -D -d ${DOTFILES_DIR}/stow -t \"\$HOME\" systemd-user を実行すること"
        LEGACY_COUNT=$((LEGACY_COUNT + 1))
        return 0
    fi

    # 配置先が別経路でdotfiles内へ解決される場合も、二重管理になるので触らない。
    if resolves_into "$dest_dir" "$DOTFILES_DIR"; then
        log_unit "systemd" "skip（配置先がdotfiles内へ解決される: ${dest_dir}）: ${rel_label}"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        return 0
    fi

    if [[ -L "$dest" ]]; then
        if resolves_into "$dest" "$LEGACY_STOW_USER_DIR"; then
            # Stowが張ったfile symlink。実体はdotfiles内に残るのでunlinkして実fileへ置き換える。
            replace_legacy=1
            action="update"
            past="updated"
        else
            # 素性の分からないsymlinkは破壊しない。
            log_unit "systemd" "skip（想定外のsymlinkのため触らない: $(readlink -- "$dest")）: ${rel_label}"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            return 0
        fi
    fi

    # 同一内容なら書き換えない（不要なdaemon-reloadも避ける）。
    if [[ "$replace_legacy" -eq 0 && -f "$dest" ]] && cmp -s -- "$src" "$dest"; then
        log_unit "systemd" "already installed: ${rel_label} -> ${dest}"
        ALREADY_INSTALLED_COUNT=$((ALREADY_INSTALLED_COUNT + 1))
        return 0
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        action="update"
        past="updated"
    fi

    if [[ "$APPLY" -eq 0 ]]; then
        if [[ "$replace_legacy" -eq 1 ]]; then
            log_unit "systemd" "would replace legacy Stow-managed symlink: ${rel_label} -> ${dest}"
        else
            log_unit "systemd" "would ${action}: ${rel_label} -> ${dest}"
        fi
    else
        # installはsymlinkを辿ってしまうため、置き換え対象のsymlinkは先に外す。
        if [[ "$replace_legacy" -eq 1 ]]; then
            if [[ "$scope" == "user" ]]; then
                cmd=(unlink -- "$dest")
            else
                cmd=(sudo unlink -- "$dest")
            fi

            if ! "${cmd[@]}"; then
                log_unit "systemd" "failed to unlink legacy symlink: ${dest}"
                FAILED_COUNT=$((FAILED_COUNT + 1))
                return 0
            fi

            log_unit "systemd" "unlinked legacy Stow-managed symlink: ${dest}"
        fi

        if [[ "$scope" == "user" ]]; then
            cmd=(install -Dm644 -- "$src" "$dest")
        else
            cmd=(sudo install -D -o root -g root -m 644 -- "$src" "$dest")
        fi

        if ! "${cmd[@]}"; then
            log_unit "systemd" "failed to ${action}: ${rel_label} -> ${dest}"
            FAILED_COUNT=$((FAILED_COUNT + 1))
            return 0
        fi

        log_unit "systemd" "${past}: ${rel_label} -> ${dest}"
    fi

    if [[ "$action" == "update" ]]; then
        UPDATED_COUNT=$((UPDATED_COUNT + 1))
    else
        INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
    fi

    if [[ "$scope" == "user" ]]; then
        USER_RELOAD_NEEDED=1
    else
        SYSTEM_RELOAD_NEEDED=1
    fi
}

install_custom_units() {
    local scope="$1"
    local src_dir="$2"
    local dest_dir="$3"
    local rel_path=""
    local found=0

    if [[ ! -d "$src_dir" ]]; then
        log_unit "systemd" "custom ${scope} units: なし（${src_dir#"${DOTFILES_DIR}/"} が無い）"
        return 0
    fi

    while IFS= read -r -d '' rel_path; do
        found=1
        install_one_unit_file \
            "$scope" \
            "${src_dir#"${DOTFILES_DIR}/"}/${rel_path}" \
            "${src_dir}/${rel_path}" \
            "${dest_dir}/${rel_path}"
    done < <(collect_unit_files "$src_dir")

    if [[ "$found" -eq 0 ]]; then
        log_unit "systemd" "custom ${scope} units: なし（${src_dir#"${DOTFILES_DIR}/"} が空）"
    fi
}

# unit fileを実際に配置・更新した時だけ実行する。dry-runでは実行しない。
run_daemon_reload() {
    local scope="$1"
    local needed="$2"
    local -a cmd=()

    [[ "$needed" -eq 1 ]] || return 0

    if [[ "$APPLY" -eq 0 ]]; then
        log_unit "systemd" "would run daemon-reload (${scope})"
        return 0
    fi

    if [[ "$scope" == "user" ]]; then
        cmd=(systemctl --user daemon-reload)
    else
        cmd=(sudo systemctl daemon-reload)
    fi

    if "${cmd[@]}"; then
        log_unit "systemd" "daemon-reload: ${scope}"
    else
        log_unit "systemd" "failed to daemon-reload: ${scope}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
}

# user manager経由でしかuser unitは扱えない。TTY等で不在なら誤判定を避けて全体skipする。
user_manager_available() {
    systemctl --user show --property=Version --value >/dev/null 2>&1
}

unit_exists() {
    local scope="$1"
    local unit="$2"

    if [[ "$scope" == "user" ]]; then
        systemctl --user cat -- "$unit" >/dev/null 2>&1
    else
        systemctl cat -- "$unit" >/dev/null 2>&1
    fi
}

unit_enable_state() {
    local scope="$1"
    local unit="$2"
    local state=""

    if [[ "$scope" == "user" ]]; then
        state="$(systemctl --user is-enabled -- "$unit" 2>/dev/null)" || true
    else
        state="$(systemctl is-enabled -- "$unit" 2>/dev/null)" || true
    fi

    printf '%s' "${state:-unknown}"
}

unit_active_state() {
    local scope="$1"
    local unit="$2"
    local state=""

    if [[ "$scope" == "user" ]]; then
        state="$(systemctl --user is-active -- "$unit" 2>/dev/null)" || true
    else
        state="$(systemctl is-active -- "$unit" 2>/dev/null)" || true
    fi

    printf '%s' "${state:-unknown}"
}

# --now専用。restart / stop はせず、inactiveなunitだけをstartする。
maybe_start_unit() {
    local scope="$1"
    local unit="$2"
    local state
    local -a cmd=()

    [[ "$START_NOW" -eq 1 ]] || return 0

    state="$(unit_active_state "$scope" "$unit")"
    if [[ "$state" != "inactive" ]]; then
        log_unit "$scope" "start skip (${state}): ${unit}"
        return 0
    fi

    if [[ "$APPLY" -eq 0 ]]; then
        log_unit "$scope" "would start: ${unit}"
        return 0
    fi

    if [[ "$scope" == "user" ]]; then
        cmd=(systemctl --user start -- "$unit")
    else
        cmd=(sudo systemctl start -- "$unit")
    fi

    if "${cmd[@]}"; then
        log_unit "$scope" "started: ${unit}"
        STARTED_COUNT=$((STARTED_COUNT + 1))
    else
        log_unit "$scope" "failed to start: ${unit}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
}

enable_unit() {
    local scope="$1"
    local unit="$2"
    local from_runtime="${3:-0}"
    local note=""
    local -a cmd=()

    # --runtimeを付けないenableなので、enabled-runtimeからでも永続enableへ昇格する。
    if [[ "$from_runtime" -eq 1 ]]; then
        note=" (enabled-runtime -> persistent)"
    fi

    if [[ "$APPLY" -eq 0 ]]; then
        log_unit "$scope" "would enable${note}: ${unit}"
        ENABLED_COUNT=$((ENABLED_COUNT + 1))
        maybe_start_unit "$scope" "$unit"
        return 0
    fi

    if [[ "$scope" == "user" ]]; then
        cmd=(systemctl --user enable -- "$unit")
    else
        cmd=(sudo systemctl enable -- "$unit")
    fi

    if "${cmd[@]}"; then
        log_unit "$scope" "enabled${note}: ${unit}"
        ENABLED_COUNT=$((ENABLED_COUNT + 1))
        maybe_start_unit "$scope" "$unit"
    else
        log_unit "$scope" "failed to enable${note}: ${unit}"
        FAILED_COUNT=$((FAILED_COUNT + 1))
    fi
}

process_unit() {
    local scope="$1"
    local unit="$2"
    local state

    # 新環境ではpackage未installでunitが無いことがある。abortせず記録して継続する。
    if ! unit_exists "$scope" "$unit"; then
        log_unit "$scope" "missing: ${unit}"
        MISSING_UNITS+=("${scope}: ${unit}")
        MISSING_COUNT=$((MISSING_COUNT + 1))
        return 0
    fi

    state="$(unit_enable_state "$scope" "$unit")"

    case "$state" in
        enabled)
            log_unit "$scope" "already enabled: ${unit}"
            ALREADY_COUNT=$((ALREADY_COUNT + 1))
            maybe_start_unit "$scope" "$unit"
            ;;
        enabled-runtime)
            # 再起動で消える一時的なenable。desired stateは永続enableなので昇格させる。
            enable_unit "$scope" "$unit" 1
            ;;
        disabled)
            enable_unit "$scope" "$unit"
            ;;
        masked | masked-runtime)
            # unmaskはこのscriptの責務外。意図的なmaskを黙って壊さない。
            log_unit "$scope" "masked (手動対応が要る・unmaskしない): ${unit}"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            ;;
        *)
            # static / alias / indirect / linked / generated / transient / unknown
            log_unit "$scope" "skip (${state}): ${unit}"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            ;;
    esac
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply)
            APPLY=1
            shift
            ;;
        --now)
            START_NOW=1
            shift
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            usage
            die "不明な引数: $1"
            ;;
    esac
done

if [[ "$(id -u)" -eq 0 ]]; then
    die "rootで直接実行しない。一般ユーザーで実行すること（system unitへは sudo systemctl を使う）。"
fi

if [[ "$APPLY" -eq 1 ]]; then
    log "mode: apply（自作unitを配置し、未enableのunitをenableする）"
else
    log "mode: dry-run（file systemもsystemd状態も変更しない。実変更には --apply が要る）"
fi

if [[ "$START_NOW" -eq 1 ]]; then
    log "--now: inactiveなunitだけstartする（restart / stop はしない）"
fi

# 実変更時だけ、処理の途中でpassword入力待ちが挟まらないよう先に認証しておく。
if [[ "$APPLY" -eq 1 ]]; then
    sudo -v || die "sudo認証に失敗した。system unitの配置とenableはできない。"
fi

# 新規環境でunit fileが未配置でもenableまで到達できるよう、配置→reload→enableの順で進める。
log "step 1/6: custom system / user unitとdrop-inの配置"
install_custom_units "system" "$CUSTOM_SYSTEM_SRC_DIR" "$CUSTOM_SYSTEM_DEST_DIR"
install_custom_units "user" "$CUSTOM_USER_SRC_DIR" "$CUSTOM_USER_DEST_DIR"

log "step 2/6: system daemon-reload"
if [[ "$SYSTEM_RELOAD_NEEDED" -eq 0 ]]; then
    log_unit "systemd" "system unit fileに変更なし: daemon-reloadは不要"
else
    run_daemon_reload "system" "$SYSTEM_RELOAD_NEEDED"
fi

log "step 3/6: user daemon-reload"
if [[ "$USER_RELOAD_NEEDED" -eq 0 ]]; then
    log_unit "systemd" "user unit fileに変更なし: daemon-reloadは不要"
elif ! user_manager_available; then
    log_unit "systemd" "user daemon-reload skip（systemd user managerを利用できない）"
else
    run_daemon_reload "user" "$USER_RELOAD_NEEDED"
fi

log "step 4/6: system unitのenable状態"
for unit in "${SYSTEM_UNITS[@]}"; do
    process_unit "system" "$unit"
done

log "step 5/6: user unitのenable状態"
if user_manager_available; then
    for unit in "${USER_UNITS[@]}"; do
        process_unit "user" "$unit"
    done
else
    log_unit "user" "systemd user managerを利用できないためuser unitをskipした"
    SKIPPED_COUNT=$((SKIPPED_COUNT + ${#USER_UNITS[@]}))
fi

echo
log "step 6/6: summary"

if [[ "$APPLY" -eq 1 ]]; then
    log_summary "installed: ${INSTALLED_COUNT}"
    log_summary "updated: ${UPDATED_COUNT}"
else
    log_summary "would install: ${INSTALLED_COUNT}"
    log_summary "would update: ${UPDATED_COUNT}"
fi
log_summary "already installed: ${ALREADY_INSTALLED_COUNT}"
log_summary "legacy Stow-managed: ${LEGACY_COUNT}"

if [[ "$APPLY" -eq 1 ]]; then
    log_summary "enabled: ${ENABLED_COUNT}"
else
    log_summary "would enable: ${ENABLED_COUNT}"
fi
log_summary "already enabled: ${ALREADY_COUNT}"
log_summary "missing: ${MISSING_COUNT}"
log_summary "skipped: ${SKIPPED_COUNT}"
if [[ "$START_NOW" -eq 1 ]]; then
    log_summary "started: ${STARTED_COUNT}"
fi
log_summary "failed: ${FAILED_COUNT}"

if [[ "${#MISSING_UNITS[@]}" -gt 0 ]]; then
    log_summary "missing units（packageが未installの可能性・このscriptはinstallしない）:"
    printf '[summary]   %s\n' "${MISSING_UNITS[@]}"
fi

if [[ "$LEGACY_COUNT" -gt 0 ]]; then
    log_summary "旧Stow方式が残っているためuser unitを配置していない。移行手順:"
    log_summary "  1) stow -D -d ${DOTFILES_DIR}/stow -t \"\$HOME\" systemd-user"
    log_summary "  2) ${BASH_SOURCE[0]} --apply"
    log_summary "  3) 確認後に rm -rf ${DOTFILES_DIR}/stow/systemd-user"
fi

# missingはbootstrap途中として許容し、実際のenable/start失敗だけを異常終了にする。
if [[ "$FAILED_COUNT" -gt 0 ]]; then
    exit 1
fi

exit 0
