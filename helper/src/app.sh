#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# @cmd utils Group: general utilities.
# @cmd interactive Group: interactive helpers.
# @cmd fs Group: filesystem helpers (path/file).
# @cmd ssh Group: ssh helpers.
# @cmd docker Group: docker helpers.
# @cmd data Group: data helpers.
# @cmd compress Group: compression helpers.
# @cmd transform Group: encryption/base64/hash helpers.
# @cmd path Group: path utilities.
# @cmd file Group: file utilities.

if [ -d "$ROOT_DIR/functions" ]; then
    for dir in utils interactive fs ssh docker data compress transform; do
        if [ -d "$ROOT_DIR/functions/$dir" ]; then
            while IFS= read -r f; do
                # shellcheck source=/dev/null
                . "$f"
            done < <(find "$ROOT_DIR/functions/$dir" -type f -name '*.sh' | sort)
        fi
    done
fi

is_internal_command() {
    case "${1:-}" in
        help|-h|--help|commands|create_array|colorize|arg|ssh-circlejerk|ssh-copy-id|ssh-command|docker|install|autocomplete|get_current_script|get_path|compress|decompress|encrypt|decrypt|base64|hash|archive|rsync|choose|reset_permissions|utils|interactive|fs|ssh|data|compress|transform|path|file)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

is_group_command() {
    case "${1:-}" in
        utils|interactive|fs|ssh|docker|data|compress|transform|path|file)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

run_internal() {
    case "${1:-}" in
        help|-h|--help)
            show_help
            ;;
        commands)
            list_commands
            ;;
        create_array)
            shift
            create_array "$@"
            ;;
        colorize)
            shift
            colorize_cmd "$@"
            ;;
        arg)
            shift
            arg "$@"
            ;;
        ssh-circlejerk)
            shift
            ssh_circlejerk "$@"
            ;;
        ssh-copy-id)
            shift
            ssh_copy_id_multi "$@"
            ;;
        ssh-command)
            shift
            ssh_command_multi "$@"
            ;;
        docker)
            shift
            case "${1:-}" in
                folders)
                    if [ "${2:-}" = "all" ]; then
                        docker_folders_all
                    else
                        die "Usage: docker folders all"
                    fi
                    ;;
                update)
                    docker_update
                    ;;
                update_all)
                    docker_update_all
                    ;;
                *)
                    die "Usage: docker <folders|update|update_all>"
                    ;;
            esac
            ;;
        install)
            shift
            install_self "$@"
            ;;
        autocomplete)
            shift
            if [ "${1:-}" = "--install" ]; then
                shift
                install_autocomplete "$@"
            else
                print_autocomplete
            fi
            ;;
        get_current_script)
            shift
            get_current_script "$@"
            ;;
        get_path)
            shift
            get_path "$@"
            ;;
        compress)
            shift
            if [ "${1:-}" = "compress" ] || [ "${1:-}" = "decompress" ]; then
                run_internal "$@"
            else
                compress "$@"
            fi
            ;;
        decompress)
            shift
            decompress "$@"
            ;;
        encrypt)
            shift
            encrypt "$@"
            ;;
        decrypt)
            shift
            decrypt "$@"
            ;;
        base64)
            shift
            base64_cmd "$@"
            ;;
        hash)
            shift
            hash_cmd "$@"
            ;;
        archive)
            shift
            archive "$@"
            ;;
        rsync)
            shift
            rsync_helper "$@"
            ;;
        choose)
            shift
            choose "$@"
            ;;
        reset_permissions)
            shift
            reset_permissions "$@"
            ;;
        utils)
            shift
            case "${1:-}" in
                create_array|colorize|arg|commands|help|install|autocomplete)
                    run_internal "$@"
                    ;;
                *)
                    die "Usage: utils <create_array|colorize|arg|commands|help|install|autocomplete>"
                    ;;
            esac
            ;;
        interactive)
            shift
            case "${1:-}" in
                choose)
                    run_internal "$@"
                    ;;
                *)
                    die "Usage: interactive <choose>"
                    ;;
            esac
            ;;
        fs)
            shift
            case "${1:-}" in
                path|file)
                    run_internal "$@"
                    ;;
                *)
                    die "Usage: fs <path|file>"
                    ;;
            esac
            ;;
        ssh)
            shift
            case "${1:-}" in
                ssh-circlejerk|ssh-copy-id|ssh-command)
                    run_internal "$@"
                    ;;
                *)
                    die "Usage: ssh <ssh-circlejerk|ssh-copy-id|ssh-command>"
                    ;;
            esac
            ;;
        data)
            shift
            case "${1:-}" in
                archive|base64|compress|decompress|decrypt)
                    run_internal "$@"
                    ;;
                *)
                    die "Usage: data <archive|base64|compress|decompress|decrypt>"
                    ;;
            esac
            ;;
        transform)
            shift
            case "${1:-}" in
                encrypt|decrypt|base64|hash)
                    run_internal "$@"
                    ;;
                *)
                    die "Usage: transform <encrypt|decrypt|base64|hash>"
                    ;;
            esac
            ;;
        path)
            shift
            case "${1:-}" in
                get_current_script|get_path)
                    run_internal "$@"
                    ;;
                *)
                    die "Usage: path <get_current_script|get_path>"
                    ;;
            esac
            ;;
        file)
            shift
            case "${1:-}" in
                rsync|reset_permissions)
                    run_internal "$@"
                    ;;
                *)
                    die "Usage: file <rsync|reset_permissions>"
                    ;;
            esac
            ;;
        *)
            die "Unknown command: ${1:-}"
            ;;
    esac
}

main() {
    if [ "$#" -eq 0 ]; then
        show_help
        exit 1
    fi

    if is_alias_name "${1:-}"; then
        shift
    fi

    if [ "$#" -ge 2 ] && is_internal_command "${1:-}" && is_internal_command "${2:-}" && ! is_group_command "${1:-}"; then
        local first="$1"
        local second="$2"
        shift 2
        run_internal "$first" | run_internal "$second" "$@"
        return
    fi

    run_internal "$@"
}

main "$@"