#!/bin/bash
# @author Michael Wiesendanger <michael.wiesendanger@gmail.com>
# @description launch script for mysql

# abort when trying to use unset variable
set -o nounset

mysql_root_password="/run/secrets/com.ragedunicorn.mysql.root_password"
mysql_app_user="/run/secrets/com.ragedunicorn.mysql.app_user"
mysql_app_user_password="/run/secrets/com.ragedunicorn.mysql.app_user_password"

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

    if [ -f "${mysql_app_user}" ] && [ -f "${mysql_app_user_password}" ] && [ -f "${mysql_root_password}" ]; then
      echo "$(date) [INFO]: Found docker secrets - using secrets to setup mysql"

      mysql_root_password="$(cat ${mysql_root_password})"
      mysql_app_user="$(cat ${mysql_app_user})"
      mysql_app_user_password="$(cat ${mysql_app_user_password})"
    else
      echo "$(date) [INFO]: No docker secrets found - using environment variables"

      mysql_root_password="${MYSQL_ROOT_PASSWORD}"
      mysql_app_user="${MYSQL_APP_USER}"
      mysql_app_user_password="${MYSQL_APP_PASSWORD}"
    fi

    unset "${MYSQL_ROOT_PASSWORD}"
    unset "${MYSQL_APP_USER}"
    unset "${MYSQL_APP_PASSWORD}"

    # handle potential empty datadir. Mysql is populating the datadir while getting installed.
    # However that data is lost when the image is pulled and the container started. Because of
    # this the folder needs to be initialzed before proceeding. Note that the root password is set
    # at a later point
    if [ -z "$(ls -A ${MYSQL_DATA_DIR})" ]; then
       mysqld --initialize-insecure --datadir="${MYSQL_DATA_DIR}" --user="${MYSQL_USER}"
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
      mysql -uroot -e "status" > /dev/null 2>&1 && break
      i=$((i + 1))
    done

    # use default root password to set new root password
    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${mysql_root_password}';" | mysql -uroot

    # create new user and grant remote access
    echo "$(date) [INFO]: Creating new user ${mysql_app_user}"
    sed -e "s/{{password}}/${mysql_app_user_password}/g" \
      -e "s/{{user}}/${mysql_app_user}/g" /home/user.sql | mysql -uroot -p${mysql_root_password};

    if [ $? -ne 0 ]; then
      echo "$(date) [ERROR]: Failed to create new user";
      exit 1
    else
      echo "$(date) [INFO]: Created new app user:"
      echo "$(date) [INFO]: Username: ${mysql_app_user}"
    fi

    echo "$(date) [INFO]: Finished database setup"

    mysqladmin -uroot -p${mysql_root_password} shutdown

    sleep 5 # wait for mysql to shutdown

    set_init_done

    # start mysql in foreground with datadir set
    exec gosu ${MYSQL_USER} /usr/bin/mysqld_safe --datadir="${MYSQL_DATA_DIR}"
  fi
}

init
