FROM ubuntu:bionic

LABEL com.ragedunicorn.maintainer="Michael Wiesendanger <michael.wiesendanger@gmail.com>"

#     __  _____  _______ ____    __
#    /  |/  /\ \/ / ___// __ \  / /
#   / /|_/ /  \  /\__ \/ / / / / /
#  / /  / /   / /___/ / /_/ / / /___
# /_/  /_/   /_//____/\___\_\/_____/

# image args
ARG MYSQL_USER=mysql
ARG MYSQL_GROUP=mysql
ARG MYSQL_APP_USER=app
ARG MYSQL_APP_PASSWORD=app
ARG MYSQL_ROOT_PASSWORD=root

# software versions
ENV \
  MYSQL_MAJOR_VERSION=5.7.22-0ubuntu18.04.1 \
  WGET_VERSION=1.19.4-1ubuntu2.1 \
  CA_CERTIFICATES_VERSION=20180409 \
  DIRMNGR_VERSION=2.2.4-1ubuntu1.1 \
  GOSU_VERSION=1.10 \
  GPG_VERSION=2.2.4-1ubuntu1.1 \
  GPG_AGENT_VERSION=2.2.4-1ubuntu1.1

ENV \
  MYSQL_USER="${MYSQL_USER}" \
  MYSQL_GROUP="${MYSQL_GROUP}" \
  MYSQL_APP_USER="${MYSQL_APP_USER}" \
  MYSQL_APP_PASSWORD="${MYSQL_APP_PASSWORD}" \
  MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
  MYSQL_BASE_DIR=/var/lib/mysql \
  MYSQL_DATA_DIR=/var/lib/mysql \
  MYSQL_RUN_DIR=/var/run/mysqld \
  GOSU_GPGKEY="B42F6819007F00F88E364FD4036A9C25BF357DD4"

# explicitly set user/group IDs
RUN groupadd -g 9999 -r "${MYSQL_USER}" && useradd -u 9999 -r -g "${MYSQL_GROUP}" "${MYSQL_USER}"

RUN \
  set -ex; \
  apt-get update && apt-get install -y --no-install-recommends \
    dirmngr="${DIRMNGR_VERSION}" \
    ca-certificates="${CA_CERTIFICATES_VERSION}" \
    wget="${WGET_VERSION}" \
    gpg="${GPG_VERSION}" \
    gpg-agent="${GPG_AGENT_VERSION}" \
    mysql-server="${MYSQL_MAJOR_VERSION}" && \
  dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
  wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch" && \
  wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc" && \
  export GNUPGHOME && \
  GNUPGHOME="$(mktemp -d)" && \
  for server in \
    hkp://p80.pool.sks-keyservers.net:80 \
    hkp://keyserver.ubuntu.com:80 \
    hkp://pgp.mit.edu:80 \
  ;do \
    echo "Fetching GPG key $GOSU_GPGKEY from $server"; \
    gpg --keyserver "$server" --recv-keys "$GOSU_GPGKEY" && found=yes && break; \
  done && \
  gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu && \
  rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc && \
  chmod +x /usr/local/bin/gosu && \
  gosu nobody true && \
  apt-get purge -y --auto-remove ca-certificates wget dirmngr gpg gpg-agent && \
  rm -rf /var/lib/apt/lists/*

# add custom mysql config
COPY config/my.cnf config/mysqld_charset.cnf /etc/mysql/

# add init scripts for mysql
COPY config/user.sql /home/user.sql

# add healthcheck script
COPY docker-healthcheck.sh /

# add launch script
COPY docker-entrypoint.sh /

RUN \
  chmod 644 /etc/mysql/my.cnf && \
  chown "${MYSQL_USER}" /etc/mysql/my.cnf && \
  chmod 644 /etc/mysql/mysqld_charset.cnf && \
  chown "${MYSQL_USER}" /etc/mysql/mysqld_charset.cnf && \
  chmod 755 /docker-entrypoint.sh && \
  chmod 755 /docker-healthcheck.sh

EXPOSE 3306

VOLUME ["${MYSQL_DATA_DIR}"]

ENTRYPOINT ["/docker-entrypoint.sh"]
