#!/usr/bin/env bash
#
# Bootstrap script for a fresh macOS machine.
#
# The macOS counterpart to install.sh: same contract, Homebrew instead of apt.
# Installs the programs these dotfiles assume are present. Run this BEFORE
# `stow` — package installation and stowing configs are kept as separate,
# independent steps.
#
# Safe to re-run: every section checks whether its target is already
# installed and skips if so. One section failing (e.g. no network) does not
# abort the rest of the script.
#
# Deliberately narrower than install.sh: no LaTeX, DBeaver, ffmpeg, rustup or
# pixi. The Linux-only tools (xdotool, flameshot, k4dirstat, meld,
# openssh-server) have no sensible macOS equivalent and are skipped —
# see README.md.

set -uo pipefail

log()  { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$1" >&2; }
ok()   { printf '   already installed, skipping\n'; }

run_section() {
  local name="$1"; shift
  log "$name"
  if "$@"; then
    return 0
  else
    warn "$name failed - continuing with the rest of the script"
    return 1
  fi
}

# Make binaries installed by this script visible to later sections in the
# same run, without waiting for a fresh shell.
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:$PATH"

# ---------------------------------------------------------------------------
# Xcode command line tools - the macOS stand-in for build-essential.
#
# `xcode-select --install` opens a GUI dialog, so this only reports; it does
# not try to drive the installer.
# ---------------------------------------------------------------------------

check_xcode_clt() {
  if xcode-select -p >/dev/null 2>&1; then
    ok; return 0
  fi
  warn "Xcode command line tools are not set up. Run: xcode-select --install"
  return 1
}

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    ok; return 0
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # The installer does not touch the current shell's PATH.
  local prefix
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "$prefix/bin/brew" ]; then
      eval "$("$prefix/bin/brew" shellenv)"
      return 0
    fi
  done

  warn "brew not found after install"
  return 1
}

# ---------------------------------------------------------------------------
# Core CLI / dev tools
#
# `brew install` is already idempotent, so there is no per-package check here.
# ---------------------------------------------------------------------------

install_core_cli() {
  brew install \
    git git-lfs gh stow tmux zsh wget jq cmake make \
    fzf ripgrep lazygit neovim git-delta difftastic
}

# ---------------------------------------------------------------------------
# Language toolchains / version managers
# ---------------------------------------------------------------------------

install_toolchains() {
  brew install go uv
}

install_ohmyzsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    ok; return 0
  fi
  # --keep-zshrc matters: without it the installer moves ~/.zshrc aside and
  # writes its own template, which would fight with `stow zsh`.
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    "" --unattended --keep-zshrc
}

install_nvm() {
  if [ -d "$HOME/.nvm" ]; then
    ok; return 0
  fi
  # Pinned to a known-good tag; bump as needed - see https://github.com/nvm-sh/nvm/releases
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm install --lts
}

# ---------------------------------------------------------------------------
# git-lfs - git/.gitconfig sets filter.lfs.required, so the hooks have to be
# registered or every LFS checkout breaks.
# ---------------------------------------------------------------------------

setup_git_lfs() {
  if ! command -v git-lfs >/dev/null 2>&1; then
    warn "git-lfs not found on PATH, skipping"
    return 1
  fi
  git lfs install --skip-repo
}

# ---------------------------------------------------------------------------
# GUI apps
# ---------------------------------------------------------------------------

install_casks() {
  brew install --cask zed
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  run_section "Xcode command line tools" check_xcode_clt
  run_section "Homebrew"                 install_homebrew
  run_section "Core CLI tools"           install_core_cli
  run_section "Go + uv"                  install_toolchains
  run_section "Zed"                      install_casks
  run_section "oh-my-zsh"                install_ohmyzsh
  run_section "nvm + Node LTS"           install_nvm
  run_section "git-lfs"                  setup_git_lfs

  log "Done."
  echo "Next: cd ~/dotfiles && stow zsh tmux nvim zed git   (see README.md)"
}

main "$@"
