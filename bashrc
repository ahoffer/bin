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
HISTFILESIZE=20000


alias pickjava='source $HOME/bin/pickjava'  #no subshell so it can source a file
alias install-node='source $HOME/bin/install-node'  #no subshell so it can source a file
alias ll='ls -alh'
alias k='kubectl'
complete -F __start_kubectl k
alias helmlogin='helm registry login $SSF_NEXUS_HOST --username $SSF_NEXUS_USER --password $SSF_NEXUS_TOKEN'
alias sourceb='source ~/.bashrc'
alias k3stop='sudo systemctl stop k3s && dstop'
alias k3go='sudo systemctl start k3s'


# Do not set JAVA_HOME here. It gets written and re-written in ~/.bashrc
#export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

export KUBECONFIG=~/.kube/config
export YAMLLINT_CONFIG_FILE=/home/aaron/bin/.yamllint

alias pickjava='. $HOME/bin/pickjava' #source trick


# Add Go binaries to PATH if Go is installed
command -v go >/dev/null 2>&1 && export PATH="$PATH:$(go env GOPATH)/bin"

# Append history lines immediately
export PROMPT_COMMAND="history -a; history -n"
shopt -s histappend

#Tab completion for kubectl, if kubectl is available
command -v kubectl &>/dev/null && source <(kubectl completion bash)

#Tab completion for Helm, if helm is available
command -v helm &>/dev/null && source <(helm completion bash)

#Tab completion for nerdctl, if it is available
command -v nerdctl &>/dev/null && source <(nerdctl completion bash)

#Set path to Container Network Interface
export CNI_PATH=~/.local/libexec/cni

