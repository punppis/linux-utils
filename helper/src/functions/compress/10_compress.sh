# Compression helpers
# @cmd compress Create a tar/tar.gz archive from a path.

compress() {
  local input=""
  local output=""
  local format="tar"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --output|-o)
        output="$2"
        shift 2
        ;;
      --format)
        format="$2"
        shift 2
        ;;
      *)
        input="$1"
        shift
        ;;
    esac
  done

  [ -z "$input" ] && die "Usage: compress <path> [--output FILE] [--format tar|tar_gz|tar.gz|tgz]"
  [ ! -e "$input" ] && die "Input not found: $input"

  if [ -z "$output" ]; then
    case "$format" in
      tar) output="${input##*/}.tar" ;;
      tar_gz|tar.gz|tgz) output="${input##*/}.tar.gz" ;;
      *) die "Unsupported format: $format" ;;
    esac
  fi

  local base_dir
  base_dir="$(dirname "$input")"
  local name
  name="$(basename "$input")"

  case "$format" in
    tar)
      tar -C "$base_dir" -cf "$output" "$name"
      ;;
    tar_gz|tar.gz|tgz)
      tar -C "$base_dir" -czf "$output" "$name"
      ;;
    *)
      die "Unsupported format: $format"
      ;;
  esac
}

# @cmd decompress Extract a tar/tar.gz archive.

decompress() {
  local archive=""
  local output="."

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --output|-o)
        output="$2"
        shift 2
        ;;
      *)
        archive="$1"
        shift
        ;;
    esac
  done

  [ -z "$archive" ] && die "Usage: decompress <archive> [--output DIR]"
  [ ! -f "$archive" ] && die "Archive not found: $archive"

  mkdir -p "$output"

  case "$archive" in
    *.tar.gz|*.tgz)
      tar -C "$output" -xzf "$archive"
      ;;
    *.tar)
      tar -C "$output" -xf "$archive"
      ;;
    *)
      die "Unsupported archive: $archive"
      ;;
  esac
}
