# Install monolith script
# @cmd install Install bumbuhelper and aliases.

install_self() {
  local target_dir="/usr/local/bin"
  local name="bumbuhelper"
  local install_deps=0
  local install_autocomplete_default=1
  local -a deps=(bash sed tr sort wc dirname mktemp tar gzip base64 openssl rsync find chmod awk)

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --system)
        target_dir="/usr/local/bin"
        shift
        ;;
      --user)
        target_dir="$HOME/.local/bin"
        shift
        ;;
      --dir)
        target_dir="$2"
        shift 2
        ;;
      --deps)
        install_deps=1
        shift
        ;;
      --no-autocomplete)
        install_autocomplete_default=0
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  local -a missing=()
  local dep
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      missing+=("$dep")
    fi
  done

  if [ "${#missing[@]}" -gt 0 ]; then
    if [ "$install_deps" -eq 1 ]; then
      if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y
        sudo apt-get install -y coreutils sed
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y coreutils sed
      elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm coreutils sed
      elif command -v apk >/dev/null 2>&1; then
        sudo apk add coreutils sed
      elif command -v brew >/dev/null 2>&1; then
        brew install coreutils gnu-sed
      else
        die "Missing deps: ${missing[*]}. Install them manually."
      fi
    else
      log_warn "Missing deps: ${missing[*]} (run install with --deps to attempt install)"
    fi
  fi

  local tmp=""
  local use_stdin=0

  if [ ! -t 0 ]; then
    use_stdin=1
    tmp="$(mktemp)"
    cat > "$tmp"
    chmod +x "$tmp"
  else
    tmp="$(get_current_script)"
  fi

  if [ ! -w "$target_dir" ]; then
    sudo mkdir -p "$target_dir"
    if [ "$use_stdin" -eq 1 ]; then
      sudo mv "$tmp" "$target_dir/$name"
    else
      sudo cp "$tmp" "$target_dir/$name"
    fi
    sudo chmod +x "$target_dir/$name"
  else
    mkdir -p "$target_dir"
    if [ "$use_stdin" -eq 1 ]; then
      mv "$tmp" "$target_dir/$name"
    else
      cp "$tmp" "$target_dir/$name"
    fi
    chmod +x "$target_dir/$name"
  fi

  log "Installed to $target_dir/$name"

  local -a aliases=(bh bhelper bhelp helper)
  local alias
  if [ ! -w "$target_dir" ]; then
    for alias in "${aliases[@]}"; do
      sudo ln -sf "$target_dir/$name" "$target_dir/$alias"
    done
  else
    for alias in "${aliases[@]}"; do
      ln -sf "$target_dir/$name" "$target_dir/$alias"
    done
  fi
  log "Aliases installed: ${aliases[*]}"

  if [ "$install_autocomplete_default" -eq 1 ]; then
    local scope="--user"
    if [ ! -w "$target_dir" ]; then
      scope="--system"
    elif [[ "$target_dir" != "$HOME"/* ]]; then
      scope="--system"
    fi
    install_autocomplete "$scope"
    if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
      source <(print_autocomplete) >/dev/null 2>&1 || true
    fi
  fi
}
