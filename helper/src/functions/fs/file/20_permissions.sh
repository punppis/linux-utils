# Reset default permissions for files and folders
# @cmd reset_permissions Reset file/dir permissions (644/755).

reset_permissions() {
  local target="."
  local file_mode="644"
  local dir_mode="755"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --files)
        file_mode="$2"
        shift 2
        ;;
      --dirs)
        dir_mode="$2"
        shift 2
        ;;
      *)
        target="$1"
        shift
        ;;
    esac
  done

  [ -e "$target" ] || die "Path not found: $target"

  confirm_run find "$target" -type d -exec chmod "$dir_mode" {} +
  confirm_run find "$target" -type f -exec chmod "$file_mode" {} +
}
