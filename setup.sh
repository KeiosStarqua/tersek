#!/usr/bin/env bash
#
# setup.sh - install, fix, doctor and manage the terminal toolchain from README.md
#
# Targets: getnf fonts foot herdr zoxide eza fzf atuin carapace starship config
# Run `./setup.sh help` for usage.

set -uo pipefail

SCRIPT_NAME=$(basename "$0")

# --- settings (override through the environment) ----------------------------
FONT_FAMILY=${FONT_FAMILY:-"FiraCode Nerd Font"}  # family foot should use
FONT_SIZE=${FONT_SIZE:-11}                        # only applied when foot.ini gets a new font= line
NERD_FONTS=${NERD_FONTS:-FiraCode}                # getnf font names, space or comma separated
GETNF_TAG=${GETNF_TAG:-}                          # pin the getnf release, e.g. v0.5.0

FOOT_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/foot/foot.ini"
HERDR_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/herdr/config.toml"

readonly BEGIN_MARK='# >>> tersek setup >>>'
readonly END_MARK='# <<< tersek setup <<<'

ALL_TARGETS=(getnf fonts foot herdr zoxide eza fzf atuin carapace starship config)

declare -A VERSION_CMD=(
  [getnf]="getnf -V"
  [foot]="foot --version"
  [herdr]="herdr --version"
  [zoxide]="zoxide --version"
  [eza]="eza --version"
  [fzf]="fzf --version"
  [atuin]="atuin --version"
  [carapace]="carapace --version"
  [starship]="starship --version"
)

# --- state ---------------------------------------------------------------------
DRY_RUN=0
ASSUME_YES=0
PASS=0 WARN=0 FAIL=0
ORIG_PATH=$PATH

