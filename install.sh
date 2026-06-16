#!/usr/bin/env bash
#
# emacs-plus を takaxp/ns-inline-patch 付きでビルドする。
# - リポジトリ内の build.yml を HOMEBREW_EMACS_PLUS_BUILD_CONFIG で指定
# - パッチ(url / sha256)は build.yml に定義し、ビルド時に formula が取得・検証する
# - ボトルを避けて必ずソースからビルド(でないとパッチが適用されない)
#
# 使い方: ./install.sh <command>   (make <command> でも可。help を参照)
#
set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

FORMULA="emacs-plus@30"          # Emacs バージョン更新時はここだけ変える(例: emacs-plus@31)
TAP="d12frosted/emacs-plus"

# build.yml を repo 内のものに固定(~/.config を汚さない)
export HOMEBREW_EMACS_PLUS_BUILD_CONFIG="$SCRIPT_DIR/build.yml"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

require_brew() { command -v brew >/dev/null 2>&1 || die "Homebrew が見つかりません。https://brew.sh からインストールしてください。"; }

do_help() {
  cat <<EOS
使い方: ./install.sh <command>   (make <command> でも可)

  install      $FORMULA を ns-inline パッチ付きでビルド (既定)
  uninstall    $FORMULA を削除
  reinstall    uninstall してから install
EOS
}

do_uninstall() {
  require_brew
  if brew list --formula 2>/dev/null | grep -qx "$FORMULA"; then
    brew uninstall "$FORMULA"
  else
    log "$FORMULA は未インストールです。"
  fi
}

# /Applications/Emacs.app エイリアスを作成する。
# 再インストール時に既存ファイルが残っていると osascript の make alias が
# 同名ファイルの存在で失敗するため、先に既存を除去してから作成する。
create_app_alias() {
  local prefix
  prefix="$(brew --prefix "$FORMULA")"
  rm -f "/Applications/Emacs.app"
  log "/Applications/Emacs.app エイリアスを作成します"
  osascript -e 'tell application "Finder" to make alias file to posix file "'"$prefix"'/Emacs.app" at posix file "/Applications" with properties {name:"Emacs.app"}' >/dev/null \
    || warn "/Applications へのエイリアス作成に失敗しました。手動で作成してください。"
}

print_next_steps() {
  cat <<'EOS'

--- 次のステップ ---

init.el に以下を追加してインライン入力を有効化:
     (when (and (memq window-system '(ns nil))
                (fboundp 'mac-get-current-input-source))
       (when (version< "27.0" emacs-version)
         (custom-set-variables
          '(mac-default-input-source "com.apple.inputmethod.Kotoeri.RomajiTyping.Japanese")))
       (mac-input-method-mode 1))

   確認コマンド: M-x mac-ime-input-source-list
EOS
}

do_install() {
  require_brew

  # --- tap ---
  if ! brew tap | grep -qx "$TAP"; then
    log "tap を追加: $TAP"
    brew tap "$TAP"
  fi

  # --- 既存インストールがあれば uninstall(公式が reinstall を非推奨にしているため) ---
  if brew list --formula 2>/dev/null | grep -qx "$FORMULA"; then
    log "既存の $FORMULA を uninstall します(reinstall はオプションが壊れやすいため)"
    brew uninstall "$FORMULA"
  fi

  # --- ビルド(必ずソースから。ボトルだと build.yml のパッチが適用されない) ---
  log "build.yml: $HOMEBREW_EMACS_PLUS_BUILD_CONFIG"
  log "$FORMULA をソースからビルドします"

  # brew install の終了コードを拾う(post_install のみの失敗を本体ビルド失敗と区別するため)。
  # emacs-plus の post_install はビルド直後に codesign --deep で再署名するが、フルビルド中は
  # まれに一過性で失敗する。その場合 keg 自体は入っているので、post_install をやり直せば直る。
  set +e
  brew install --build-from-source "$FORMULA"
  brew_status=$?
  set -e

  if [[ "$brew_status" -ne 0 ]]; then
    if brew list --versions "$FORMULA" >/dev/null 2>&1; then
      warn "本体ビルドは成功しましたが post_install が失敗しました。post_install をやり直します。"
      brew postinstall "$FORMULA" \
        || die "post_install のやり直しに失敗しました。手動で確認してください: brew postinstall --verbose $FORMULA"
      APP="$(brew --prefix "$FORMULA")/Emacs.app"
      codesign --verify "$APP" >/dev/null 2>&1 \
        || die "再署名後も署名検証に失敗しました。手動で確認してください: codesign --verify --verbose \"$APP\""
      log "post_install をやり直し、署名を修復しました。"
    else
      die "brew install が失敗しました(keg 未インストール)。上のログを確認してください。"
    fi
  fi

  log "ビルド完了。"
  create_app_alias
  print_next_steps
}

do_reinstall() {
  do_uninstall
  do_install
}

case "${1:-install}" in
  install)        do_install ;;
  uninstall)      do_uninstall ;;
  reinstall)      do_reinstall ;;
  help|-h|--help) do_help ;;
  *) die "未知のサブコマンド: ${1} (help を参照)" ;;
esac
