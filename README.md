# docker-mysql

> A docker base to build a container for MySQL based on Ubuntu

This container is intended to build a base for providing a database to an application stack.

## Version

* MySQL 5.7

### Start container

The container can be easily started with `docker-compose` command.

Note that the container itself won't be very useful by itself. The default port `3306` is only
exposed to linked containers. Meaning a connection with a client to the database is not possible with the default configuration.

```
docker-compose up -d
```

### Stop container

To stop all services from the docker-compose file

```
docker-compose down
```


#### Join a swarm

```
docker swarm init
```

#### Create secrets
```
echo "some_password" | docker secret create com.ragedunicorn.mysql.root_password -
echo "app_user" | docker secret create com.ragedunicorn.mysql.app_user -
echo "app_user_password" | docker secret create com.ragedunicorn.mysql.app_user_password -
```

#### Deploy stack
```
docker stack deploy --compose-file=docker-compose.stack.yml [stackname]
```

For a production deployment a stack should be deployed. Secrets will then be taken into account and MySQL will be setup accordingly.

## Dockery

In the dockery folder are some scripts that help out avoiding retyping long docker commands but are mostly intended for playing around with the container.

#### Build image

The build script builds an image with a defined name

```
sh dockery/dbuild.sh
```

#### Run container

Runs the built container. If the container was already run once it will `docker start` the already present container instead of using `docker run`

```
sh dockery/drun.sh
```

#### Attach container

Attaching to the container after it is running

```
sh dockery/dattach.sh
```

#### Stop container

Stopping the running container

```
sh dockery/dstop.sh
```

## Configuration

Most of the configuration can be changed with the `my.cnf` and `mysqld_charset.cnf` configuration files. Both of those files are copied into the container on buildtime. After a change to one of those files the container must be rebuilt.

#### Default user

First time starting up the container a user based on the values of `MYSQL_APP_USER` and `MYSQL_APP_PASSWORD` environmental values is created. This user is also allowed to make external connections and can be used by other services to interact with the database. To modify the setup of this user have a look into `config/user.sql`.

#### Build Args

The image allows for certain arguments being overridden by build args.

`MYSQL_USER, MYSQL_GROUP, MYSQL_APP_USER, MYSQL_APP_PASSWORD, MYSQL_ROOT_PASSWORD`

They all have a default value and don't have to be overridden. For details see the Dockerfile.

## Persistence

The container is storing data in the docker volume configured by the environment variable `${MYSQL_DATA_DIR}`.

## Healthcheck

The production and the stack image supports a simple healthcheck whether the container is healthy or not. This can be configured inside `docker-compose.yml` or `docker-compose.stack.yml`

## Test

To do basic tests of the structure of the container use the `docker-compose.test.yml` file.

`docker-compose -f docker-compose.test.yml up`

For more info see [container-test](https://github.com/RagedUnicorn/docker-container-test).

Tests can also be run by category such as command, fileExistence and metadata tests by starting single services in `docker-compose.test.yml`

```
# basic file existence tests
docker-compose -f docker-compose.test.yml up container-test
# command tests
docker-compose -f docker-compose.test.yml up container-test-command
# metadata tests
docker-compose -f docker-compose.test.yml up container-test-metadata
```

The same tests are also available for the `dev-image`

```
# basic file existence tests
docker-compose -f docker-compose.test.yml up container-dev-test
# command tests
docker-compose -f docker-compose.test.yml up container-dev-test-command
# metadata tests
docker-compose -f docker-compose.test.yml up container-dev-test-metadata
```

## Development

To debug the container and get more insight into the container use the `docker-compose-dev.yml`
configuration. This will also allow external clients to connect to the database. By default the port `3306` will be publicly exposed.

```
docker-compose -f docker-compose-dev.yml up -d
```

By default the launchscript `/docker-entrypoint.sh` will not be used to start the MySQL process. Instead the container will be setup to keep `stdin_open` open and allocating a pseudo `tty`. This allows for connecting to a shell and work on the container. MySQL itself can be started with `./docker-entrypoint.sh`.

## Links

Ubuntu packages database
- http://packages.ubuntu.com/

## License

Copyright (c) 2019 Michael Wiesendanger

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
