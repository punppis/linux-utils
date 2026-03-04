# Data helpers
# @cmd archive Create an archive (tar/tar_gz/base64). Default: tar.

archive() {
  local mode="tar"
  local output=""

  if [ "$#" -gt 0 ]; then
    case "$1" in
      tar|tar_gz|tar.gz|tgz|base64)
        mode="$1"
        shift
        ;;
    esac
  fi

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --output|-o)
        output="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  case "$mode" in
    base64)
      base64_cmd "$@"
      ;;
    tar|tar_gz|tar.gz|tgz)
      local format="$mode"
      if [ "$format" = "tar_gz" ]; then
        format="tar.gz"
      fi
      if [ -n "$output" ]; then
        compress "$@" --output "$output" --format "$format"
      else
        compress "$@" --format "$format"
      fi
      ;;
    *)
      die "Usage: archive [tar|tar_gz|base64] <path> [--output FILE]"
      ;;
  esac
}
