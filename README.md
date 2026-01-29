My collection of bash scripts.

## Tools

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

- Creates a directory with the sanitized package name
- Generates an executable bash script inside the directory with the same name
- The generated script includes a shebang, error handling, and a simple hello message

**Name Sanitization Rules:**

Package names are automatically sanitized:
- Converted to lowercase
- Any run of whitespace characters (spaces, tabs, etc.) is replaced with a single dash
- All other special characters are removed (only `[a-z0-9-]` are retained)
- Multiple consecutive dashes are collapsed into one
- Leading and trailing dashes are removed

**Examples:**

```bash
# Creates: my-tool/my-tool
./create-package "My Tool"

# Creates: my-repo/my-repo
./create-package "my repo"

# Creates: my-repo2/my-repo2
./create-package "my  ^ repo2"

# Creates: test123/test123
./create-package "test123"
```

**Error Handling:**

- If the sanitized name is empty (e.g., only special characters), the script exits with an error
- If a directory with that name already exists, the script exits with an error message