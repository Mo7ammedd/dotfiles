# -----------------------------------------------------------------------------
# PATH
# -----------------------------------------------------------------------------
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# -----------------------------------------------------------------------------
# OH MY ZSH
# -----------------------------------------------------------------------------

export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="developer"

# Auto update
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 14

# Completion
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"

# Better completion UX
ENABLE_CORRECTION="false"
COMPLETION_WAITING_DOTS="false"

# Faster git repos
DISABLE_UNTRACKED_FILES_DIRTY="true"

# -----------------------------------------------------------------------------
# Plugins
# -----------------------------------------------------------------------------

plugins=(
  git
  sudo
  command-not-found
  colored-man-pages
  extract
  history
  copypath
  copyfile
  web-search
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Prompt, suggestions, and completion use a restrained dark palette.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#76747f'
ZSH_HIGHLIGHT_STYLES[command]='fg=#c4c2ee'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#c4c2ee'
ZSH_HIGHLIGHT_STYLES[function]='fg=#c4c2ee'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#9ed7d5'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f97386,bold'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#9ed7d5'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#9ed7d5'

zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{#c4c2ee}%d%f'
zstyle ':completion:*:messages' format '%F{#acaab5}%d%f'
zstyle ':completion:*:warnings' format '%F{#f97386}No matches%f'

# -----------------------------------------------------------------------------
# History
# -----------------------------------------------------------------------------

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------

export EDITOR="code --wait"
export VISUAL="$EDITOR"
export PAGER="bat"

# -----------------------------------------------------------------------------
# Better defaults
# -----------------------------------------------------------------------------

setopt AUTO_CD
setopt INTERACTIVE_COMMENTS
setopt HIST_REDUCE_BLANKS

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------


alias ccat="bat"

alias search="rg"

alias cls="clear"

alias c="code ."

alias reload="source ~/.zshrc"

alias zshconfig="code ~/.zshrc"

alias update="sudo pacman -Syu"

alias mkdir="mkdir -pv"

# Git
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gb="git branch"
alias gd="git diff"

# -----------------------------------------------------------------------------
# FZF
# -----------------------------------------------------------------------------

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# -----------------------------------------------------------------------------
# Zoxide
# -----------------------------------------------------------------------------

# # eval "$(zoxide init zsh)"

# -----------------------------------------------------------------------------
# Starship (optional)
# -----------------------------------------------------------------------------

# Uncomment after installing starship
# eval "$(starship init zsh)"

# -----------------------------------------------------------------------------
# Fastfetch
# -----------------------------------------------------------------------------

# Uncomment if you want system info every terminal launch
# fastfetch

export JAVA_HOME=/usr/lib/jvm/java-26-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
export AWS_REGION='us-west-2'

# Keep credentials in this untracked, machine-local file.
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
