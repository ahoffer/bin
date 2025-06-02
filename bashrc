# Things I normally add to bash and can put under source control.
# Add this code the ~/.bashrc to make this work.
# When ~/bin/bashrc exists and is readable, source it
#
# if [ -r "${HOME}/bin/bashrc" ]; then
#  source "${HOME}/bin/bashrc"
#fi


# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

export HISTCONTROL=ignoredups
shopt -s histappend
PROMPT_COMMAND='history -a'


# THINGS TO DEFINE IN 	~/.bashrc
# export SSF_NEXUS_HOST=
# export SSF_NEXUS_USER=
# export SSF_NEXUS_TOKEN=
# export RUNSHIFT_HOST=
# export RUNSHIFT_USER=
# export RUNSHIFT_TOKEN=
# export SSF_GITLAB_HOST=
# export SSF_GITLAB_USER=
# export SSF_GITLAB_TOKEN=


#Log into registries and such
#docker login "$RUNSHIFT_HOST" -u $RUNSHIFT_USER -p "$RUNSHIFT_TOKEN"
#helm registry login $SSF_NEXUS_HOST -u $export SSF_NEXUS_USER -p "$SSF_NEXUS_TOKEN" 
 
# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi


HISTSIZE=50
HISTFILESIZE=2000


alias e='geany'
alias pickjava='source $HOME/bin/pickjava'  #no subshell so it can source a file
alias install-node='source $HOME/bin/install-node'  #no subshell so it can source a file
alias ll='ls -alh'
alias k='kubectl -n octo-mcs'
alias h='history'
alias helmlogin='helm registry login $SSF_NEXUS_HOST --username $SSF_NEXUS_USER --password $SSF_NEXUS_TOKEN'
alias sourceb='source ~/.bashrc'

# Do not set JAVA_HOME here. It gets written and re-written in ~/.bashrc
#export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

export KUBECONFIG=~/.kube/config:~/.kube/mm-config
export YAMLLINT_CONFIG_FILE=/home/aaron/bin/.yamllint

alias pickjava='. $HOME/bin/pickjava' #source trick


# Add Go binaries to PATH if Go is installed
command -v go >/dev/null 2>&1 && export PATH="$PATH:$(go env GOPATH)/bin"

# Append history lines immediately
export PROMPT_COMMAND="history -a; history -n"
shopt -s histappend
