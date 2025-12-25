source ~/.local/share/zinit/zinit.git/zinit.zsh

# ---- History file (make sure it's shared) ----
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt AUTO_CD

# ---- History behavior ----
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

autoload -Uz compinit && compinit -C
zstyle ':completion:*' matcher-list 'r:|?=**'

zinit ice depth=1
zinit light sindresorhus/pure

zinit light zsh-users/zsh-autosuggestions

zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

zinit ice wait lucid
zinit light zsh-users/zsh-completions

zinit ice wait lucid
zinit light Aloxaf/fzf-tab
# zstyle ':fzf-tab:complete:*' fzf-preview 'ls --color=always $realpath'

zinit snippet OMZL::directories.zsh

export MY_TOOLS_PATH="$HOME/my-tools"
export PLAYGROUND_DIR="$HOME/playground"

source "$HOME/projects/shell-setup/shell.sh"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# on ctrl+left arrow, go back a word
bindkey '^[[1;5D' backward-word
# on ctrl+right arrow, go back a word
bindkey '^[[1;5C' forward-word
