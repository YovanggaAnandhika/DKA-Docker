#!/bin/sh

ROOT_PASSWORD="${DKA_ROOT_PASSWORD:-root}"

mysqladmin ping -h 127.0.0.1 -uroot -p"${ROOT_PASSWORD}" >/dev/null 2>&1 || exit 1
exit 0
