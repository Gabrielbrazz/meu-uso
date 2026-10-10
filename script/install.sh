#!/bin/bash
# Installs or updates Meu Uso from the GitHub releases, from the terminal:
#
#   curl -fsSL https://raw.githubusercontent.com/Gabrielbrazz/meu-uso/main/script/install.sh | bash
#
# The same script runs again for updates (`meu-uso update` runs the copy bundled in the app).
#
# Why the terminal: these release builds are ad-hoc signed, not Developer ID signed and notarized.
# A file downloaded by curl carries no quarantine flag, so Gatekeeper opens the app; the same zip
# downloaded by a browser is quarantined and blocked. The download is checked against the SHA-256
# published with the release before anything on the Mac is touched, and a failed swap restores the
# previous app.
#
# Usage: install.sh [--version vX.Y.Z] [--app PATH] [--force] [--no-open]
#
# User-facing messages are Portuguese (the app's only language); code and comments stay English.
#
# Everything lives in functions and `main` runs on the last line, so a truncated `curl | bash`
# download never executes half a script.

set -euo pipefail

REPO="Gabrielbrazz/meu-uso"
BUNDLE_ID="io.github.gabrielbrazz.meuuso"
APP_DIR_NAME="MeuUso.app"
ASSET="MeuUso.zip"
CLI_LINK="${MEUUSO_CLI_LINK:-/usr/local/bin/meu-uso}"
MIN_MACOS_MAJOR=15
# Test hook: where release assets are downloaded from. Defaults to the GitHub release of the tag.
DOWNLOAD_BASE_URL="${MEUUSO_DOWNLOAD_BASE_URL:-}"

say() { printf '%s\n' "$*"; }
fail() { printf 'meu-uso: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Uso: install.sh [--version vX.Y.Z] [--app CAMINHO] [--force] [--no-open]

Instala ou atualiza o Meu Uso a partir das versões publicadas no GitHub.

Opções:
  --version vX.Y.Z  Instala essa versão em vez da mais recente
  --app CAMINHO     Atualiza o app que está nesse caminho
  --force           Reinstala mesmo se a versão já for a instalada
  --no-open         Não abre o app no fim
  -h, --help        Mostra esta ajuda
USAGE
}

# Reads a key from an app bundle's Info.plist, or prints nothing.
plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$2" "$1/Contents/Info.plist" 2>/dev/null || true
}

# The tag GitHub's /releases/latest redirects to (the newest non-prerelease), e.g. "v0.1.0".
latest_tag() {
  local url
  url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest") \
    || fail "não foi possível consultar as versões no GitHub. Confira a internet e tente de novo."
  case "$url" in
    */releases/tag/*) printf '%s\n' "${url##*/}" ;;
    *) fail "ainda não há versão publicada do Meu Uso." ;;
  esac
}

# An existing install of this app (by bundle id), in the usual places.
find_installed_app() {
  local candidate
  for candidate in "/Applications/$APP_DIR_NAME" "$HOME/Applications/$APP_DIR_NAME"; do
    if [ -d "$candidate" ] && [ "$(plist_value "$candidate" CFBundleIdentifier)" = "$BUNDLE_ID" ]; then
      printf '%s\n' "$candidate"
      return
    fi
  done
}

is_running() {
  pgrep -f "$1/Contents/MacOS/MeuUso" >/dev/null 2>&1
}

# Stops the running app and waits for it to exit. A plain SIGTERM, not an AppleScript `quit`: an Apple
# event from the terminal would trigger macOS's "Terminal wants to control Meu Uso" prompt. The app keeps
# no unsaved state (settings and caches are written as they change), so this is the same as quitting it.
quit_app() {
  local app="$1" waited=0
  is_running "$app" || return 0
  say "Fechando o Meu Uso…"
  pkill -TERM -f "$app/Contents/MacOS/MeuUso" >/dev/null 2>&1 || true
  while is_running "$app" && [ "$waited" -lt 10 ]; do
    sleep 0.5
    waited=$((waited + 1))
  done
  if is_running "$app"; then
    pkill -KILL -f "$app/Contents/MacOS/MeuUso" >/dev/null 2>&1 || true
    sleep 1
  fi
  ! is_running "$app" || fail "não foi possível fechar o Meu Uso. Use Opções → Encerrar o Meu Uso e rode de novo."
}

