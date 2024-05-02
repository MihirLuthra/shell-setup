#!/bin/sh

echo_err() {
    >&2 echo "$@"
}

# Pass math calculations to awk
# A single arg should be passed without any space in it.
calc() {
    awk "BEGIN { print "$*" }";
}

open_prefix() {
    local prefix="$1"
    local nullglob_was_enabled=0

    if [ -n "$BASH_VERSION" ]; then
        if shopt -q nullglob; then
            nullglob_was_enabled=1
        else
            shopt -s nullglob  # Enable null globbing if not already enabled
        fi
    elif [ -n "$ZSH_VERSION" ]; then
        if setopt | grep -q nullglob; then
            nullglob_was_enabled=1
        else
            setopt nullglob  # Enable null globbing if not already enabled
        fi
    fi

    local matches=("$prefix".*)

    if [ $nullglob_was_enabled -eq 0 ]; then
        if [ -n "$BASH_VERSION" ]; then
            shopt -u nullglob  # Disable null globbing if it was enabled in this function
        elif [ -n "$ZSH_VERSION" ]; then
            unsetopt nullglob  # Disable null globbing if it was enabled in this function
        fi
    fi

    if [ ${#matches[@]} -eq 0 ]; then
        echo_err "No files matching '$prefix.*' found."
        return 1
    elif [ ${#matches[@]} -eq 1 ]; then
        vim "$matches"
    else
        echo_err "Multiple files matching '$prefix.*' found:"
        printf "%s\n" "${matches[@]}"
        return 1
    fi
}


alias m='open_prefix main'
