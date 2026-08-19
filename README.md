# dotfiles

Personal configuration files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package | Covers |
| --- | --- |
| `bash`  | `~/.bashrc` (Linux only - see below) |
| `git`   | `~/.gitconfig` - aliases, LFS filters; identity lives in `~/.gitconfig.local`. Also `~/.config/git/ignore`, the global excludes file |
| `nvim`  | Neovim config (`init.lua`), plugins via lazy.nvim |
| `tmux`  | `~/.tmux.conf` |
| `zed`   | Zed settings and keymap |
| `zsh`   | `~/.zshrc` — oh-my-zsh, fzf, nvm, git-worktree helper functions |

`git/.config/git/ignore` ignores `CLAUDE.md` in **every** repo on the machine, so
that the symlinks stowed by [`~/Trusted/claude-md`](../Trusted/claude-md) stay out
of each host repo's `git status`. A project that genuinely wants to commit its own
`CLAUDE.md` needs `git add -f`, or a `!CLAUDE.md` line in its own `.gitignore`.

## Setting up a new machine

1. **Install the programs these configs assume** (Neovim, oh-my-zsh, fzf, ripgrep,
   lazygit, nvm, Go, etc.):

   ```sh
   git clone <this-repo-url> ~/dotfiles
   cd ~/dotfiles
   ./install.sh          # Debian/Ubuntu - apt
   ./install-macos.sh    # macOS - Homebrew
   ```

   Both scripts are safe to re-run and skip anything already installed — see the
   scripts themselves for exactly what they install. Installing packages and linking
   dotfiles are kept as separate steps; neither script ever calls `stow`.

   `install-macos.sh` is deliberately narrower than `install.sh`: no LaTeX, DBeaver,
   ffmpeg, rustup or pixi, and none of the X11/KDE tools (`xdotool`, `flameshot`,
   `k4dirstat`, `meld`, `openssh-server`) that have no macOS equivalent. It will tell
   you if the Xcode command line tools are missing, but you have to run
   `xcode-select --install` yourself — it opens a GUI dialog.

2. **Create the per-machine files** (both are intentionally untracked, so secrets and
   machine-specific paths never land in the repo):

   - `~/.gitconfig.local` — your identity. Without it you have no commit author:

     ```ini
     [user]
     	name = Your Name
     	email = you@example.com
     ```

   - `~/.zshrc.local` — anything only this machine needs (conda init, `PNPM_HOME`,
     work-specific paths). Sourced from the end of `~/.zshrc` if present.

3. **Link the configs with Stow** (see below).

Each top-level directory here is a Stow package: the directory tree inside it mirrors
`$HOME`, so Stow symlinks files back into place (e.g. `zsh/.zshrc` → `~/.zshrc`). The
repo lives directly in `~`, so Stow's default target is already correct — no `-t` flag
needed, and all commands below run from `~/dotfiles`.

## Applying settings on a machine

```sh
cd ~/dotfiles
stow zsh tmux nvim zed git bash    # Linux - everything
stow zsh tmux nvim zed git         # macOS - everything except bash
stow nvim                          # or just one package
```

**`bash` on macOS:** don't stow it. `bash/.bashrc` is the stock Debian skeleton
(`debian_chroot`, `lesspipe`, `dircolors`, `notify-send`), macOS ships bash 3.2 and
doesn't source `~/.bashrc` for login shells anyway.

- `stow -n -v zsh` — dry run with verbose output; shows what *would* be linked.
- `stow -R nvim` — restow (unlink then relink); use after moving files within a package.

**Conflicts:** if a real file already exists where Stow wants a symlink (e.g. a
pre-existing `~/.zshrc`), Stow refuses. Either move it aside first...

```sh
mv ~/.zshrc ~/.zshrc.bak && stow zsh
```

...or pull its contents into the repo with `--adopt` (this **overwrites** the repo's
copy with the real file's contents — review with `git diff` after):

```sh
stow --adopt zsh && git diff
```

## Adding a new config to the repo

Recreate the file's `$HOME`-relative path inside a package directory, move the real
file in, then let Stow link it back:

```sh
cd ~/dotfiles
mkdir -p foo/.config/foo                        # mirrors ~/.config/foo
mv ~/.config/foo/config.toml foo/.config/foo/    # move the real file into the package
stow foo                                        # symlinks it back to ~/.config/foo/config.toml
git add foo && git commit -m "feat: add foo config"
```

## Updating and removing

- Edit a config normally — it's a symlink into the repo, so changes land here
  automatically. Commit them with git.
- `stow -R <pkg>` — restow after adding/moving files within a package.
- `stow -D <pkg>` — unlink a package's symlinks from your home directory (files stay
  safely in the repo).
