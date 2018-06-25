#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description launch script for mysql

# abort when trying to use unset variable
set -o nounset

function create_data_dir {
  echo "$(date) [INFO]: Creating data directory ${MYSQL_DATA_DIR} and setting permissions"
  mkdir -p "${MYSQL_DATA_DIR}"
  chmod -R 0700 "${MYSQL_DATA_DIR}"
  chown -R "${MYSQL_GROUP}":"${MYSQL_USER}" "${MYSQL_DATA_DIR}"
}

function create_run_dir {
  echo "$(date) [INFO]: Creating run directory ${MYSQL_RUN_DIR} and setting permissions"
  mkdir -p "${MYSQL_RUN_DIR}"
  chown -R "${MYSQL_GROUP}":"${MYSQL_USER}" "${MYSQL_RUN_DIR}"
}

function set_init_done {
  touch "${MYSQL_DATA_DIR}"/setup.d
  echo "$(date) [INFO]: Init script done"
}

function init {
  if [ -f "${MYSQL_DATA_DIR}/setup.d" ]; then
    echo "$(date) [INFO]: Init script already run - starting MYSQL"

    # check if run directory exists
    create_run_dir
    # start mysql in foreground with base- and datadir set
    exec gosu ${MYSQL_USER} /usr/bin/mysqld_safe --datadir="${MYSQL_DATA_DIR}"
  else
    echo "$(date) [INFO]: First time setup - running init script"
    create_data_dir
    create_run_dir

    if [ $? -ne 0 ]; then
      echo "$(date) [ERROR]: Failed to initialize mysqld - aborting...";
      exit 1
    fi

    # do not listen to external connections during setup. This helps while orchestarting with
    # other containers. They will only receive a response after the initialistation is finished.
    /usr/bin/mysqld_safe --bind-address=localhost --datadir="${MYSQL_DATA_DIR}" --user="${MYSQL_USER}" &

    LOOP_LIMIT=13
    i=1

    while true
    do
      if [ ${i} -eq ${LOOP_LIMIT} ]; then
        echo "$(date) [ERROR]: Timeout error, failed to start MYSQL server"
        exit 1
      fi

      echo "$(date) [INFO]: Waiting for confirmation of MYSQL service startup, trying ${i}/${LOOP_LIMIT}..."
      sleep 5

      # use initial password of mysql
      mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "status" > /dev/null 2>&1 && break
      i=$((i + 1))
    done

    # use default root password to set new root password
    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" | mysql -uroot -proot

    # create new user and grant remote access
    echo "$(date) [INFO]: Creating new user ${MYSQL_APP_USER}"
    sed -e "s/{{password}}/${MYSQL_APP_PASSWORD}/g" \
      -e "s/{{user}}/${MYSQL_APP_USER}/g" /home/user.sql | mysql -uroot -p${MYSQL_ROOT_PASSWORD};

    if [ $? -ne 0 ]; then
      echo "$(date) [ERROR]: Failed to create new user";
      exit 1
    else
      echo "$(date) [INFO]: Created user:"
      echo "$(date) [INFO]: Username: ${MYSQL_APP_USER}"
      echo "$(date) [INFO]: Password: ${MYSQL_APP_PASSWORD}"
    fi

    echo "$(date) [INFO]: Finished database setup"

    mysqladmin -uroot -p${MYSQL_ROOT_PASSWORD} shutdown

    sleep 5 # wait for mysql to shutdown

    unset "${MYSQL_ROOT_PASSWORD}"
    unset "${MYSQL_APP_USER}"
    unset "${MYSQL_APP_PASSWORD}"

    set_init_done

    # start mysql in foreground with datadir set
    exec gosu ${MYSQL_USER} /usr/bin/mysqld_safe --datadir="${MYSQL_DATA_DIR}"
  fi
}

init
