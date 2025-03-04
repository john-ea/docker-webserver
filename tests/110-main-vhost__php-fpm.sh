#!/usr/bin/env bash

set -e
set -u
set -o pipefail

CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"

IMAGE="${1}"
TAG="${2}"
ARCH="${3}"
DOCKER_USER="${4}"


###
### Load Library
###
# shellcheck disable=SC1090,SC1091
. "${CWD}/.lib.sh"


###
### Universal ports
###
# shellcheck disable=SC2034
HOST_PORT_HTTP="8093"
# shellcheck disable=SC2034
HOST_PORT_HTTPS="8493"

###
### Universal container names
###
# shellcheck disable=SC2034
NAME_HTTPD="$( get_random_name )"
# shellcheck disable=SC2034
NAME_PHPFPM="$( get_random_name )"
# shellcheck disable=SC2034
NAME_RPROXY="$( get_random_name )"



#---------------------------------------------------------------------------------------------------
# DEFINES
#---------------------------------------------------------------------------------------------------

###
### GLOBALS
###
DOCROOT="htdocs"
MOUNT_CONT="/var/www/default"
MOUNT_HOST="$( tmp_dir )"



#---------------------------------------------------------------------------------------------------
# APPS
#---------------------------------------------------------------------------------------------------

###
### Application 1
###
APP1_URL="http://localhost:${HOST_PORT_HTTP}"
APP1_EXT="php"
APP1_HDR=""
APP1_TXT="hello via httpd with ${APP1_EXT}"
create_app "${MOUNT_HOST}" "${DOCROOT}" "" "index.${APP1_EXT}" "<?php echo '${APP1_TXT}';"



#---------------------------------------------------------------------------------------------------
# START
#---------------------------------------------------------------------------------------------------

###
### Start PHP Container
###
run "docker run -d --platform ${ARCH} --name ${NAME_PHPFPM} \
-v ${MOUNT_HOST}:${MOUNT_CONT} \
${DOCKER_USER}/php-fpm:8.3-base >/dev/null"


###
### Start HTTPD Container
###
run "docker run -d --platform ${ARCH} --name ${NAME_HTTPD} \
-v ${MOUNT_HOST}:${MOUNT_CONT} \
-p 127.0.0.1:${HOST_PORT_HTTP}:80 \
-p 127.0.0.1:${HOST_PORT_HTTPS}:443 \
-e DEBUG_ENTRYPOINT=3 \
-e DEBUG_RUNTIME=2 \
-e MAIN_VHOST_BACKEND=conf:phpfpm:tcp:${NAME_PHPFPM}:9000 \
--link ${NAME_PHPFPM} \
${IMAGE}:${TAG} >/dev/null"



#---------------------------------------------------------------------------------------------------
# TESTS
#---------------------------------------------------------------------------------------------------

###
### Test: APP1
###
if ! test_vhost_response "${APP1_TXT}" "${APP1_URL}" "${APP1_HDR}"; then
	docker_logs "${NAME_PHPFPM}"
	docker_logs "${NAME_HTTPD}"
	docker_stop "${NAME_PHPFPM}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "'${APP1_TXT}' not found in ${APP1_URL}"
	exit 1
fi



#---------------------------------------------------------------------------------------------------
# GENERIC
#---------------------------------------------------------------------------------------------------

###
### Test: Errors
###
if ! test_docker_logs_err "${NAME_HTTPD}"; then
	docker_logs "${NAME_PHPFPM}"
	docker_logs "${NAME_HTTPD}"
	docker_stop "${NAME_PHPFPM}"
	docker_stop "${NAME_HTTPD}"
	log "fail" "Found errors in docker logs"
	exit 1
fi


###
### Cleanup
###
docker_stop "${NAME_PHPFPM}"
docker_stop "${NAME_HTTPD}"
log "ok" "Test succeeded"