# The tools live in places a non-interactive shell may not have on PATH.
add_path() { [[ -d $1 && ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"; return 0; }
add_path /home/linuxbrew/.linuxbrew/bin
add_path "$HOME/.linuxbrew/bin"
add_path "$HOME/.atuin/bin"
add_path "$HOME/.local/bin"

if [[ -t 1 ]]; then
  C_RED=$'\e[31m' C_GRN=$'\e[32m' C_YEL=$'\e[33m' C_BLU=$'\e[34m' C_OFF=$'\e[0m'
else
  C_RED='' C_GRN='' C_YEL='' C_BLU='' C_OFF=''
fi

# --- output helpers ------------------------------------------------------------
info() { printf '%s==>%s %s\n' "$C_BLU" "$C_OFF" "$*"; }
ok()   { PASS=$((PASS + 1)); printf '  %s✓%s %s\n' "$C_GRN" "$C_OFF" "$*"; }
warn() { WARN=$((WARN + 1)); printf '  %s!%s %s\n' "$C_YEL" "$C_OFF" "$*"; }
bad()  { FAIL=$((FAIL + 1)); printf '  %s✗%s %s\n' "$C_RED" "$C_OFF" "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# --- execution helpers ---------------------------------------------------------
run() {
  if ((DRY_RUN)); then printf '  [dry-run] %s\n' "$*"; return 0; fi
  "$@"
}

if ((EUID == 0)); then SUDO=(); elif have sudo; then SUDO=(sudo); else SUDO=(); fi
as_root() { run "${SUDO[@]}" "$@"; }

# Download an installer to a temp file, then run it with the given shell.
# Usage: run_remote <url> <shell> [installer args...]
run_remote() {
  local url=$1 shell=$2 tmp rc
  shift 2
  have curl || { bad "curl is required to download $url"; return 1; }
  if ((DRY_RUN)); then
    printf '  [dry-run] download %s and run: %s <script> %s\n' "$url" "$shell" "$*"
    return 0
  fi
  tmp=$(mktemp "${TMPDIR:-/tmp}/tersek.XXXXXX") || return 1
  if curl --proto '=https' --tlsv1.2 -fsSL --max-time 60 -o "$tmp" "$url"; then
    timeout 300 "$shell" "$tmp" "$@" </dev/null
    rc=$?
  else
    rc=1
  fi
  rm -f -- "$tmp"
  return "$rc"
}

backup_file() {
  [[ -f $1 ]] || return 0
  run cp -p -- "$1" "$1.tersek-bak.$(date +%Y%m%d-%H%M%S)"
}

confirm() {
  ((ASSUME_YES || DRY_RUN)) && return 0
  [[ -t 0 ]] || die "not a terminal; pass -y to run without a prompt"
  local answer
  read -r -p "$1 [y/N] " answer
  [[ $answer == [yY]* ]]
}

tool_version() {
  local out
  # shellcheck disable=SC2086  # the command string is split on purpose
  out=$(timeout 5 ${VERSION_CMD[$1]} </dev/null 2>&1) || return 1
  printf '%s\n' "${out%%$'\n'*}"
}

# brew when present (as in README), apt otherwise.
pkg_install() { # <brew formula> <apt package>
  if have brew; then run timeout 900 brew install "$1" </dev/null
  elif have apt-get; then as_root apt-get install -y "$2"
  else bad "need brew or apt-get to install $1"; return 1
  fi
}

pkg_upgrade() { # <brew formula> <apt package>
  if have brew && brew list --formula "$1" >/dev/null 2>&1; then
    run timeout 900 brew upgrade "$1" </dev/null
  elif have apt-get; then
    as_root apt-get install -y --only-upgrade "$2"
  else
    bad "no package manager found to upgrade $1"; return 1
  fi
}

# --- per-tool install ----------------------------------------------------------
do_install_getnf() {
  local args=()
  [[ -n $GETNF_TAG ]] && args+=("--tag=$GETNF_TAG")
  run_remote https://raw.githubusercontent.com/getnf/getnf/main/install.sh bash "${args[@]}"
}
do_install_foot()     { have apt-get && as_root apt-get install -y foot || { bad "foot: apt-get install failed or apt-get missing"; return 1; }; }
do_install_herdr()    { run_remote https://herdr.dev/install.sh sh; }
do_install_zoxide()   { run_remote https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh sh; }
do_install_atuin()    { run_remote https://setup.atuin.sh sh; }
do_install_eza()      { pkg_install eza eza; }
do_install_fzf()      { pkg_install fzf fzf; }
do_install_starship() {
  # -b keeps the install in ~/.local/bin so no sudo is needed.
  run_remote https://starship.rs/install.sh sh -b "$HOME/.local/bin" -y
}
do_install_carapace() {
  if have brew; then run timeout 900 brew install carapace </dev/null; return; fi
  have apt-get && have gpg || { bad "carapace: need brew, or apt-get and gpg"; return 1; }
  if ((DRY_RUN)); then
    echo "  [dry-run] add apt.fury.io/rsteube apt repo and apt-get install carapace-bin"
    return 0
  fi
  curl --proto '=https' --tlsv1.2 -fsSL https://apt.fury.io/rsteube/gpg.key \
    | "${SUDO[@]}" gpg --dearmor --yes -o /usr/share/keyrings/rsteube.gpg || return 1
  echo "deb [signed-by=/usr/share/keyrings/rsteube.gpg] https://apt.fury.io/rsteube/ /" \
    | "${SUDO[@]}" tee /etc/apt/sources.list.d/fury.list >/dev/null || return 1
  "${SUDO[@]}" apt-get update && "${SUDO[@]}" apt-get install -y carapace-bin
}

# --- per-tool update -----------------------------------------------------------
do_update_getnf()    { do_install_getnf; }
do_update_foot()     { as_root apt-get install -y --only-upgrade foot; }
do_update_herdr()    { run herdr update </dev/null; }
do_update_zoxide()   { do_install_zoxide; }
do_update_atuin()    { do_install_atuin; }
do_update_eza()      { pkg_upgrade eza eza; }
do_update_fzf()      { pkg_upgrade fzf fzf; }
do_update_carapace() { pkg_upgrade carapace carapace-bin; }
do_update_starship() {
  local dir
  dir=$(dirname "$(command -v starship)")
  run_remote https://starship.rs/install.sh sh -b "$dir" -y
}

# --- fonts ---------------------------------------------------------------------
font_visible() {
  have fc-list || return 1
  # Capture first: `grep -q` closing the pipe early would trip pipefail.
  local families
  families=$(fc-list : family | tr ',' '\n')
  grep -qixF -- "$FONT_FAMILY" <<<"$families"
}

getnf_installed() { timeout 30 getnf -l </dev/null 2>/dev/null; }

install_fonts() {
  have getnf || { bad "getnf is missing; run: $SCRIPT_NAME install getnf"; return 1; }
  local installed font missing=()
  installed=$(getnf_installed)
  for font in ${NERD_FONTS//,/ }; do
    grep -Eq "^${font}[[:space:]]" <<<"$installed" && ok "font $font already installed" || missing+=("$font")
  done
  if ((${#missing[@]})); then
    local list
    list=$(IFS=,; echo "${missing[*]}")
    run timeout 600 getnf -i "$list" </dev/null || { bad "getnf -i $list failed"; return 1; }
  fi
  have fc-cache && run fc-cache -f
  ((DRY_RUN)) && return 0
  font_visible && ok "'$FONT_FAMILY' is visible to fontconfig" || bad "'$FONT_FAMILY' not found by fc-list"
}

# --- foot / herdr config -------------------------------------------------------
# Value of the active font= line in [main] (keys before any section belong to main).
foot_font() {
  [[ -f $FOOT_CONF ]] || return 0
  awk 'BEGIN{sec="[main]"}
       /^[[:space:]]*\[/ {sec=$0; gsub(/[[:space:]]/, "", sec)}
       sec=="[main]" && /^[[:space:]]*font[[:space:]]*=/ {
         sub(/^[^=]*=[[:space:]]*/, ""); sub(/[[:space:]]+$/, ""); print; exit }' "$FOOT_CONF"
}

config_foot() { # <force 0|1>
  local force=$1 want="$FONT_FAMILY:size=$FONT_SIZE" cur tmp
  if [[ ! -f $FOOT_CONF ]]; then
    info "creating $FOOT_CONF"
    if ((DRY_RUN)); then echo "  [dry-run] write [main] font=$want"; return 0; fi
    mkdir -p -- "$(dirname "$FOOT_CONF")" && printf '[main]\nfont=%s\n' "$want" >"$FOOT_CONF" \
      && ok "foot.ini created with font=$want"
    return
  fi
  cur=$(foot_font)
  if [[ -z $cur ]]; then
    info "adding font= to $FOOT_CONF"
    backup_file "$FOOT_CONF"
    ((DRY_RUN)) && { echo "  [dry-run] add font=$want to [main]"; return 0; }
    tmp=$(mktemp) || return 1
    if grep -q '^\[main\][[:space:]]*$' "$FOOT_CONF"; then
      awk -v want="font=$want" '{print} /^\[main\][[:space:]]*$/ && !d {print want; d=1}' "$FOOT_CONF" >"$tmp"
    else
      { printf '[main]\nfont=%s\n\n' "$want"; cat "$FOOT_CONF"; } >"$tmp"
    fi
    cat "$tmp" >"$FOOT_CONF"; rm -f -- "$tmp"
    ok "font=$want added"
  elif [[ ${cur%%:*} != "$FONT_FAMILY" ]]; then
    if ((force)); then
      info "replacing font=$cur in $FOOT_CONF"
      backup_file "$FOOT_CONF"
      ((DRY_RUN)) && { echo "  [dry-run] font=$want"; return 0; }
      tmp=$(mktemp) || return 1
      awk -v want="font=$want" 'BEGIN{sec="[main]"}
          /^[[:space:]]*\[/ {sec=$0; gsub(/[[:space:]]/, "", sec)}
          !done && sec=="[main]" && /^[[:space:]]*font[[:space:]]*=/ {print want; done=1; next}
          {print}' "$FOOT_CONF" >"$tmp"
      cat "$tmp" >"$FOOT_CONF"; rm -f -- "$tmp"
      ok "font=$want set"
    else
      warn "foot font is '$cur', expected family '$FONT_FAMILY' (run: $SCRIPT_NAME fix config)"
    fi
  else
    ok "foot font=$cur"
  fi
}

config_herdr() {
  if [[ -f $HERDR_CONF ]]; then ok "herdr config present: $HERDR_CONF"; return 0; fi
  info "creating $HERDR_CONF"
  if ((DRY_RUN)); then echo "  [dry-run] write herdr config.toml"; return 0; fi
  mkdir -p -- "$(dirname "$HERDR_CONF")" || return 1
  printf 'onboarding = false\n\n[ui]\nsidebar_collapsed_mode = "compact"\n' >"$HERDR_CONF" \
    && ok "herdr config created"
}

# --- shell rc integration ------------------------------------------------------
# Everything outside our managed block, so we never duplicate lines you already have.
rc_outside() {
  [[ -f $1 ]] || return 0
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" '$0==b{skip=1; next} $0==e{skip=0; next} !skip' "$1"
}

rc_has() { # <outside-content> <regex>; commented lines never count
  grep -Eq -- "^[^#]*($2)" <<<"$1"
}

rc_wanted() { # <shell> <outside-content>
  local sh=$1 content=$2 brew_bin
  rc_has "$content" '\.local/bin' \
    || printf '%s\n' 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac'
  if have brew && ! rc_has "$content" 'brew shellenv'; then
    brew_bin=$(command -v brew)
    printf '[ -x %q ] && eval "$(%q shellenv %s)"\n' "$brew_bin" "$brew_bin" "$sh"
  fi
  if have zoxide && ! rc_has "$content" 'zoxide init'; then
    printf 'command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init %s)"\n' "$sh"
  fi
  if have carapace && ! rc_has "$content" 'carapace _carapace'; then
    printf '%s\n' 'command -v carapace >/dev/null 2>&1 && source <(carapace _carapace)'
  fi
  if [[ -f $HOME/.atuin/bin/env ]] && ! rc_has "$content" '\.atuin/bin/env'; then
    printf '%s\n' '[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"'
  fi
  if have atuin && ! rc_has "$content" 'atuin init'; then
    printf 'command -v atuin >/dev/null 2>&1 && eval "$(atuin init %s)"\n' "$sh"
  fi
  if have starship && ! rc_has "$content" 'starship init'; then
    printf 'command -v starship >/dev/null 2>&1 && eval "$(starship init %s)"\n' "$sh"
  fi
}

rc_apply() { # <shell> <rc file>
  local sh=$1 rc=$2 outside wanted new current
  outside=$(rc_outside "$rc")
  wanted=$(rc_wanted "$sh" "$outside")
  if [[ -n $wanted ]]; then
    new="$outside"$'\n\n'"$BEGIN_MARK"$'\n'"$wanted"$'\n'"$END_MARK"
  else
    new=$outside
  fi
  current=$(cat -- "$rc" 2>/dev/null)
  if [[ $new == "$current" ]]; then ok "$rc up to date"; return 0; fi
  [[ -f $rc || -n $wanted ]] || return 0
  info "updating $rc"
  backup_file "$rc"
  if ((DRY_RUN)); then
    echo "  [dry-run] managed block would contain:"
    sed 's/^/      /' <<<"$wanted"
    return 0
  fi
  printf '%s\n' "$new" >"$rc" && ok "$rc updated (managed block: $BEGIN_MARK)"
}

# README: ~/.profile and ~/.bash_profile both source the Atuin env.
config_profiles() {
  [[ -f $HOME/.atuin/bin/env ]] || return 0
  local f
  for f in "$HOME/.profile" "$HOME/.bash_profile"; do
    [[ -f $f ]] || continue
    grep -Eq '^[^#]*\.atuin/bin/env' "$f" && continue
    info "adding atuin env to $f"
    backup_file "$f"
    if ((DRY_RUN)); then echo "  [dry-run] append atuin env line"; continue; fi
    printf '\n# tersek: atuin env\n[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"\n' >>"$f" \
      && ok "$f updated"
  done
}

apply_config() { # <force 0|1>
  config_foot "$1"
  config_herdr
  config_profiles
  rc_apply bash "$HOME/.bashrc"
  if have zsh; then rc_apply zsh "$HOME/.zshrc"; else echo "  zsh not installed; skipping ~/.zshrc"; fi
}

# --- doctor checks -------------------------------------------------------------
check_bin() {
  local t=$1 path ver
  if ! have "$t"; then bad "$t not found on PATH"; return 1; fi
  path=$(command -v "$t")
  if ver=$(tool_version "$t"); then ok "$ver ($path)"
  else bad "$t at $path fails: ${VERSION_CMD[$t]}"; fi
}

check_getnf() {
  check_bin getnf
  have curl || bad "curl missing (getnf needs it)"
  [[ ":$ORIG_PATH:" == *":$HOME/.local/bin:"* ]] || warn "~/.local/bin is not on your login PATH"
}

check_fonts() {
  local installed font
  have fc-list || { bad "fc-list missing (install fontconfig)"; return; }
  font_visible && ok "'$FONT_FAMILY' visible to fontconfig" \
    || bad "'$FONT_FAMILY' not visible; try: $SCRIPT_NAME fix fonts"
  have getnf || return 0
  installed=$(getnf_installed)
  for font in ${NERD_FONTS//,/ }; do
    grep -Eq "^${font}[[:space:]]" <<<"$installed" && ok "getnf lists $font" \
      || warn "getnf does not list $font"
  done
}

check_rc_file() { # <shell> <rc>
  local sh=$1 rc=$2 name pattern count
  if [[ ! -f $rc ]]; then warn "$rc missing"; return; fi
  if "$sh" -n "$rc" 2>/dev/null; then ok "$rc syntax ok"; else bad "$rc has a syntax error ($sh -n)"; fi
  for name in zoxide:'zoxide init' atuin:'atuin init' carapace:'carapace _carapace' starship:'starship init'; do
    pattern=${name#*:}; name=${name%%:*}
    have "$name" || continue
    count=$(grep -Ec -- "^[^#]*($pattern)" "$rc")
    if ((count == 0)); then warn "$name not initialised in $rc (run: $SCRIPT_NAME fix config)"
    elif ((count > 1)); then warn "$name initialised $count times in $rc"
    fi
  done
  # fzf's Ctrl-R binding must come before atuin's, or it steals Ctrl-R.
  local fzf_line atuin_line
  fzf_line=$(grep -En '^[^#]*fzf --(bash|zsh)' "$rc" | head -n1 | cut -d: -f1)
  atuin_line=$(grep -En '^[^#]*atuin init' "$rc" | tail -n1 | cut -d: -f1)
  if [[ -n $fzf_line && -n $atuin_line ]] && ((fzf_line > atuin_line)); then
    warn "$rc: fzf init comes after atuin init, so fzf takes over Ctrl-R"
  fi
}

check_config() {
  local cur out
  if [[ -f $FOOT_CONF ]]; then
    ok "foot config: $FOOT_CONF"
    cur=$(foot_font)
    if [[ -z $cur ]]; then warn "no font= in [main]; foot uses its default font"
    elif [[ ${cur%%:*} != "$FONT_FAMILY" ]]; then warn "foot font family is '${cur%%:*}', expected '$FONT_FAMILY'"
    else ok "foot font=$cur"; fi
    if have foot; then
      out=$(timeout 10 foot --check-config 2>&1 </dev/null) && ok "foot --check-config passes" \
        || bad "foot --check-config: ${out%%$'\n'*}"
    fi
  else
    warn "$FOOT_CONF missing; foot runs on defaults without $FONT_FAMILY"
  fi
  if [[ -f $HERDR_CONF ]]; then ok "herdr config: $HERDR_CONF"; else warn "$HERDR_CONF missing"; fi
  [[ -f $HOME/.atuin/bin/env ]] && for f in "$HOME/.profile" "$HOME/.bash_profile"; do
    [[ -f $f ]] || continue
    grep -Eq '^[^#]*\.atuin/bin/env' "$f" || warn "$f does not source ~/.atuin/bin/env"
  done
  check_rc_file bash "$HOME/.bashrc"
  if have zsh; then check_rc_file zsh "$HOME/.zshrc"; fi
}

# --- target dispatch -----------------------------------------------------------
is_bin_tool() { [[ -n ${VERSION_CMD[$1]:-} ]]; }

install_target() {
  local t=$1
  info "install: $t"
  case $t in
    fonts)  install_fonts ;;
    config) apply_config 0 ;;
    *)
      if have "$t"; then ok "$t already installed ($(command -v "$t"))"; return 0; fi
      "do_install_$t" || { bad "$t install failed"; return 1; }
      ((DRY_RUN)) && return 0
      hash -r
      have "$t" && ok "$t installed ($(command -v "$t"))" || bad "$t installer finished but '$t' is not on PATH"
      ;;
  esac
}

update_target() {
  local t=$1
  info "update: $t"
  case $t in
    fonts)
      have getnf || { bad "getnf missing"; return 1; }
      run timeout 900 getnf -U </dev/null && have fc-cache && run fc-cache -f
      ;;
    config) echo "  nothing to update (use fix to re-apply config)" ;;
    *)
      have "$t" || { warn "$t is not installed; run: $SCRIPT_NAME install $t"; return 0; }
      "do_update_$t" || bad "$t update failed"
      ;;
  esac
}

fix_target() {
  local t=$1 font
  info "fix: $t"
  case $t in
    fonts)
      have fc-cache && run fc-cache -f
      if ! font_visible && have getnf; then
        local listed
        listed=$(getnf_installed)
        for font in ${NERD_FONTS//,/ }; do
          grep -Eq "^${font}[[:space:]]" <<<"$listed" && run timeout 300 getnf -u "$font" </dev/null
        done
      fi
      install_fonts
      ;;
    config) apply_config 1 ;;
    *)
      # A binary that exists but is not executable is invisible to `command -v`.
      if ! have "$t" && [[ -f $HOME/.local/bin/$t && ! -x $HOME/.local/bin/$t ]]; then
        run chmod u+x -- "$HOME/.local/bin/$t"
        hash -r
      fi
      if ! have "$t"; then
        install_target "$t"
      elif tool_version "$t" >/dev/null; then
        ok "$t works ($(command -v "$t"))"
      else
        warn "$t is broken; reinstalling"
        "do_update_$t" || bad "$t reinstall failed"
      fi
      ;;
  esac
}

doctor_target() {
  local t=$1
  info "doctor: $t"
  case $t in
    getnf)  check_getnf ;;
    fonts)  check_fonts ;;
    config) check_config ;;
    *)      check_bin "$t" ;;
  esac
}

status_target() {
  local t=$1 ver list
  case $t in
    fonts)
      list=""
      have getnf && list=$(getnf_installed | awk '$2=="-"{printf "%s%s %s", s, $1, $3; s=", "}')
      printf '%-10s %s\n' fonts "${list:-none installed via getnf}"
      ;;
    config)
      printf '%-10s foot.ini:%s herdr:%s\n' config \
        "$([[ -f $FOOT_CONF ]] && echo yes || echo no)" "$([[ -f $HERDR_CONF ]] && echo yes || echo no)"
      ;;
    *)
      if have "$t"; then
        ver=$(tool_version "$t" || echo "version check failed")
        printf '%-10s %-34s %s\n' "$t" "$ver" "$(command -v "$t")"
      else
        printf '%-10s %s\n' "$t" "not installed"
      fi
      ;;
  esac
}

