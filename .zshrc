#
# ~/.zshrc — managed in ~/git/runcom
# 対話シェル用の設定。マシン固有の設定は ~/.zshrc.local に書く。
#

# ---------------------------------------------------------------- Prezto
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# ---------------------------------------------------------------- PATH
# typeset -U で重複を排除。(N-/) は「存在するディレクトリだけ」を意味する glob 修飾子。
typeset -U path PATH fpath
path=(
  $HOME/.local/bin(N-/)
  $HOME/.roswell/bin(N-/)
  $HOME/go/bin(N-/)
  /usr/local/go/bin(N-/)
  $path
)

# ---------------------------------------------------------------- 環境変数
export EDITOR='emacs -nw'
export VISUAL="$EDITOR"
export CLICOLOR=1
: ${LANG:=en_US.UTF-8}
export LANG
# TERM は端末エミュレータ自身に決めさせる（固定すると truecolor 判定や tmux が壊れる）

# ---------------------------------------------------------------- ヒストリ
HISTFILE=$HOME/.zhistory
HISTSIZE=100000
SAVEHIST=100000
setopt share_history          # 複数の端末でヒストリを共有
setopt extended_history       # 実行時刻と所要時間も記録
setopt hist_ignore_all_dups   # 重複は古いほうを捨てる
setopt hist_ignore_space      # 行頭スペースのコマンドは残さない
setopt hist_reduce_blanks
setopt hist_verify            # ヒストリ展開は一度確認してから実行

# ---------------------------------------------------------------- シェルの挙動
setopt auto_cd                # ディレクトリ名だけで cd
setopt auto_pushd             # cd の履歴を自動で積む
setopt pushd_ignore_dups
setopt pushd_silent
setopt interactive_comments   # 対話シェルでも # コメントを使える
setopt nonomatch              # マッチしない glob をエラーにしない
setopt no_beep no_hist_beep no_list_beep
setopt correct

# cdr（過去に訪れたディレクトリ）を有効化
autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
add-zsh-hook chpwd chpwd_recent_dirs
zstyle ':chpwd:*' recent-dirs-max 500

# ---------------------------------------------------------------- ファジーファインダ
# fzf があれば fzf、無ければ peco を使う。ff() がどちらかに解決される。
if (( $+commands[fzf] )); then
  export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border --info=inline'
  (( $+commands[fd] )) && export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
  # Ctrl-R=履歴 / Ctrl-T=ファイル / Alt-C=ディレクトリ
  source <(fzf --zsh) 2>/dev/null
  ff() { fzf "$@" }
elif (( $+commands[peco] )); then
  ff() { peco }

  # Ctrl-R: ヒストリを絞り込む
  peco-history() {
    BUFFER=$(\history -n -r 1 | awk '!seen[$0]++' | peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle reset-prompt
  }
  zle -N peco-history
  bindkey '^r' peco-history

  # Ctrl-U: 過去に移動したディレクトリへ飛ぶ
  peco-cdr() {
    local dest
    dest=$(cdr -l | sed -E 's/^[0-9]+ +//' | peco --query "$LBUFFER")
    if [[ -n $dest ]]; then
      BUFFER="cd ${dest}"
      zle accept-line
    else
      zle reset-prompt
    fi
  }
  zle -N peco-cdr
  bindkey '^u' peco-cdr
else
  ff() { cat }
fi

# ---------------------------------------------------------------- エイリアス
alias vi='vim'
alias cl='clear'
alias emacs='emacs -nw'

# モダンな代替コマンドが入っていれば使う
if (( $+commands[eza] )); then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --git --group-directories-first'
  alias la='eza -la --git --group-directories-first'
  alias lt='eza --tree --level=2'
else
  alias ll='ls -lh'
  alias la='ls -lAh'
fi
(( $+commands[bat] )) && alias cat='bat --style=plain --paging=never'

# git（同じ操作は ~/.gitconfig の alias にもある）
alias glg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias glga="git log --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias gd='git diff'
alias gau='git add -u'
alias gac='git add .'
alias gst='git status'
alias gstt='git status -uno'
alias gco='git checkout'
alias gsw='git switch'
alias gf='git fetch'
alias gm='git merge'
alias gmd='git merge origin/develop'
alias gpl='git pull'
alias gcm='git commit -m'
alias gp='git push'
alias gpoh='git push origin HEAD'
alias gpf='git push --force-with-lease'
alias gcp='git cherry-pick'
alias gb='git branch'
alias gba='git branch -a'

# ブランチをファジーに選んで切り替える: git checkout lb
alias -g lb='$(git branch | ff | sed -E "s/^[*+ ]*//")'
# 動いているコンテナをファジーに選んで入る
alias de='docker exec -it $(docker ps | ff | cut -d" " -f1) /bin/bash'

# ---------------------------------------------------------------- ツール連携
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[direnv] )) && eval "$(direnv hook zsh)"

# Python: virtualenvwrapper（lazy 版があればそちらを使い、起動を遅くしない）
export WORKON_HOME=$HOME/.virtualenvs
for _vew in /usr/local/bin/virtualenvwrapper_lazy.sh /usr/local/bin/virtualenvwrapper.sh; do
  if [[ -r $_vew ]]; then
    export VIRTUALENVWRAPPER_PYTHON=${commands[python3]:-/usr/bin/python3}
    source $_vew
    break
  fi
done
unset _vew

# ---------------------------------------------------------------- マシン固有設定
[[ -r $HOME/.zshrc.local ]] && source $HOME/.zshrc.local
