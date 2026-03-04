# rsync helper
# @cmd rsync Rsync sources to destination with progress.

rsync_helper() {
  [ "$#" -lt 2 ] && die "Usage: rsync <src...> <dest>"

  local dest="${!#}"
  local -a sources=("${@:1:$#-1}")

  confirm_run rsync -a --info=progress2 "${sources[@]}" "$dest"
}
