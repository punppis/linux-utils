# Transform helpers
# @cmd encrypt Encrypt a file with a password (OpenSSL).
# @cmd decrypt Decrypt a file with a password (OpenSSL).
# @cmd base64 Encode/decode base64 (auto-detect by default).
# @cmd hash Hash input or files (default: sha256).

encrypt() {
  local input=""
  local output=""
  local password="${BUMBUHELPER_PASSWORD:-}"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --output|-o)
        output="$2"
        shift 2
        ;;
      --password|-p)
        password="$2"
        shift 2
        ;;
      *)
        input="$1"
        shift
        ;;
    esac
  done

  [ -z "$password" ] && die "Missing password (use --password or BUMBUHELPER_PASSWORD)"

  if [ -z "$input" ]; then
    [ -z "$output" ] && die "Usage: encrypt <file> [--output FILE] --password PASS"
    openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$password" -out "$output"
    return
  fi

  [ ! -f "$input" ] && die "Input not found: $input"

  if [ -z "$output" ]; then
    output="$input.enc"
  fi

  openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$password" -in "$input" -out "$output"
}

decrypt() {
  local input=""
  local output=""
  local password="${BUMBUHELPER_PASSWORD:-}"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --output|-o)
        output="$2"
        shift 2
        ;;
      --password|-p)
        password="$2"
        shift 2
        ;;
      *)
        input="$1"
        shift
        ;;
    esac
  done

  [ -z "$password" ] && die "Missing password (use --password or BUMBUHELPER_PASSWORD)"

  if [ -z "$input" ]; then
    [ -z "$output" ] && die "Usage: decrypt <file> [--output FILE] --password PASS"
    openssl enc -aes-256-cbc -d -pbkdf2 -pass pass:"$password" -out "$output"
    return
  fi

  [ ! -f "$input" ] && die "Input not found: $input"

  if [ -z "$output" ]; then
    output="${input%.enc}"
    if [ "$output" = "$input" ]; then
      output="$input.dec"
    fi
  fi

  openssl enc -aes-256-cbc -d -pbkdf2 -pass pass:"$password" -in "$input" -out "$output"
}

base64_cmd() {
  local mode="auto"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --decode|-d)
        mode="decode"
        shift
        ;;
      --encode|-e)
        mode="encode"
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  local input=""
  if [ "$#" -gt 0 ] && [ -t 0 ]; then
    input="$*"
  else
    input="$(cat)"
  fi

  if [ -z "$input" ]; then
    return 0
  fi

  case "$mode" in
    encode)
      printf '%s' "$input" | base64
      return
      ;;
    decode)
      printf '%s' "$input" | base64 --decode
      return
      ;;
  esac

  local normalized
  normalized="$(printf '%s' "$input" | tr -d '\n\r\t ')"
  local len="${#normalized}"

  if [[ "$normalized" =~ ^[A-Za-z0-9+/=]+$ ]] && [ $((len % 4)) -eq 0 ]; then
    if printf '%s' "$normalized" | base64 --decode >/dev/null 2>&1; then
      printf '%s' "$normalized" | base64 --decode
      return
    fi
  fi

  printf '%s' "$input" | base64
}

hash_cmd() {
  local algo="sha256"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --algo|-a)
        algo="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  local mode="stdin"
  local input=""

  if [ "$#" -gt 0 ] && [ -f "$1" ]; then
    mode="file"
    input="$1"
  elif [ "$#" -gt 0 ] && [ -t 0 ]; then
    mode="text"
    input="$*"
  else
    input="$(cat)"
  fi

  [ -z "$input" ] && die "No input provided."

  if command -v openssl >/dev/null 2>&1; then
    if [ "$mode" = "file" ]; then
      openssl dgst "-$algo" "$input" | awk '{print $NF}'
    else
      printf '%s' "$input" | openssl dgst "-$algo" | awk '{print $NF}'
    fi
    return
  fi

  case "$algo" in
    sha256)
      if command -v sha256sum >/dev/null 2>&1; then
        if [ "$mode" = "file" ]; then
          sha256sum "$input" | awk '{print $1}'
        else
          printf '%s' "$input" | sha256sum | awk '{print $1}'
        fi
        return
      fi
      ;;
    sha1)
      if command -v sha1sum >/dev/null 2>&1; then
        if [ "$mode" = "file" ]; then
          sha1sum "$input" | awk '{print $1}'
        else
          printf '%s' "$input" | sha1sum | awk '{print $1}'
        fi
        return
      fi
      ;;
    sha512)
      if command -v sha512sum >/dev/null 2>&1; then
        if [ "$mode" = "file" ]; then
          sha512sum "$input" | awk '{print $1}'
        else
          printf '%s' "$input" | sha512sum | awk '{print $1}'
        fi
        return
      fi
      ;;
    md5)
      if command -v md5sum >/dev/null 2>&1; then
        if [ "$mode" = "file" ]; then
          md5sum "$input" | awk '{print $1}'
        else
          printf '%s' "$input" | md5sum | awk '{print $1}'
        fi
        return
      fi
      ;;
  esac

  die "Hash tool not available for algo: $algo"
}
