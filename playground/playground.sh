#!/bin/sh

if [ -z "$PLAYGROUND_DIR" ]
then
    echo_err "PLAYGROUND_DIR needs to be set to source playground.sh"
    return 1
fi

declare -A default_boilerplate_dirs
default_boilerplate_dirs[go]="$PLAYGROUND_DIR/boilerplates/basic_go"
default_boilerplate_dirs[c]="$PLAYGROUND_DIR/boilerplates/basic_c"
default_boilerplate_dirs[cpp]="$PLAYGROUND_DIR/boilerplates/basic_cpp"
default_boilerplate_dirs[rust]="$PLAYGROUND_DIR/boilerplates/basic_rust"
default_boilerplate_dirs[java]="$PLAYGROUND_DIR/boilerplates/basic_java"
default_boilerplate_dirs[java-mvn]="$PLAYGROUND_DIR/boilerplates/basic_java_mvn"
default_boilerplate_dirs[general]="$PLAYGROUND_DIR/boilerplates/general"
default_boilerplate_dirs[qemu]="$PLAYGROUND_DIR/boilerplates/basic_qemu"

setup_playground() {
    if [ $# -lt 2 ]; then
        echo "Usage: setup_playground <directory> <language> [<name> [<boilerplate_dir>]]"
        return 1
    fi

    local dir="$1"
    local lang="$2"
    local name="$3"

    if [ $# -eq 2 ]; then
        local target_dir="$( find "$dir" -maxdepth 1 -mindepth 1 -printf "%T@ %p\n" | sort -nr | cut -d' ' -f2- | fzf --height=50% --reverse --cycle )"
    else
        target_dir="$dir/$name"
    fi

    if [ -z "$target_dir" ]; then
        echo "target_dir was empty" >&2
        return 1
    fi

    local default_boilerplate="${default_boilerplate_dirs[$lang]}"
    local boilerplate_dir="$default_boilerplate"

    if [ $# -eq 4 ]; then
        custom_boilerplate_dir="$4"
        if [ -n "$custom_boilerplate_dir" ] && [ -d "$custom_boilerplate_dir" ]; then
            boilerplate_dir="$custom_boilerplate_dir"
        else
            echo "Boilerplate directory not found: $custom_boilerplate_dir" >&2
            return 1
        fi
    fi

    if [ -z "$boilerplate_dir" ]; then
        echo "Boilerplate directory not specified." >&2
        return 1
    fi

    if [ ! -d "$boilerplate_dir" ]; then
        echo "Boilerplate directory not found: $boilerplate_dir" >&2
        return 1
    fi

    if [ -d "$target_dir" ]; then
        echo "Target directory already exists: $target_dir. Taking you there"
        cd "$target_dir" || return 1
        return 0
    fi

    if [ -e "$target_dir" ]; then
        echo "$target_dir exists but isn't a directory" >&2
        return 1
    fi

    mkdir -p "$target_dir"
    cp -r "$boilerplate_dir/." "$target_dir"

    case "$lang" in
        java)
            local new_target_path="$target_dir/$name.java"
            mv "$target_dir"/Boilerplate.java "$new_target_path"
            sed -i "s/Boilerplate/$name/g" "$new_target_path"
            echo "export PLAYGROUND_JAVA_NAME=$name" > "$target_dir/.envrc"
            direnv allow "$target_dir"
            ;;
        *)
            ;;
    esac

    cd "$target_dir" || return 1
}

alias pgo='setup_playground "$HOME/playground/go" "go"'
alias prust='setup_playground "$HOME/playground/rust" "rust"'
alias pjava='setup_playground "$HOME/playground/java" "java-mvn"'
alias pgeneral='setup_playground "$HOME/playground/general" "general"'
alias pqemu='setup_playground "$HOME/playground/qemu" "qemu"'
alias pc='setup_playground "$HOME/playground/c" "c"'
alias pcpp='setup_playground "$HOME/playground/cpp" "cpp"'
pgit() {
    local repo_url=$1
    local clone_name=$2

    if [ -z "$repo_url" ]
    then
        setup_playground "$PLAYGROUND_DIR/git" "general"
        return
    fi

    cd "$PLAYGROUND_DIR"/git
    git clone $repo_url $clone_name

    if [ $? -ne 0 ]
    then
        echo "Failed to clone repo $repo_url"
        cd -
        return 1
    else
        echo "Cloned $repo_url"
    fi

    if [ -n "$clone_name" ]
    then
        cd "$clone_name"
    else
        local repo_name=$(basename -s .git "$repo_url")
        cd $repo_name
    fi
}

alias jc='javac ${PLAYGROUND_JAVA_NAME}.java'
alias jr='java ${PLAYGROUND_JAVA_NAME}'
alias jcr='jc;jr;'
alias j='nvim ${PLAYGROUND_JAVA_NAME}.java'

BACKUP_PLAYGROUND="$PLAYGROUND_DIR/backup"

pbackup() {
    local old_set_x_setting=${-//[^x]/}
    set -x
    for inp_path in "$@"
    do
        if [ ! -e  "$inp_path" ]
        then
            >&2 echo "Input $inp_path doesn't exist"
            if [ -z "$old_set_x_setting" ]
            then
                set +x
            fi
            return 1
        fi
    done

    for inp_path in "$@"
    do
        local full_path="$(realpath "$inp_path")"
        local new_path="${BACKUP_PLAYGROUND}${full_path}"
        local new_path_dir="$(dirname "$new_path")"

        mkdir -p "$new_path_dir"
        cp -a "$full_path" "$new_path_dir"
    done
    if [ -z "$old_set_x_setting" ]
    then
        set +x
    fi
}
