import subprocess
from os import system
from sys import exit
from string import Template

# Return a dictionary given a string.
# If the string is contained in the name of a docker containers, return the container name and ID.
# Otherwise, return an error flag and description.
# WARNING: Very naive. Doesn't account for headers or string that show up in other places than in the docker ps command.
def grepcontainer(input):
    output = subprocess.run(["docker", "ps"],  stdout=subprocess.PIPE, text=True)
    lines= output.stdout.split("\n")
    matches = [x for x in lines if input in x]
    returnObject = {"error" : False}
    if not matches:
        print()
        returnObject["error"] = True
        returnObject["message"] = f'Nothing matches {input}'
    else:
        firstMatch = matches[0]
        containerInfo = firstMatch.split(' ')
        returnObject["id"] =containerInfo[0]
        returnObject["name"] = containerInfo[-1]
    return returnObject

# Execute a command for a docker container.
# This function does some verification of the inputs.
def execute_docker(cmd, container):
    if not container:
        print("The (partial) name of the docker container is missing. Please try again.")
        exit(-1)
    output = grepcontainer(container)
    if output["error"]:
        print(output["message"])
        exit(-2)
    completedCmd = Template(cmd).substitute(name = output["id"])
    system(completedCmd)