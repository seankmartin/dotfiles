#!/usr/bin/env bash
#
# Bootstrap script for a fresh Linux (apt-based) machine.
#
# Installs the programs these dotfiles assume are present. Run this BEFORE
# `stow` — package installation and stowing configs are kept as separate,
# independent steps.
#
# Safe to re-run: every section checks whether its target is already
# installed and skips if so. One section failing (e.g. no network) does not
# abort the rest of the script.

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
export PATH="/usr/local/go/bin:$HOME/.cargo/bin:$HOME/.local/bin:$HOME/go/bin:$PATH"

# ---------------------------------------------------------------------------
# apt setup
# ---------------------------------------------------------------------------

apt_update() {
  sudo add-apt-repository -y universe
  sudo apt-get update
}

# ---------------------------------------------------------------------------
# Core CLI / dev tools
# ---------------------------------------------------------------------------

install_core_cli() {
  sudo apt-get install -y \
    build-essential git git-crypt gh stow tmux zsh curl wget jq cmake make \
    unzip fzf openssh-server sqlite3 graphviz pandoc meld xdotool python3-pip

  # Optional: only needed for `python3 -m venv`. Comment out if not wanted.
  sudo apt-get install -y python3-venv
}

# ---------------------------------------------------------------------------
# Minimal LaTeX (latexmk + the base LaTeX package set, not texlive-full)
# ---------------------------------------------------------------------------

install_latex() {
  sudo apt-get install -y latexmk texlive-latex-base
}

# ---------------------------------------------------------------------------
# Creative tools (trimmed set)
# ---------------------------------------------------------------------------

install_creative() {
  sudo apt-get install -y ffmpeg k4dirstat flameshot
}

# ---------------------------------------------------------------------------
# DBeaver CE - not in Ubuntu's default repos, install the official .deb
# ---------------------------------------------------------------------------

install_dbeaver() {
  if dpkg -s dbeaver-ce >/dev/null 2>&1; then
    ok; return 0
  fi

  local deb="/tmp/dbeaver-ce_latest_amd64.deb"
  curl -fsSL -o "$deb" "https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb"
  sudo apt-get install -y "$deb"
  rm -f "$deb"
}

# ---------------------------------------------------------------------------
# Neovim - installed from the official release tarball into /opt, matching
# the existing layout these dotfiles' PATH setup expects.
# ---------------------------------------------------------------------------

install_neovim() {
  if [ -x /opt/nvim-linux-x86_64/bin/nvim ]; then
    ok; return 0
  fi

  local tarball="/tmp/nvim-linux-x86_64.tar.gz"
  curl -fsSL -o "$tarball" \
    "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
  sudo tar -C /opt -xzf "$tarball"
  rm -f "$tarball"
}

# ---------------------------------------------------------------------------
# Zed - official installer, lands under ~/.local
# ---------------------------------------------------------------------------

install_zed() {
  if command -v zed >/dev/null 2>&1; then
    ok; return 0
  fi
  curl -fsSL https://zed.dev/install.sh | sh
}

# ---------------------------------------------------------------------------
# Language toolchains / version managers
# ---------------------------------------------------------------------------

install_ohmyzsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    ok; return 0
  fi
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
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

install_rustup() {
  if command -v rustc >/dev/null 2>&1; then
    ok; return 0
  fi
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
}

install_go() {
  if command -v go >/dev/null 2>&1; then
    ok; return 0
  fi

  local version tarball
  version="$(curl -fsSL 'https://go.dev/VERSION?m=text' | head -n1)"
  tarball="/tmp/${version}.linux-amd64.tar.gz"
  curl -fsSL -o "$tarball" "https://go.dev/dl/${version}.linux-amd64.tar.gz"
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf "$tarball"
  rm -f "$tarball"
}

install_pixi() {
  if command -v pixi >/dev/null 2>&1; then
    ok; return 0
  fi
  curl -fsSL https://pixi.sh/install.sh | sh
}

install_uv() {
  if command -v uv >/dev/null 2>&1; then
    ok; return 0
  fi
  curl -LsSf https://astral.sh/uv/install.sh | sh
}

install_lazygit() {
  if command -v lazygit >/dev/null 2>&1; then
    ok; return 0
  fi
  if ! command -v go >/dev/null 2>&1; then
    warn "go not found on PATH, cannot install lazygit"
    return 1
  fi
  go install github.com/jesseduffield/lazygit@latest
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  run_section "apt update"        apt_update
  run_section "Core CLI tools"    install_core_cli
  run_section "Minimal LaTeX"     install_latex
  run_section "Creative tools"    install_creative
  run_section "DBeaver CE"        install_dbeaver
  run_section "Neovim"            install_neovim
  run_section "Zed"               install_zed
  run_section "oh-my-zsh"         install_ohmyzsh
  run_section "nvm + Node LTS"    install_nvm
  run_section "rustup"            install_rustup
  run_section "Go"                install_go
  run_section "pixi"              install_pixi
  run_section "uv"                install_uv
  run_section "lazygit"           install_lazygit

  log "Done."
  echo "Next: cd ~/dotfiles && stow zsh tmux nvim zed bash   (see README.md)"
}

main "$@"
