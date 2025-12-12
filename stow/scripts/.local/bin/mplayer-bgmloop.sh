#!/usr/bin/env bash
# monitor.sh
# 使い方: ./monitor.sh -- max-restarts 5 -- sleep 2 -- /path/to/your_program arg1 arg2
# または簡単に: ./monitor.sh -- /path/to/your_program

set -u
PROG_ARGS=(mplayer ~/Downloads/Morning.mp3)
MAX_RESTARTS=0   # 0 = 無制限
BASE_DELAY=1     # 再起動時の基礎待ち秒（バックオフのベース）
DELAY_MULTIPLIER=2

print_usage(){
  cat <<EOF
Usage: $0 [--max-restarts N] [--base-delay S] [--multiplier M] -- command [args...]
  --max-restarts N   : 0 = 無制限（デフォルト）。短時間で何度も再起動させたくないときに制限。
  --base-delay S     : 再起動待ちの基礎秒（デフォルト 1）。
  --multiplier M     : 連続再起動時の遅延倍率（デフォルト 2）。
  --                  : 以降が実行するコマンド。
EOF
}

# 引数解析（簡易）
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-restarts)
      MAX_RESTARTS="$2"; shift 2;;
    --base-delay)
      BASE_DELAY="$2"; shift 2;;
    --multiplier)
      DELAY_MULTIPLIER="$2"; shift 2;;
    --help|-h)
      print_usage; exit 0;;
    --)
      shift; PROG_ARGS=( "$@" ); break;;
    *)
      # もし -- が省略されていれば、最初の未知オプション以降をコマンドとみなす
      PROG_ARGS=( "$@" ); break;;
  esac
done

if [[ ${#PROG_ARGS[@]} -eq 0 ]]; then
  echo "実行するコマンドを指定してください。"
  print_usage
  exit 1
fi

# ログ関数
log(){
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# 子プロセスPIDを保持
CHILD_PID=0
SHUTDOWN=0

# シグナル受け取り -> 子へ転送して自分は終了フラグを立てる
_on_signal(){
  sig="$1"
  log "監視プロセスがシグナル ${sig} を受け取りました。子プロセスへ転送します..."
  SHUTDOWN=1
  if [[ $CHILD_PID -ne 0 ]]; then
    kill -"$sig" "$CHILD_PID" 2>/dev/null || true
  fi
}

trap '_on_signal INT' INT
trap '_on_signal TERM' TERM
trap '_on_signal HUP' HUP
# Ctrl-\ (QUIT) 等も必要なら追加

restart_count=0
consecutive_restarts=0

while true; do
  if [[ $SHUTDOWN -eq 1 ]]; then
    log "停止フラグ検出。監視を終了します。"
    exit 0
  fi

  # 実行
  log "起動: ${PROG_ARGS[*]}"
  "${PROG_ARGS[@]}" &
  CHILD_PID=$!
  start_ts=$(date +%s)

  # 子が終了するのを待つ
  wait "$CHILD_PID"
  exit_code=$?
  end_ts=$(date +%s)
  runtime=$((end_ts - start_ts))

  log "プロセス PID=${CHILD_PID} が終了しました (終了コード=${exit_code})。実行時間=${runtime}s"

  CHILD_PID=0

  # 終了理由に合わせた対処（任意）
  # 例えば特定の終了コードで監視を止めたい場合はここで判定できる

  # 再起動カウント管理
  restart_count=$((restart_count+1))
  if [[ $runtime -ge 5 ]]; then
    # 比較的長時間動いていたら連続クラッシュとみなさない
    consecutive_restarts=0
  else
    consecutive_restarts=$((consecutive_restarts+1))
  fi

  if [[ $MAX_RESTARTS -gt 0 && $restart_count -ge $MAX_RESTARTS ]]; then
    log "最大再起動回数 (${MAX_RESTARTS}) に到達しました。監視を終了します。"
    exit 0
  fi

  # バックオフ遅延計算（指数的）
  delay=$BASE_DELAY
  if [[ $consecutive_restarts -gt 1 ]]; then
    # DELAY_MULTIPLIER を累乗
    exp=$((consecutive_restarts - 1))
    # 累乗計算（整数）
    pow=1
    i=0
    while [[ $i -lt $exp ]]; do
      pow=$((pow * DELAY_MULTIPLIER))
      i=$((i+1))
    done
    delay=$((BASE_DELAY * pow))
  fi

  log "再起動前に ${delay}s 待ちます (連続再起動=${consecutive_restarts})..."
  # 待機中でもシグナルで抜けられるよう小刻みにsleep
  slept=0
  while [[ $slept -lt $delay ]]; do
    if [[ $SHUTDOWN -eq 1 ]]; then
      log "停止フラグ検出。監視を終了します。"
      exit 0
    fi
    sleep 1
    slept=$((slept+1))
  done

  log "再起動します。"
done
