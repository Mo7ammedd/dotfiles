# Dotfiles

Private snapshot of my Arch Linux configuration, captured on 2026-09-18.
The `home/` directory mirrors my home directory. These are copies; editing
this repository does not change the active configuration or sync it automatically.

| Configuration | Location under `home/` |
| --- | --- |
| Zsh, Bash, Powerlevel10k, and Git | `.zshrc`, `.bash*`, `.p10k.zsh`, `.gitconfig` |
| Custom Oh My Zsh prompt | `.oh-my-zsh/custom/themes/developer.zsh-theme` |
| Hyprland, idle/lock settings, and scripts | `.config/hypr/` |
| Quickshell source and local customizations | `.config/quickshell/ii/`, `.config/quickshell/caelestia/` |
| Desktop shell settings | `.config/illogical-impulse/`, `.config/caelestia/` |
| Terminals and launchers | `.config/kitty/`, `.config/ghostty/`, `.config/fuzzel/`, `.config/rofi/` |
| Editors | `.config/nvim/`, `.config/Code/User/`, `.config/Cursor/User/`, `.config/zed/` |
| Theme generation, GTK, fonts, and application themes | `.config/matugen/`, `.config/gtk-*/`, `.config/fontconfig/`, and related theme directories |
| Command-line tools and desktop preferences | Fastfetch, btop, htop, Cava, GitHub CLI, OpenCode, Thunar, systemd user units, and XDG settings |

The current desktop starts **illogical-impulse** with `qs -c ii` and uses
Hyprland's Lua configuration. The customized Caelestia shell is also preserved.
Its build output is excluded; its source contains the original build instructions.

## Restore

Install the applications and dependencies before using their configurations.
The Zsh configuration expects [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh),
[zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions), and
[zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting).
Install those separately before restoring the custom prompt. Desktop source and
dependency information is listed in [THIRD_PARTY.md](THIRD_PARTY.md).

Clone with a GitHub account that has access to this private repository:

```sh
git clone https://github.com/Mo7ammedd/dotfiles.git "$HOME/dotfiles"
cd "$HOME/dotfiles"
```

Preview copying missing configuration files with rsync:

```sh
rsync -avni --ignore-existing home/ "$HOME/"
```

After reviewing the preview, copy them:

```sh
rsync -avi --ignore-existing home/ "$HOME/"
```

Existing files are skipped. Back them up and merge any desired changes manually.
Some settings retain `/home/mohammed` paths, device preferences, and references to
installed programs, fonts, themes, and wallpapers. Adjust those for another machine.
The wallpaper collection, installed theme/icon packages, and generated desktop
state are separate from this snapshot; choose a wallpaper after restoring.

## Credentials and exclusions

Credential exports were removed from the repository's `.zshrc`. It optionally
loads `~/.zshrc.local`, which is ignored by Git. Configure `AWS_BEARER_TOKEN_BEDROCK`
and `REWAAQ_API_KEY` locally if needed. OpenCode's existing credential-file reference
is preserved; the referenced credential file is excluded. Sign in to the GitHub CLI
separately with `gh auth login`.

SSH/GPG keys, credentials, environment files, package-manager authentication,
browser and application profiles, shell/clipboard history, editor sessions,
backups, caches, build output, downloaded dependencies, and the large wallpaper
collection are excluded. The initial snapshot was checked with Gitleaks 8.30.1
and a check for the credential values removed from the shell configuration.

To update this snapshot, copy only the intended configuration changes into
`home/`, remove embedded credentials, and review `git diff` before committing.
`.gitignore` does not detect credentials added inside an already tracked file.
