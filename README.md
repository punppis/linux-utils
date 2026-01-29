My collection of bash scripts.

## Tools

### docker-compose-update

A robust Debian/Ubuntu-friendly tool to update Docker Compose stacks.

**Usage:**

```bash
# Update only currently running compose projects (default)
./packages/docker-compose-update/docker-compose-update

# Update all compose projects under /opt (with --all)
./packages/docker-compose-update/docker-compose-update --all

# Update all projects under a custom root directory
./packages/docker-compose-update/docker-compose-update --all --root /srv --max-depth 3

# Dry run to see what would be executed
./packages/docker-compose-update/docker-compose-update --all --dry-run

# Update running projects and prune after each
./packages/docker-compose-update/docker-compose-update --prune-each
```

**Options:**

- `--all` - Scan for all compose files and update all projects (default: update only running)
- `--root DIR` - Root directory to scan for compose files (default: /opt, only used with --all)
- `--max-depth N` - Maximum directory depth to scan (default: 6, only used with --all)
- `--no-prune` - Skip Docker system prune (default: prune once at the end)
- `--prune-each` - Run Docker system prune after each project update
- `--dry-run` - Print commands without executing them
- `--help, -h` - Show help message

**Behavior:**

*Default mode (no --all):*
- Detects currently running Docker Compose projects by inspecting container labels
- Updates only those running projects

*--all mode:*
- Scans for compose files (docker-compose.yml, compose.yml, etc.) under the specified root
- Updates all found projects

*For each project:*
1. Changes to the project's working directory (to respect local overrides, .env, etc.)
2. Runs: `docker compose pull`
3. Runs: `docker compose up -d --force-recreate --remove-orphans`

*Docker cleanup:*
- Runs: `docker system prune -a --volumes --force`
- By default: prune once at the end
- With `--prune-each`: prune after each project
- With `--no-prune`: skip pruning entirely

**Requirements:**

- Docker Engine with docker compose plugin
- Debian/Ubuntu/Raspberry Pi environment
- Sufficient permissions to run docker commands (may require sudo)

### create-package

A tool to create new package directories with bash script templates.

**Usage:**

```bash
# Using command-line arguments
./create-package "My Tool"

# Using stdin (piped input)
echo "My Tool" | ./create-package
```

**Behavior:**

- Creates a directory with the sanitized package name under `./packages/`
- Generates an executable bash script inside the directory with the same name
- The generated script includes a shebang, error handling, and a simple hello message

**Name Sanitization Rules:**

Package names are automatically sanitized:
- Converted to lowercase
- Whitespace and underscores are replaced with dashes (any run of spaces, tabs, underscores becomes a single dash)
- All other invalid characters are removed (only `[a-z0-9-]` are retained)
- Multiple consecutive dashes are collapsed into one
- Leading and trailing dashes are removed

**Examples:**

```bash
# Creates: packages/my-tool/my-tool
./create-package "My Tool"

# Creates: packages/my-repo/my-repo
./create-package "my repo"

# Creates: packages/my-repo2/my-repo2
./create-package "my  ^ repo2"

# Creates: packages/hello-world/hello-world
echo "Hello_World" | ./create-package

# Creates: packages/test123/test123
./create-package "test123"
```

**Error Handling:**

- If the sanitized name is empty (e.g., only special characters), the script exits with an error
- If a directory with that name already exists, the script exits with an error message
