# dotfiles

Personal configuration files, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a Stow **package**. Inside a package, the directory tree
mirrors `$HOME`, so Stow can create symlinks that point from your home directory back
into this repo. For example, `zsh/.zshrc` becomes a symlink at `~/.zshrc`.

## Prerequisites

Install Stow, then clone this repo into `~/dotfiles`:

```sh
# Debian/Ubuntu
sudo apt install stow
# macOS
brew install stow

git clone <this-repo-url> ~/dotfiles
```

The repo lives directly in your home directory, so Stow's default target (the parent
of the repo, i.e. `~`) is already correct — no `-t` flag is needed. All commands below
are run from inside `~/dotfiles`.

## Applying settings on a machine

Link everything at once:

```sh
cd ~/dotfiles
stow zsh tmux nvim zed
```

Or link a single package:

```sh
stow nvim
```

Useful flags:

- `stow -n -v zsh` — dry run (`-n`) with verbose output (`-v`); shows what *would*
  be linked without touching anything. Run this first when unsure.
- `stow -R nvim` — restow (unlink then relink); use after adding or moving files
  within a package.

**Conflicts:** if a real file already exists where Stow wants to create a symlink
(e.g. a pre-existing `~/.zshrc`), Stow refuses and reports the conflict. Either back
up and remove the existing file first:

```sh
mv ~/.zshrc ~/.zshrc.bak
stow zsh
```

…or, if you want the existing file's contents to become the tracked version, use
`--adopt` (this **moves** the real file into the repo, overwriting the repo's copy —
review with `git diff` afterward):

```sh
stow --adopt zsh
git diff        # inspect what --adopt pulled in
```

## Adding a new config to the repo

To start tracking a config file, recreate its `$HOME`-relative path inside a new
package directory, move the real file in, then let Stow link it back.

General steps for a file at `~/<path>`:

1. `mkdir -p ~/dotfiles/<pkg>/<dir-of-path>`
2. `mv ~/<path> ~/dotfiles/<pkg>/<path>`
3. `cd ~/dotfiles && stow <pkg>` — recreates the symlink at `~/<path>`.
4. `git add <pkg> && git commit -m "feat: add <pkg> config"`

### Worked example: tracking `~/.gitconfig`

```sh
cd ~/dotfiles
mkdir -p git                       # new package, top level of the file is ~/.gitconfig
mv ~/.gitconfig git/.gitconfig     # move the real file into the package
stow git                           # ~/.gitconfig is now a symlink into the repo
git add git && git commit -m "feat: add git config"
```

### Worked example: tracking `~/.config/foo/config.toml`

The package tree must mirror the full path under `$HOME`:

```sh
cd ~/dotfiles
mkdir -p foo/.config/foo
mv ~/.config/foo/config.toml foo/.config/foo/config.toml
stow foo
git add foo && git commit -m "feat: add foo config"
```

## Updating and removing

- Edit a config normally — because it's a symlink into the repo, changes land here
  automatically. Commit them with git.
- `stow -R <pkg>` — restow after adding/moving files within a package.
- `stow -D <pkg>` — unlink (delete) a package's symlinks from your home directory.
  The files remain safely in the repo.
