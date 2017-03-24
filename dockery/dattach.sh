#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description script for attaching to running docker-mysql container

# abort when trying to use unset variable
set -o nounset

# variable setup
DOCKER_MYSQL_NAME="mysql"

# get absolute path to script and change context to script folder
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
cd "${SCRIPTPATH}"

echo "$(date) [INFO]: attaching to container ${DOCKER_MYSQL_NAME}. To detach from the container use Ctrl-p Ctrl-q"
# attach to container
docker attach "${DOCKER_MYSQL_NAME}"
