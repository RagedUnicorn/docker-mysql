#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description build script for docker-mysql container

# abort when trying to use unset variable
set -euo pipefail

# variable setup
DOCKER_MYSQL_TAG="com.ragedunicorn/mysql"
DOCKER_MYSQL_NAME="mysql"
DOCKER_MYSQL_DATA_VOLUME="mysql_data"

# get absolute path to script and change context to script folder
SCRIPTPATH="$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"
cd "${SCRIPTPATH}"

echo "$(date) [INFO]: Building container: ${DOCKER_MYSQL_NAME}"

# build mysql container
docker build -t "${DOCKER_MYSQL_TAG}" ../

# check if mysql data volume already exists
docker volume inspect "${DOCKER_MYSQL_DATA_VOLUME}" > /dev/null 2>&1

if [ $? -eq 0 ]; then
  echo "$(date) [INFO]: Reusing existing volume: ${DOCKER_MYSQL_DATA_VOLUME}"
else
  echo "$(date) [INFO]: Creating new volume: ${DOCKER_MYSQL_DATA_VOLUME}"
  docker volume create --name "${DOCKER_MYSQL_DATA_VOLUME}" > /dev/null
fi
