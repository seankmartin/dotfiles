# If you come from bash you might have to change your $PATH.
# Neovim
export PATH="/opt/nvim-linux-x86_64/bin:$PATH"
export PATH=$HOME/.local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
alias zshconfig="nano ~/.zshrc"
alias ohmyzsh="nano ~/.oh-my-zsh"
alias hist="history"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

razer-setup
fpath+=${ZDOTDIR:-~}/.zsh_functions

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ZSH FZF - fuzzy finder
source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh

# TMUX and git worktrees
# Usage:
#   wt <branch> [friendly-name]
#   ww <branch> [friendly-name]

_wt_info() {
  local branch="$1"
  local friendly="$2"
  local root base branch_safe dir name_file safe

  root="$(git rev-parse --show-toplevel)" || return 1
  base="$(basename "$root")"
  branch_safe="${branch//\//-}"
  dir="$(dirname "$root")/${base}-${branch_safe}"
  name_file="$dir/.tmux-name"

  if [ -n "$friendly" ]; then
    safe="${friendly//\//-}"
  elif [ -f "$name_file" ]; then
    safe="$(cat "$name_file")"
  else
    safe="$branch_safe"
  fi

  echo "$root|$base|$safe|$dir"
}

_wt_ensure_worktree() {
  local branch="$1"
  local friendly="$2"
  local info root base safe dir

  info="$(_wt_info "$branch" "$friendly")" || return 1
  IFS="|" read -r root base safe dir <<< "$info"

  if [ -d "$dir/.git" ] || [ -f "$dir/.git" ]; then
    if [ -n "$friendly" ]; then
      echo "${friendly//\//-}" > "$dir/.tmux-name"
    fi
    echo "$dir"
    return 0
  fi

  git fetch origin >/dev/null 2>&1

  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$dir" "$branch"
  elif git ls-remote --exit-code --heads origin "$branch" >/dev/null 2>&1; then
    git worktree add -b "$branch" "$dir" "origin/$branch"
  else
    git worktree add -b "$branch" "$dir"
  fi

  if [ -f "$root/CLAUDE.md" ]; then
    cp "$root/CLAUDE.md" "$dir/CLAUDE.md"
  fi

  if [ -n "$friendly" ]; then
    echo "${friendly//\//-}" > "$dir/.tmux-name"
  else
    echo "$safe" > "$dir/.tmux-name"
  fi

  echo "$dir"
}

_tmux_window_exists() {
  tmux list-windows -F "#{window_name}" | grep -qx "$1"
}

_tmux_new_worktree_window() {
  local name="$1"
  local dir="$2"
  local command="$3"

  if ! _tmux_window_exists "$name"; then
    tmux new-window -n "$name" "cd '$dir' && $command"
  fi
}

# create/open a worktree + tmux windows
wt() {
  local branch="$1"
  local friendly="$2"

  if [ -z "$branch" ]; then
    echo "Usage: wt <branch> [friendly-name]"
    return 1
  fi

  local info root base safe dir
  info="$(_wt_info "$branch" "$friendly")" || return 1
  IFS="|" read -r root base safe dir <<< "$info"

  dir="$(_wt_ensure_worktree "$branch" "$friendly")" || return 1

  # Re-read after creating the worktree, so .tmux-name is respected.
  info="$(_wt_info "$branch" "$friendly")" || return 1
  IFS="|" read -r root base safe dir <<< "$info"

  if [ -n "$TMUX" ]; then
    _tmux_new_worktree_window "${safe}-agent" "$dir" "exec \$SHELL"
    _tmux_new_worktree_window "${safe}-edit" "$dir" "nvim ."
    _tmux_new_worktree_window "${safe}-run" "$dir" "exec \$SHELL"

    tmux select-window -t "${safe}-edit"
  else
    cd "$dir"
  fi
}

# jump to a worktree edit window
ww() {
  local branch="$1"
  local friendly="$2"

  if [ -z "$branch" ]; then
    echo "Usage: ww <branch> [friendly-name]"
    return 1
  fi

  local info root base safe dir
  info="$(_wt_info "$branch" "$friendly")" || return 1
  IFS="|" read -r root base safe dir <<< "$info"

  dir="$(_wt_ensure_worktree "$branch" "$friendly")" || return 1

  # Re-read after ensuring the worktree, so .tmux-name is respected.
  info="$(_wt_info "$branch" "$friendly")" || return 1
  IFS="|" read -r root base safe dir <<< "$info"

  if [ -n "$TMUX" ]; then
    tmux select-window -t "${safe}-edit" 2>/dev/null || {
      _tmux_new_worktree_window "${safe}-edit" "$dir" "nvim ."
      tmux select-window -t "${safe}-edit"
    }
  else
    cd "$dir"
  fi
}

# remove a worktree
wr() {
  local force=""
  [ "$1" = "-f" ] && force="--force" && shift

  local branch="$1"
  local root="$(git rev-parse --show-toplevel)"
  local base="$(basename "$root")"
  local safe="${branch//\//-}"
  local dir="../${base}-${safe}"

  git worktree remove $force "$dir"
  git branch -d "$branch" 2>/dev/null
  [ -n "$TMUX" ] && tmux kill-window -t "$safe" 2>/dev/null
}

alias wl='git worktree list'

# For razer-setup
export PATH="$HOME/.pixi/bin:$PATH"

# Go setup
export PATH=$PATH:/usr/local/go/bin
export PATH="$PATH:$(go env GOPATH)/bin"
