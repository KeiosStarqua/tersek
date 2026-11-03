# Terminal setup

Notes to rebuild my terminal on a new machine.

| Tool | Role | Version in use |
| --- | --- | --- |
| [Foot](https://codeberg.org/dnkl/foot) | Terminal emulator (Wayland) | 1.25.0 |
| [herdr](https://herdr.dev) | Terminal workspace / multiplexer, runs inside Foot | 0.9.5 |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` | 0.10.0 |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder | 0.74.5 (Homebrew) |
| [Atuin](https://github.com/atuinsh/atuin) | Shell history search and sync | 18.24.4 |
| [carapace-bin](https://carapace-sh.github.io/carapace-bin/install.html) | Multi-shell command completion | not installed on this machine yet |
| [Starship](https://starship.rs) | Shell prompt | not installed on this machine yet |

Shells: bash (`~/.bashrc`) and zsh (`~/.zshrc`).

## Install

Where each tool lives on my machine:

| Tool | Path |
| --- | --- |
| foot | `/usr/bin/foot` (system package) |
| herdr | `~/.local/bin/herdr` |
| zoxide | `~/.local/bin/zoxide` |
| fzf | `/home/linuxbrew/.linuxbrew/bin/fzf` (Homebrew) |
| atuin | `~/.atuin/bin/atuin` |
| carapace | not installed here; see below |
| starship | not installed here; the installer puts it in `/usr/local/bin` by default |

```bash
# Foot (Debian/Ubuntu example; use your distro's package manager)
sudo apt install foot

# herdr: install from https://herdr.dev, binary goes to ~/.local/bin

# zoxide
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# fzf
brew install fzf

# Atuin
curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh

# carapace-bin: pick one method from
# https://carapace-sh.github.io/carapace-bin/install.html
brew install carapace                      # Homebrew
# or on Debian/Ubuntu via the fury.io apt repo:
curl -fsSL https://apt.fury.io/rsteube/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/rsteube.gpg
echo "deb [signed-by=/usr/share/keyrings/rsteube.gpg] https://apt.fury.io/rsteube/ /" | sudo tee /etc/apt/sources.list.d/fury.list
sudo apt-get update && sudo apt-get install carapace-bin

# Starship
curl -sS https://starship.rs/install.sh | sh
```

## Shell configuration

### `~/.bashrc`

```bash
export PATH="$HOME/.local/bin:$PATH"
eval "$(zoxide init bash)"

# ... other config ...

. "$HOME/.atuin/bin/env"
eval "$(atuin init bash)"

# carapace (not in my ~/.bashrc yet)
source <(carapace _carapace)

# starship (not in my ~/.bashrc yet)
eval "$(starship init bash)"
```

### `~/.zshrc`

```zsh
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

# carapace (not in my ~/.zshrc yet)
source <(carapace _carapace)

# starship (not in my ~/.zshrc yet)
eval "$(starship init zsh)"
```

zoxide is only initialized in bash right now. To get it in zsh, add
`eval "$(zoxide init zsh)"`.

### `~/.profile` and `~/.bash_profile`

Both source the Atuin env so login shells find the binary:

```bash
. "$HOME/.atuin/bin/env"
```

## Per-tool notes

### Foot

No custom config. Foot runs on its defaults, with no `~/.config/foot/foot.ini`.
Add one there when I start changing fonts, colors, or keybindings.

### herdr

Config: `~/.config/herdr/config.toml`

```toml
onboarding = false

[ui]
sidebar_collapsed_mode = "compact"
```

Runtime files (`session.json`, `session-snapshots/`, logs, sockets) live in the
same directory. They are state, not config, so I don't back them up.

### zoxide

Provides `z` and `zi` after `eval "$(zoxide init bash)"`.

```bash
z foo        # jump to the best match for "foo"
zi foo       # pick a match interactively (uses fzf)
zoxide query -l   # list the tracked directories with scores
```

### fzf

Installed through Homebrew. There is no `fzf --bash` or `fzf --zsh` line in my
rc files, so the default `Ctrl-T`, `Alt-C` and `Ctrl-R` bindings are not active.
`zi` from zoxide still uses it. To enable the bindings, add this to `~/.bashrc`
before the Atuin lines:

```bash
eval "$(fzf --bash)"
```

### Atuin

Replaces shell history search. `atuin init` binds `Ctrl-R` and the Up arrow.
Config lives in `~/.config/atuin/` (only `atuin-receipt.json` so far; Atuin's
settings go in `config.toml` there).

```bash
atuin search <query>   # search history from the command line
atuin stats            # usage stats
atuin status           # sync status (if logged in)
```

Ordering matters: `atuin init` comes last in `~/.bashrc`. If you add fzf's
`Ctrl-R` binding, put the Atuin line after it so Atuin keeps `Ctrl-R`.

### carapace-bin

Provides completions for many CLI tools in bash and zsh from one binary. It is
not installed on this machine and not in my rc files yet. Once installed, add
`source <(carapace _carapace)` to the rc files (see "Shell configuration"),
then restart the shell. Check the shell setup page in the
[carapace docs](https://carapace-sh.github.io/carapace-bin/) if the bash or
zsh syntax has changed.

### Starship

Cross-shell prompt, installed with `curl -sS https://starship.rs/install.sh | sh`.
It is not installed on this machine and not in my rc files yet. Once installed,
add `eval "$(starship init bash)"` (or `zsh`) to the rc files. Config goes in
`~/.config/starship.toml`, which doesn't exist yet, so Starship would run on
its defaults. If the prompt behaves oddly with Atuin, check the order of the
two `init` lines.

## Setting up on a new machine

1. Install the tools above.
2. Make sure `~/.local/bin` is on `PATH`.
3. Add the snippets from "Shell configuration" to the rc files, including carapace and Starship.
4. Copy `~/.config/herdr/config.toml`.
5. Restart the shell, then run `atuin login` and `atuin sync` if I use sync.
