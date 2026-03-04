# bumbuhelper

## Overview
A Bash helper toolkit built as a single executable monolith. Development is split into function files, then built into one script.

## Project Structure
```
helper
├── build.sh
├── bin
│   └── bumbuhelper
├── src
│   ├── app.sh
│   └── functions
│       ├── 00_env.sh
│       ├── 01_utils.sh
│       ├── 10_help.sh
│       ├── 20_create_array.sh
│       ├── 30_ssh_copy_id.sh
│       ├── 31_ssh_circlejerk.sh
│       ├── 32_ssh_command.sh
│       ├── 40_docker_folders.sh
│       ├── 50_install.sh
│       └── 60_autocomplete.sh
└── README.md
```

## Build
```
./build.sh
```

## Install (one-liner)
```
curl -fsSL <URL_TO_MONOLITH> | sudo bash -s -- install --system
```

## Autocomplete (optional)
```
bumbuhelper autocomplete --install --user
```

## Tests
```
./tests/run-tests.sh
```

## Usage Examples

(from bash)
```
cat rows.txt | helper create_array
cat entries.csv | helper create_array --separators ","

helper ssh-circlejerk host1 host2 host3
cat hosts.txt | helper ssh-circlejerk
cat hosts.csv | helper ssh-circlejerk
helper ssh-circlejerk < hosts.somefile

helper ssh-copy-id host1 host2 host3

helper ssh-command "echo hello, im $(hostname)" "date" host1 host2 host3

helper docker folders all
```