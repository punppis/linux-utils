# Bash autocomplete support
# @cmd autocomplete Print or install bash completion.

print_autocomplete() {
  cat <<'EOF'
_bumbuhelper_complete() {
  local cur prev words cword
  _init_completion -n : || return

  local cmds="utils interactive fs ssh docker data compress transform path file create_array ssh-circlejerk ssh-copy-id ssh-command install autocomplete get_current_script get_path compress decompress encrypt decrypt base64 hash archive rsync choose reset_permissions commands help colorize"
  if [[ ${cword} -eq 1 ]]; then
    COMPREPLY=( $(compgen -W "${cmds}" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == docker ]]; then
    COMPREPLY=( $(compgen -W "folders update update_all" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == docker && ${words[2]} == folders ]]; then
    COMPREPLY=( $(compgen -W "all" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == utils ]]; then
    COMPREPLY=( $(compgen -W "create_array colorize commands help install autocomplete" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == interactive ]]; then
    COMPREPLY=( $(compgen -W "choose" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == fs ]]; then
    COMPREPLY=( $(compgen -W "path file" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == ssh ]]; then
    COMPREPLY=( $(compgen -W "ssh-circlejerk ssh-copy-id ssh-command" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == data ]]; then
    COMPREPLY=( $(compgen -W "archive base64 compress decompress decrypt" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == compress ]]; then
    COMPREPLY=( $(compgen -W "compress decompress" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == transform ]]; then
    COMPREPLY=( $(compgen -W "encrypt decrypt base64 hash" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == path || ( ${words[1]} == fs && ${words[2]} == path ) ]]; then
    COMPREPLY=( $(compgen -W "get_current_script get_path" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == file || ( ${words[1]} == fs && ${words[2]} == file ) ]]; then
    COMPREPLY=( $(compgen -W "rsync reset_permissions" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == install || ( ${words[1]} == utils && ${words[2]} == install ) ]]; then
    COMPREPLY=( $(compgen -W "--system --user --dir --deps --no-autocomplete" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == autocomplete || ( ${words[1]} == utils && ${words[2]} == autocomplete ) ]]; then
    COMPREPLY=( $(compgen -W "--install --system --user" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == compress && ${cword} -eq 2 && ${cur} == -* ]]; then
    COMPREPLY=( $(compgen -W "--output --format" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == compress && ( ${words[2]} == compress ) ]]; then
    COMPREPLY=( $(compgen -W "--output --format" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == compress && ( ${words[2]} == decompress ) ]]; then
    COMPREPLY=( $(compgen -W "--output" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == transform && ( ${words[2]} == encrypt || ${words[2]} == decrypt ) ]]; then
    COMPREPLY=( $(compgen -W "--output --password" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == base64 || ( ${words[1]} == data && ${words[2]} == base64 ) || ( ${words[1]} == transform && ${words[2]} == base64 ) ]]; then
    COMPREPLY=( $(compgen -W "--decode --encode -d -e" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == hash || ( ${words[1]} == transform && ${words[2]} == hash ) ]]; then
    COMPREPLY=( $(compgen -W "--algo -a" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == choose ]]; then
    COMPREPLY=( $(compgen -W "--default -d --multi -m" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == reset_permissions || ( ${words[1]} == file && ${words[2]} == reset_permissions ) ]]; then
    COMPREPLY=( $(compgen -W "--files --dirs" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == data && ( ${words[2]} == compress ) ]]; then
    COMPREPLY=( $(compgen -W "--output --format" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == data && ( ${words[2]} == decompress ) ]]; then
    COMPREPLY=( $(compgen -W "--output" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == data && ${words[2]} == decrypt ]]; then
    COMPREPLY=( $(compgen -W "--output --password" -- "${cur}") )
    return
  fi

  if [[ ${words[1]} == archive || ( ${words[1]} == data && ${words[2]} == archive ) ]]; then
    COMPREPLY=( $(compgen -W "tar tar_gz base64" -- "${cur}") )
    return
  fi
}

complete -F _bumbuhelper_complete bumbuhelper
complete -F _bumbuhelper_complete bh
complete -F _bumbuhelper_complete bhelper
complete -F _bumbuhelper_complete bhelp
complete -F _bumbuhelper_complete helper
EOF
}

install_autocomplete() {
  local target=""
  local scope="user"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --system)
        scope="system"
        shift
        ;;
      --user)
        scope="user"
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  if [ "$scope" = "system" ]; then
    target="/etc/bash_completion.d/bumbuhelper"
  else
    target="$HOME/.local/share/bash-completion/completions/bumbuhelper"
  fi

  local dir
  dir="$(dirname "$target")"

  if [ ! -w "$dir" ]; then
    sudo mkdir -p "$dir"
    print_autocomplete | sudo tee "$target" >/dev/null
  else
    mkdir -p "$dir"
    print_autocomplete > "$target"
  fi

  log "Autocomplete installed: $target"
}
