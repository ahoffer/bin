# Things I normally add to bash and can put under source control.
# Add this code the ~/.bashrc to make this work.
# If ~/bin/bashrc exists and is readable, source it
# if [ -r "${HOME}/bin/bashrc" ]; then
#  source "${HOME}/bin/bashrc"
#fi

alias e='gnome-text-editor'

# Do not set JAVA_HOME here. It gets written and re-written in ~/.bashrc
#export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export KUBECONFIG=~/.kube/config:~/.kube/mm-config
export YAMLLINT_CONFIG_FILE=/home/aaron/bin/.yamllint

# This alias is trick. If you use it, you don't have to source anthing after you update JAVA_HOME
alias pickjava="source ~/bin/pickjava"