# --- CLI -----------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $SCRIPT_NAME <command> [options] [target...]

Commands:
  install   Install missing tools and apply config (idempotent, never upgrades)
  auto      One shot: install, fix, then doctor (use: $SCRIPT_NAME auto -y)
  fix       Repair: reinstall broken tools, refresh the font cache, re-apply config
  doctor    Check everything and report; changes nothing. Exits 1 on failures
  update    Upgrade installed tools (getnf -U for fonts, herdr update, brew/apt, installers)
  status    Show versions and paths
  help      Show this help

Targets (default: all):
  ${ALL_TARGETS[*]}

Options:
  -y, --yes       Do not ask for confirmation
  -n, --dry-run   Print what would happen, change nothing

Environment:
  FONT_FAMILY=$FONT_FAMILY   FONT_SIZE=$FONT_SIZE   NERD_FONTS=$NERD_FONTS   GETNF_TAG=<release>

Notes:
  - Fonts are managed with getnf (getnf -i / -u / -U / -l).
  - Remote installers (getnf, herdr, zoxide, atuin, starship) are downloaded to a
    temp file and executed. Use --dry-run to see which ones would run.
  - Shell lines go in a managed block in ~/.bashrc (and ~/.zshrc if zsh is installed),
    delimited by "$BEGIN_MARK". Lines you already have outside it are left alone.
    Files are backed up as <file>.tersek-bak.<timestamp> before any change.
