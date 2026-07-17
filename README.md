# dotfiles

Personal configuration files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Packages

| Package | Covers |
| --- | --- |
| `bash`  | `~/.bashrc` |
| `nvim`  | Neovim config (`init.lua`), plugins via lazy.nvim |
| `tmux`  | `~/.tmux.conf` |
| `zed`   | Zed settings and keymap |
| `zsh`   | `~/.zshrc` — oh-my-zsh, fzf, nvm, git-worktree helper functions |

## Setting up a new machine

1. **Install the programs these configs assume** (Neovim, oh-my-zsh, fzf, nvm, Go,
   rustup, etc.) — on a fresh Debian/Ubuntu box, run:

   ```sh
   git clone <this-repo-url> ~/dotfiles
   cd ~/dotfiles
   ./install.sh
   ```

   `install.sh` is apt-based (Linux only) and safe to re-run — see the script itself
   for exactly what it installs. Installing packages and linking dotfiles are kept as
   separate steps; `install.sh` never calls `stow`.

2. **Link the configs with Stow** (see below).

Each top-level directory here is a Stow package: the directory tree inside it mirrors
`$HOME`, so Stow symlinks files back into place (e.g. `zsh/.zshrc` → `~/.zshrc`). The
repo lives directly in `~`, so Stow's default target is already correct — no `-t` flag
needed, and all commands below run from `~/dotfiles`.

## Applying settings on a machine

```sh
cd ~/dotfiles
stow zsh tmux nvim zed bash    # link everything
stow nvim                      # or just one package
```

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
