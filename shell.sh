#!/bin/sMY_REP

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
export MY_PROJECTS_PATH="$HOME/projects"
alias q="cd $MY_PROJECTS_PATH"
alias i='[[ -e lib.rs ]] && vim lib.rs || vim init.lua'

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

# rust setup

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

export RUST_BACKTRACE=1

alias c='vim Cargo.toml'
alias cc='vim ../Cargo.toml'
alias ccc='vim ../../Cargo.toml'
alias cccc='vim ../../../Cargo.toml'

alias b='vim build.rs'
alias bb='vim ../build.rs'
alias bbb='vim ../../build.rs'
alias bbbb='vim ../../../build.rs'

# java setup
alias o='vim pom.xml'
alias oo='vim ../pom.xml'
alias ooo='vim ../../pom.xml'
alias oooo='vim ../../../pom.xml'

# go setup
alias g='vim go.mod'
alias gg='vim ../go.mod'
alias ggg='vim ../../go.mod'
alias gggg='vim ../../../go.mod'
export PATH="$HOME/my_tools/src/go/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# shell-setup
alias sc='nvim $SHELL_SETUP_PATH/shell.sh'

# My tools
. "$MY_PROJECTS_PATH"/backup_rm/backup_rm.sh
alias mt='cd "$MY_TOOLS_PATH"'
export PATH="$PATH:$MY_TOOLS_PATH/bin"

# playground
. "$SHELL_SETUP_PATH/playground/playground.sh"

# Paths
export PATH="$PATH:$HOME/.local/bin"

# i3
alias i3c="vim $HOME/.config/i3/config"
alias i3b="cd $HOME/.config/i3blocks"

# nvim
alias n="cd $HOME/.config/nvim"

# nvm
export NVM_DIR="$HOME/.nvm"
_nvm_lazy_load() {
  unset -f nvm node npm npx
  [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
}

nvm() { _nvm_lazy_load; nvm "$@"; }
node() { _nvm_lazy_load; node "$@"; }
npm()  { _nvm_lazy_load; npm  "$@"; }
npx()  { _nvm_lazy_load; npx  "$@"; }

# Start a single global ssh-agent
if [ -z "$SSH_AUTH_SOCK" ]; then
  if [ -f "$HOME/.ssh/agent.env" ]; then
    source "$HOME/.ssh/agent.env" >/dev/null
  fi
fi

if [ -z "$SSH_AUTH_SOCK" ]; then
  eval "$(ssh-agent -s)" >/dev/null
  echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$HOME/.ssh/agent.env"
  echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$HOME/.ssh/agent.env"
fi
