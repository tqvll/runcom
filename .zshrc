#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
alias cl="clear"
alias emacs="emacs -nw"
alias gopen="gnome-open"
alias pbcopy="xsel --clipboard --input"

alias glg="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias glga="git log --graph --all --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
alias gd='git diff'
alias gau='git add -u'
alias gac='git add .'
alias gst='git status'
alias gstt='git status -uno'
alias gco='git checkout'
alias gf='git fetch'
alias gm='git merge'
alias gmd='git merge origin/develop'
alias gpl='git pull'
alias gcm='git commit -m'
alias gp='git push'
alias gpoh='git push origin HEAD'
alias gcp='git cherry-pick'
alias gb='git branch'
alias gba='git branch -a'

setopt nonomatch

setopt share_history
setopt histignorealldups
HISTFILE=~/.zhistory
HISTSIZE=10000
SAVEHIST=10000

setopt auto_cd

export PATH=$PATH:~/.local/bin:/usr/local/go/bin:~/go/bin
export GOPATH=~/go

# Virtualenvwrapper
if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    export WORKON_HOME=~/.virtualenvs
    source /usr/local/bin/virtualenvwrapper.sh
fi

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="~/.sdkman"
[[ -s "~/.sdkman/bin/sdkman-init.sh" ]] && source "~/.sdkman/bin/sdkman-init.sh"

[[ -s "~/.gvm/scripts/gvm" ]] && source "~/.gvm/scripts/gvm"