link_cli() {
  local app="$1" target="$1/Contents/Helpers/meu-uso"
  if [ -L "$CLI_LINK" ] || [ -e "$CLI_LINK" ]; then
    return
  fi
  if [ -d "$(dirname "$CLI_LINK")" ] && [ -w "$(dirname "$CLI_LINK")" ] && ln -s "$target" "$CLI_LINK" 2>/dev/null; then
    say "Comando instalado: meu-uso"
    return
  fi
  say ""
  say "Para usar o comando meu-uso em qualquer pasta, abra Ajustes → Linha de comando e clique em Instalar…"
  say "Sem ele, atualize com: \"$target\" update"
}

main() {
  local tag="" app="" force=0 open_app=1
  while [ $# -gt 0 ]; do
    case "$1" in
      --version) [ $# -ge 2 ] || fail "--version precisa de uma versão, como v0.1.0."; tag="$2"; shift 2 ;;
      --app) [ $# -ge 2 ] || fail "--app precisa de um caminho."; app="$2"; shift 2 ;;
      --force) force=1; shift ;;
      --no-open) open_app=0; shift ;;
      -h|--help) usage; exit 0 ;;
      *) fail "opção desconhecida: $1 (rode com --help para ver as opções)" ;;
    esac
  done

  [ "$(uname -s)" = "Darwin" ] || fail "o Meu Uso só roda no macOS."
  local macos_major
  macos_major=$(sw_vers -productVersion | cut -d. -f1)
  [ "$macos_major" -ge "$MIN_MACOS_MAJOR" ] || fail "o Meu Uso precisa do macOS $MIN_MACOS_MAJOR ou mais novo."

  [ -n "$tag" ] || tag=$(latest_tag)
  case "$tag" in v*) ;; *) tag="v$tag" ;; esac
  local version="${tag#v}"

  if [ -n "$app" ]; then
    [ -d "$app" ] || fail "não existe app em $app."
    [ "$(plist_value "$app" CFBundleIdentifier)" = "$BUNDLE_ID" ] || fail "$app não é o Meu Uso."
  else
    app=$(find_installed_app)
  fi

  if [ -n "$app" ] && [ "$force" -eq 0 ] && [ "$(plist_value "$app" CFBundleShortVersionString)" = "$version" ]; then
    say "O Meu Uso já está na versão $version."
    exit 0
  fi

  local tmp
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/meu-uso-install.XXXXXX")
  # shellcheck disable=SC2064 # expand $tmp now: it is local to main
  trap "rm -rf '$tmp'" EXIT

  say "Baixando o Meu Uso $version…"
  local base="${DOWNLOAD_BASE_URL:-https://github.com/$REPO/releases/download/$tag}"
  curl -fsSL --retry 3 -o "$tmp/$ASSET" "$base/$ASSET" \
    || fail "não foi possível baixar $ASSET da versão $tag."
  curl -fsSL --retry 3 -o "$tmp/$ASSET.sha256" "$base/$ASSET.sha256" \
    || fail "não foi possível baixar o checksum da versão $tag."
  (cd "$tmp" && shasum -a 256 -c "$ASSET.sha256" >/dev/null 2>&1) \
    || fail "o arquivo baixado não confere com o checksum publicado. Nada foi alterado."

  ditto -x -k "$tmp/$ASSET" "$tmp/extracted" || fail "não foi possível abrir o arquivo baixado."
  local new_app="$tmp/extracted/$APP_DIR_NAME"
  [ "$(plist_value "$new_app" CFBundleIdentifier)" = "$BUNDLE_ID" ] \
    || fail "o arquivo baixado não contém o Meu Uso. Nada foi alterado."
  codesign --verify --deep --strict "$new_app" >/dev/null 2>&1 \
    || fail "a assinatura do app baixado não confere. Nada foi alterado."

  local dest="$app"
  if [ -z "$dest" ]; then
    if [ -w /Applications ]; then
      dest="/Applications/$APP_DIR_NAME"
    else
      mkdir -p "$HOME/Applications"
      dest="$HOME/Applications/$APP_DIR_NAME"
    fi
  fi

  quit_app "$dest"

  if [ -d "$dest" ]; then
    mv "$dest" "$tmp/previous.app" || fail "não foi possível substituir $dest. Confira as permissões da pasta."
  fi
  if ! mv "$new_app" "$dest"; then
    [ -d "$tmp/previous.app" ] && mv "$tmp/previous.app" "$dest"
    fail "não foi possível instalar em $dest. A versão anterior foi mantida."
  fi
  # A no-op for curl downloads; clears the flag if the zip reached the Mac some other way.
  xattr -dr com.apple.quarantine "$dest" 2>/dev/null || true

  say "Meu Uso $version instalado em $dest."
  link_cli "$dest"

  if [ "$open_app" -eq 1 ]; then
    open "$dest"
  fi
}

main "$@"
