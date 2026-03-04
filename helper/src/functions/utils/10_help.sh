# Help output
# @cmd help Show this help text.

show_help() {
  cat <<'EOF'
bumbuhelper ⚡ — a tiny toolbox with docker-compose vibes

Usage:
  bumbuhelper <group> <command> [options]
  bumbuhelper <command> [options]

Aliases:
  bumbuhelper, bh, bhelper, bhelp, helper

Groups:
  utils        create_array, colorize, commands, help, install, autocomplete
  interactive choose
  fs           path, file
  ssh          ssh-circlejerk, ssh-copy-id, ssh-command
  docker       folders, update, update_all
  data         archive, base64, compress, decompress, decrypt
  compress     compress, decompress
  transform    encrypt, decrypt, base64, hash

Group commands:
  utils <create_array|colorize|commands|help|install|autocomplete>
  interactive <choose>
  fs path <get_current_script|get_path>
  fs file <rsync|reset_permissions>
  ssh <ssh-circlejerk|ssh-copy-id|ssh-command>
  docker <folders|update|update_all>
  data <archive|base64|compress|decompress|decrypt>
  compress <compress|decompress>
  transform <encrypt|decrypt|base64|hash>

Direct commands (still supported):
  create_array, colorize, get_current_script, get_path, compress, decompress,
  encrypt, decrypt, base64, hash, archive, rsync, reset_permissions,
  ssh-circlejerk, ssh-copy-id, ssh-command

Examples:
  cat rows.txt | helper utils create_array
  cat entries.csv | helper utils create_array --separators ","

  helper ssh ssh-circlejerk host1 host2 host3
  cat hosts.txt | helper ssh ssh-circlejerk
  helper ssh ssh-circlejerk < hosts.somefile

  helper ssh ssh-copy-id host1 host2 host3
  helper ssh ssh-command "echo hello, im $(hostname)" "date" host1 host2 host3

  helper docker folders all
  helper docker update
  helper docker update_all

  helper fs path get_current_script
  helper fs file rsync /data host1:/data

  helper compress compress ./data
  helper compress decompress data.tar --output ./out
  helper transform encrypt secrets.txt --password "hunter2"
  helper transform decrypt secrets.txt.enc --password "hunter2"
  printf 'hello' | helper transform base64
  printf 'hello' | helper transform hash

  helper data archive tar ./data
  helper data archive tar_gz ./data --output data.tgz
  printf 'hello' | helper data archive base64

  bh utils colorize blue "blue text"
  bh choose a b c d:default
  bh choose --multi a b c d
  bh reset_permissions ./data --files 644 --dirs 755
  bh commands
EOF
}
