FROM ubuntu:bionic

LABEL com.ragedunicorn.maintainer="Michael Wiesendanger <michael.wiesendanger@gmail.com>"

#     __  _____  _______ ____    __
#    /  |/  /\ \/ / ___// __ \  / /
#   / /|_/ /  \  /\__ \/ / / / / /
#  / /  / /   / /___/ / /_/ / / /___
# /_/  /_/   /_//____/\___\_\/_____/

# software versions
ARG MYSQL_MAJOR_VERSION=5.7.22-0ubuntu18.04.1
ARG WGET_VERSION=1.19.4-1ubuntu2.1
ARG CA_CERTIFICATES_VERSION=20180409
ARG DIRMNGR_VERSION=2.2.4-1ubuntu1
ARG GOSU_VERSION=1.10
ARG GPG_VERSION=2.2.4-1ubuntu1
ARG GPG_AGENT_VERSION=2.2.4-1ubuntu1

ENV \
  MYSQL_USER=mysql \
  MYSQL_BASE_DIR=/var/lib/mysql \
  MYSQL_DATA_DIR=/var/lib/mysql \
  MYSQL_RUN_DIR=/var/run/mysqld \
  MYSQL_APP_USER=app \
  MYSQL_APP_PASSWORD=app \
  MYSQL_ROOT_PASSWORD=root

# explicitly set user/group IDs
RUN groupadd -r "${MYSQL_USER}" --gid=999 && useradd -r -g "${MYSQL_USER}" --uid=999 "${MYSQL_USER}"

RUN \
  set -ex; \
  apt-get update && apt-get install -y --no-install-recommends \
    dirmngr="${DIRMNGR_VERSION}" \
    ca-certificates="${CA_CERTIFICATES_VERSION}" \
    wget="${WGET_VERSION}" \
    gpg="${GPG_VERSION}" \
    gpg-agent="${GPG_AGENT_VERSION}" && \
  dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
  wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" && \
  wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" && \
  export GNUPGHOME && \
  GNUPGHOME="$(mktemp -d)" && \
  gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 && \
  gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
  rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc && \
  chmod +x /usr/local/bin/gosu && \
  gosu nobody true && \
  apt-get purge -y --auto-remove ca-certificates wget dirmngr gpg gpg-agent && \
  rm -rf /var/lib/apt/lists/*

# re-synchronize package index, install mysql and cleanup cache
RUN \
  echo "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections && \
  echo "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}" | debconf-set-selections && \
  apt-get update && apt-get install -y --no-install-recommends mysql-server="${MYSQL_MAJOR_VERSION}" && \
  rm -rf /var/lib/apt/lists/*

# add custom mysql conf
COPY conf/my.cnf conf/mysqld_charset.cnf /etc/mysql/

# add init scripts for mysql
COPY conf/user.sql /home/user.sql

# add launch script
COPY docker-entrypoint.sh /

RUN \
  chmod 644 /etc/mysql/my.cnf && \
  chown mysql /etc/mysql/my.cnf && \
  chmod 644 /etc/mysql/mysqld_charset.cnf && \
  chown mysql /etc/mysql/mysqld_charset.cnf && \
  chmod 755 docker-entrypoint.sh

EXPOSE 3306

VOLUME ["${MYSQL_DATA_DIR}"]

ENTRYPOINT ["/docker-entrypoint.sh"]