EOF
}

main() {
  local cmd=${1:-help} t valid
  shift || true
  local selected=()
  while (($#)); do
    case $1 in
      -y|--yes) ASSUME_YES=1 ;;
      -n|--dry-run) DRY_RUN=1 ;;
      -h|--help) usage; exit 0 ;;
      -*) die "unknown option: $1" ;;
      *)
        valid=0
        for t in "${ALL_TARGETS[@]}"; do [[ $t == "$1" ]] && valid=1; done
        ((valid)) || die "unknown target: $1 (valid: ${ALL_TARGETS[*]})"
        selected+=("$1")
        ;;
    esac
    shift
  done
  ((${#selected[@]})) || selected=("${ALL_TARGETS[@]}")

  case $cmd in
    help|-h|--help) usage; exit 0 ;;
    install|fix|update|auto)
      confirm "$cmd: ${selected[*]}?" || { echo "aborted"; exit 1; }
      ;;
    doctor|status) ;;
    *) usage >&2; die "unknown command: $cmd" ;;
  esac

  for t in "${selected[@]}"; do
    case $cmd in
      install) install_target "$t" ;;
      auto)    install_target "$t"; fix_target "$t" ;;
      fix)     fix_target "$t" ;;
      update)  update_target "$t" ;;
      doctor)  doctor_target "$t" ;;
      status)  status_target "$t" ;;
    esac
  done

  if [[ $cmd == auto ]]; then
    printf '\n%s ok, %s warnings, %s failures during setup\n\n' "$PASS" "$WARN" "$FAIL"
    PASS=0 WARN=0 FAIL=0
    hash -r
    for t in "${selected[@]}"; do doctor_target "$t"; done
  fi

  if [[ $cmd != status ]]; then
    printf '\n%s ok, %s warnings, %s failures\n' "$PASS" "$WARN" "$FAIL"
  fi
  ((FAIL == 0))
}

main "$@"
