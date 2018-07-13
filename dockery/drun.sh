#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description run script for docker-mysql container

set -euo pipefail

# variable setup
DOCKER_MYSQL_TAG="com.ragedunicorn/mysql"
DOCKER_MYSQL_NAME="mysql"
DOCKER_MYSQL_DATA_VOLUME="mysql_data"
DOCKER_MYSQL_ID=0

# get absolute path to script and change context to script folder
SCRIPTPATH="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
cd "${SCRIPTPATH}"

# check if there is already an image created
docker inspect ${DOCKER_MYSQL_NAME} &> /dev/null

if [ $? -eq 0 ]; then
  # start container
  docker start "${DOCKER_MYSQL_NAME}"
else
  ## run image:
  # -v mount volume
  # -d run in detached mode
  # --name define a name for the container(optional)
  DOCKER_MYSQL_ID=$(docker run \
  -v mysql_data:/var/lib/mysql \
  -d \
  --name "${DOCKER_MYSQL_NAME}" "${DOCKER_MYSQL_TAG}")
fi

if [ $? -eq 0 ]; then
  # print some info about containers
  echo "$(date) [INFO]: Container info:"
  docker inspect -f '{{ .Config.Hostname }} {{ .Name }} {{ .Config.Image }} {{ .NetworkSettings.IPAddress }}' ${DOCKER_MYSQL_NAME}
else
  echo "$(date) [ERROR]: Failed to start container - ${DOCKER_MYSQL_NAME}"
fi
