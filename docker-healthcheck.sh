#!/bin/bash

# abort when trying to use unset variable
set -eo nounset

if mysqladmin ping -h localhost; then
	exit 0
fi

exit 1
