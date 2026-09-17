# Upstream sources

This snapshot preserves local customizations along with the configuration and
source files they depend on. Existing copyright and license notices remain in
their original files. Upstream material retains its original license.

| Component | Upstream | Snapshot details |
| --- | --- | --- |
| illogical-impulse, Hyprland configuration, and related desktop files | [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) | Installed source plus local changes; no upstream Git revision was available in the installed directory. GPL-3.0 license in `LICENSES/end-4-GPL-3.0.txt`. |
| Caelestia shell | [caelestia-dots/shell](https://github.com/caelestia-dots/shell) | Based on `4e57199fd54f7e53191cc3481143f43cd9582e41`, including the current local changes. License in `home/.config/quickshell/caelestia/LICENSE`. |
| Oh My Zsh | [ohmyzsh/ohmyzsh](https://github.com/ohmyzsh/ohmyzsh) | Installed revision `c6e66edee824d83e84473ec666917b58323630df`; install separately. Only the custom `developer` theme is included. |
| zsh-autosuggestions | [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Installed revision `85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5`; install separately. |
| zsh-syntax-highlighting | [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Installed revision `1d85c692615a25fe2293bdd44b34c217d5d2bf04`; install separately. |

Quickshell, Hyprland, Caelestia's compiled plugin, the illogical-impulse runtime
dependencies, editor plugins, fonts, icon themes, and applications are not installed
by this repository. Follow the relevant upstream installation instructions.
