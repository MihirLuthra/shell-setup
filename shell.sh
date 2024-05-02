#!/bin/sh

if [ -n "$BASH_VERSION"  ]
then
    SHELL_SETUP_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
elif [ -n "$ZSH_VERSION" ]
then
    SHELL_SETUP_PATH="${${(%):-%N}:A:h}"
else
    echo_err "Only bash and zsh are supported"
    return 1
fi

if [ -z "$MY_TOOLS_PATH" ]
then
    echo_err "MY_TOOLS_PATH needs to be set to source shell-setup/shell.sh"
    return 1
fi

. "$SHELL_SETUP_PATH/helper-funcs.sh"

# general setup
alias open=xdg-open
alias sai='sudo apt install'
NUM_CPUS="$(nproc --all)"

# cd to parent dir of given path
cdd() {
    if [ $# -ne 1 ]
    then
	>&2 echo "usage: cdd <file_path>"
	return 1
    fi

    cd "$(dirname "$1")"
}

## For git editor
export VISUAL="$MY_TOOLS_PATH"/bin/nvim
export EDITOR="$VISUAL"

# vim aliases
alias vi=nvim
alias vim=nvim

# git aliases
alias ga='git add'
alias gs='git status'
alias gc='git commit -m'
alias gd='git diff'
alias gl='git log'
alias gr='git rebase -i'
alias gcm='git commit --amend'
alias gb='git branch'
alias grv='git remote -v'
alias gch='git checkout'
alias gdf='git diff-tree --no-commit-id --name-only -r'
alias gcpx='git cherry-pick -x'

# zsh and bash files aliases
alias zr='nvim ~/.zshrc'
alias br='nvim ~/.bashrc'

# Rust setup

# If cargo build uses all CPUs,
# it becomes hard to browse anything else
export CARGO_BUILD_JOBS=$( calc "int($NUM_CPUS/2)" )

# MY_CARGO_BUILD_JOBS are used in commands like
# cargo build. Generally, while doing a `cargo build`,
# it is desired to use almost max CPUs.
if [ $NUM_CPUS -ge 4 ]
then
    MY_CARGO_BUILD_JOBS=$(calc "$NUM_CPUS-2")
else
    MY_CARGO_BUILD_JOBS=$NUM_CPUS
fi

alias rtl='rustup toolchain list'
alias rtal='rustup target list'

alias cn='cargo new'
alias cb='cargo build -j $MY_CARGO_BUILD_JOBS'
alias cr='cargo run -j $MY_CARGO_BUILD_JOBS'
alias cs='cargo search'
alias cdop='cargo doc --open --document-private-items'
alias cdo='cargo doc --open'

if [ -f "$HOME/.cargo/env" ]
then
    . "$HOME/.cargo/env"
fi

# Shell setup
alias sc='nvim $SHELL_SETUP_PATH/shell.sh'

# My tools
. "$MY_TOOLS_PATH"/src/backup_rm.sh
alias mt='cd "$MY_TOOLS_PATH"'
export PATH="$MY_TOOLS_PATH/bin:$PATH"

# playground
. "$SHELL_SETUP_PATH/playground/playground.sh"
