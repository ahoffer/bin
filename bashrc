# Things I normally add to bash and can put under source control.
# Add this code the ~/.bashrc to make this work.
# When ~/bin/bashrc exists and is readable, source it
#
# if [ -r "${HOME}/bin/bashrc" ]; then
#  source "${HOME}/bin/bashrc"
#fi

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
 
 
# Only append if not already present
grep -qxF 'export PATH="$HOME/bin:$PATH"' ~/.profile || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.profile


HISTSIZE=50
HISTFILESIZE=2000


alias e='gnome-text-editor'
alias pickjava='source $HOME/bin/pickjava'  #no subshell so it can source a file
alias install-node='source $HOME/bin/install-node'  #no subshell so it can source a file
alias ll='ls -alh'


# Do not set JAVA_HOME here. It gets written and re-written in ~/.bashrc
#export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"

export KUBECONFIG=~/.kube/config:~/.kube/mm-config
export YAMLLINT_CONFIG_FILE=/home/aaron/bin/.yamllint

alias pickjava='. $HOME/bin/pickjava' #source trick


export PATH=$PATH:$(go env GOPATH)/bin


