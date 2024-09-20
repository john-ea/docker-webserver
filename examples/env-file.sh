#!/usr/bin/env bash

set -e
set -u
set -o pipefail

SCRIPTPATH="$( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd )"
ENV_FILE="${SCRIPTPATH}/env-example"
HTTPD_CONFIG="HTTPD_SERVER="
DOCKER_FILE_CONFIG="DOCKER_FILE="
IMAGE="${1:-nginx-stable}"
DOCKER_FILE="${2:-nginx-stable.alpine}"

change_config() {
  local type="${1}"
  local value="${2}"
	local current
	local safe_current
	local safe_new

	current=$(grep -Eo "^${type}+[[:print:]]*" "${ENV_FILE}" | sed "s/.*${type}//g")
	safe_current=$(printf "%s" "$current" | sed 's/[^[:alnum:]]/\\&/g')
	safe_new=$(printf "%s" "${value}" | sed 's/[^[:alnum:]]/\\&/g')

  sed -i -e "s/\(^#*${type}${safe_current}\).*/${type}${safe_new}/" "${ENV_FILE}"
}

change_config "${HTTPD_CONFIG}" "${IMAGE}"
change_config "${DOCKER_FILE_CONFIG}" "${DOCKER_FILE}"

cd "${SCRIPTPATH}"
# shellcheck disable=SC2035,SC2045
for test_dir in $(ls -1 -d */);do
	echo "################################################################################"
	echo "${test_dir}"
	echo "################################################################################"

  cp "${SCRIPTPATH}/env-example" "${test_dir}/.env"
done
