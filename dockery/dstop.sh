#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description stop script for docker-mysql container

# abort when trying to use unset variable
set -o nounset

# variable setup
DOCKER_MYSQL_NAME="mysql"

# get absolute path to script and change context to script folder
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
cd "${SCRIPTPATH}"

# search running container
docker ps | grep "${DOCKER_MYSQL_NAME}" > /dev/null

# if container is running - stop it
if [ $? -eq 0 ]; then
  echo "$(date) [INFO]: Stopping container "${DOCKER_MYSQL_NAME}" ..."
  docker stop "${DOCKER_MYSQL_NAME}" > /dev/null
else
  echo "$(date) [INFO]: No running container with name: ${DOCKER_MYSQL_NAME} found"
fi
