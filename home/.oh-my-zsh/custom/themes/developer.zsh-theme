# Two-line developer prompt. All decorations and status labels are ASCII.
autoload -Uz add-zsh-hook
zmodload zsh/datetime
setopt prompt_subst

# Oh My Zsh fetches these Git segments asynchronously.
ZSH_THEME_GIT_PROMPT_PREFIX=' %F{#76747f}|%f %F{#9ed7d5}git:'
ZSH_THEME_GIT_PROMPT_SUFFIX='%f'
ZSH_THEME_GIT_PROMPT_CLEAN=''
ZSH_THEME_GIT_PROMPT_DIRTY=''
ZSH_THEME_GIT_PROMPT_UNTRACKED=' %F{#f3c77b}untracked%f'
ZSH_THEME_GIT_PROMPT_ADDED=' %F{#f3c77b}staged%f'
ZSH_THEME_GIT_PROMPT_MODIFIED=' %F{#f3c77b}modified%f'
ZSH_THEME_GIT_PROMPT_RENAMED=' %F{#f3c77b}renamed%f'
ZSH_THEME_GIT_PROMPT_DELETED=' %F{#f3c77b}deleted%f'
ZSH_THEME_GIT_PROMPT_UNMERGED=' %F{#f97386}conflict%f'
ZSH_THEME_GIT_PROMPT_AHEAD=' %F{#acaab5}ahead%f'
ZSH_THEME_GIT_PROMPT_BEHIND=' %F{#f3c77b}behind%f'
ZSH_THEME_GIT_PROMPT_DIVERGED=' %F{#f97386}diverged%f'
ZSH_THEME_GIT_PROMPT_STASHED=' %F{#acaab5}stash%f'

export VIRTUAL_ENV_DISABLE_PROMPT=1
typeset -g _developer_runtime='' _developer_details=''
typeset -g _developer_node_key='' _developer_node_version=''
typeset -g _developer_last_directory=''
typeset -g _developer_prompt_colour='#c4c2ee'
typeset -gF _developer_command_started=0

_developer_update_runtime() {
  local project_dir=$PWD node_project='' node_binary=${commands[node]-}
  local runtime_key environment_name

  # Recognize package subdirectories without running a package manager.
  while true; do
    if [[ -f $project_dir/package.json || -f $project_dir/.nvmrc || -f $project_dir/.node-version ]]; then
      node_project=$project_dir
      break
    fi
    [[ $project_dir == / || $project_dir == $HOME || -e $project_dir/.git ]] && break
    project_dir=${project_dir:h}
  done

  runtime_key="${node_project}:${node_binary}"
  if [[ $runtime_key != $_developer_node_key ]]; then
    _developer_node_key=$runtime_key
    _developer_node_version=''
    if [[ -n $node_project && -n $node_binary ]]; then
      _developer_node_version=$("$node_binary" --version 2>/dev/null)
      [[ $_developer_node_version == v[0-9]* ]] || _developer_node_version=''
    fi
  fi

  _developer_runtime=''
  if [[ -n $_developer_node_version ]]; then
    _developer_runtime=" %F{#76747f}|%f %F{#acaab5}node:${_developer_node_version#v}%f"
  fi
  if [[ -n ${VIRTUAL_ENV-} ]]; then
    environment_name=${VIRTUAL_ENV:t}
    _developer_runtime+=" %F{#76747f}|%f %F{#acaab5}venv:${environment_name//\%/%%}%f"
  elif [[ -n ${CONDA_DEFAULT_ENV-} ]]; then
    environment_name=$CONDA_DEFAULT_ENV
    _developer_runtime+=" %F{#76747f}|%f %F{#acaab5}conda:${environment_name//\%/%%}%f"
  fi
}

_developer_preexec() {
  _developer_command_started=$EPOCHREALTIME
}

_developer_precmd() {
  local -i command_exit=$?
  local -F command_elapsed=0
  local -i elapsed_seconds=0

  # Do not display a cached branch or status from the previous directory.
  if [[ $PWD != $_developer_last_directory ]]; then
    if (( ${+_OMZ_ASYNC_OUTPUT} )); then
      _OMZ_ASYNC_OUTPUT[_omz_git_prompt_info]=''
      _OMZ_ASYNC_OUTPUT[_omz_git_prompt_status]=''
    fi
    _developer_last_directory=$PWD
  fi

  _developer_details=''
  _developer_prompt_colour='#c4c2ee'
  if (( command_exit )); then
    _developer_details="%F{#f97386}exit:${command_exit}%f"
    _developer_prompt_colour='#f97386'
  fi

  if (( _developer_command_started > 0 )); then
    command_elapsed=$(( EPOCHREALTIME - _developer_command_started ))
    if (( command_elapsed >= 2 )); then
      elapsed_seconds=$(( command_elapsed + 0.5 ))
      [[ -n $_developer_details ]] && _developer_details+='  '
      if (( elapsed_seconds >= 60 )); then
        _developer_details+="%F{#acaab5}took:$(( elapsed_seconds / 60 ))m$(( elapsed_seconds % 60 ))s%f"
      else
        _developer_details+="%F{#acaab5}took:${elapsed_seconds}s%f"
      fi
    fi
  fi
  _developer_command_started=0
  _developer_update_runtime
  return 0
}

# Capture the command's exit code before other prompt hooks run. Reloading is safe.
typeset -ga precmd_functions
precmd_functions=(_developer_precmd "${(@)precmd_functions:#_developer_precmd}")
add-zsh-hook -d preexec _developer_preexec
add-zsh-hook preexec _developer_preexec

typeset -g _developer_context=''
if [[ -n ${SSH_CONNECTION-}${SSH_TTY-} ]] || (( EUID == 0 )); then
  _developer_context='%F{#acaab5}%n@%m%f '
fi

PROMPT=$'\n''${_developer_context}%B%F{#c4c2ee}%50<...<%~%<<%f%b$(git_prompt_info)$(git_prompt_status)${_developer_runtime}'$'\n''%F{${_developer_prompt_colour}}%(!.#.$)%f '
RPROMPT='${_developer_details}'
PS2='%F{#76747f}%_> %f'
