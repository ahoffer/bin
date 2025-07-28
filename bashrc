# This file is for things I normally add to .bashrc, but want to move under source control.

# -----COPY this code to ~/.bashrc-----

# Set the PATH to include user's bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# (commented out in this file to prevent infinite loop)
# When ~/bin/bashrc exists and is readable, source it
# if [ -r "${HOME}/bin/bashrc" ]; then
#     source "${HOME}/bin/bashrc"
# fi

# -----END COPY------


# There might be scripts or alias in this repository that depend on these env vars.
# Define these secrets in ~/.bashrc so that don't show up in source control.
#
# export SSF_NEXUS_HOST=
# export SSF_NEXUS_USER=
# export SSF_NEXUS_TOKEN=
# export RUNSHIFT_HOST=
# export RUNSHIFT_USER=
# export RUNSHIFT_TOKEN=
# export SSF_GITLAB_HOST=
# export SSF_GITLAB_USER=

# Log into registries and such
#docker login "$RUNSHIFT_HOST" -u $RUNSHIFT_USER -p "$RUNSHIFT_TOKEN"
#helm registry login $SSF_NEXUS_HOST -u $export SSF_NEXUS_USER -p "$SSF_NEXUS_TOKEN" 
# ----------------------------------------------------------------------------------------------------------

# Setup history so that commands from all open shells get written to one history log
export HISTCONTROL=ignoredups
shopt -s histappend
HISTSIZE=50
HISTFILESIZE=20000
# Append history lines immediately
export PROMPT_COMMAND="history -a; history -n"
# ----------------------------------------------------------------------------------------------------------


alias pickjava='source $HOME/bin/pickjava'  #no subshell so it can source a file
alias install-node='source $HOME/bin/install-node'  #no subshell so it can source a file
alias ll='ls -alh'
alias k='kubectl'
alias pickjava='. $HOME/bin/pickjava'
alias sourceb='source ~/.bashrc'
alias helmlogin='helm registry login $SSF_NEXUS_HOST --username $SSF_NEXUS_USER --password $SSF_NEXUS_TOKEN'
alias sourceb='source ~/.bashrc'
alias k3stop='sudo systemctl stop k3s && dstop'
alias k3go='sudo systemctl start k3s'
alias docker='nerdctl'
# ----------------------------------------------------------------------------------------------------------


# ----- EXPORT VARS HERE -----
export KUBECONFIG=~/.kube/config
export YAMLLINT_CONFIG_FILE=/home/aaron/bin/.yamllint

# Set path to Container Network Interface
export CNI_PATH=~/.local/libexec/cni

# Use later version of Docker buildkit
export DOCKER_BUILDKIT=1

# Do not set JAVA_HOME here. It gets written and re-written in ~/.bashrc
# export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

# Add Go binaries to PATH if Go is installed
command -v go >/dev/null 2>&1 && export PATH="$PATH:$(go env GOPATH)/bin"
# ----------------------------------------------------------------------------------------------------------


# ----- TAB COMPLETIONS GO HERE -----
#Tab completion for kubectl, if kubectl is available
command -v kubectl &>/dev/null && source <(kubectl completion bash)

#Tab completion for Helm, if helm is available
command -v helm &>/dev/null && source <(helm completion bash)

#Tab completion for nerdctl, if it is available
command -v nerdctl &>/dev/null && source <(nerdctl completion bash)

command -v regctl &>/dev/null && source <(regctl completion bash)

# Completions for the alias "k"
complete -F __start_kubectl k

# Use later version of Docker buildkit
export DOCKER_BUILDKIT=1
# ----------------------------------------------------------------------------------------------------------

