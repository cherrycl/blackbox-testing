#!/bin/sh

# Copyright 2017 Konrad Zapalowicz <bergo.torino@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Start EdgeX Foundry services in right order, as described:
# https://wiki.edgexfoundry.org/display/FA/Get+EdgeX+Foundry+-+Users

#if [ "${OS}" ==  "Windows_NT" ] ; then
#    echo " os =  ${OS}"
#    . $(dirname "$0")/bin/env-win10.sh
#else
#    . $(dirname "$0")/bin/env.sh
#fi

# if [ -n "${COMPOSE_FILE_PATH}" ] && [ -r "${COMPOSE_FILE_PATH}" ]; then
# 	COMPOSE_FILE=${COMPOSE_FILE_PATH}
# else
# 	./sync.sh
# 	COMPOSE_FILE=$(ls $(dirname "$0") | awk '/docker-compose/ && !/test-tools/')
# fi

if ["${COMPOSE_FILE_PATH}" = "true"]; then
	COMPOSE_FILE=${COMPOSE_FILE_PATH}
else
	./sync.sh
	COMPOSE_FILE=$(ls $(dirname "$0") | awk '/docker-compose/ && !/test-tools/')
fi

run_service () {
	echo -e "\033[0;32mStarting.. $1\033[0m"
  docker-compose -f $COMPOSE_FILE up -d $1
}

if [ "$SECURITY_SERVICE_NEEDED" = "true" ]; then
	export SECURITY_IS_ON="true"
else
	export SECURITY_IS_ON="false"
fi

run_service volume

run_service consul

if [ "$SECURITY_SERVICE_NEEDED" = "true" ]; then

	run_service security-secrets-setup

	run_service vault

	sleep 20s

	run_service vault-worker

	run_service kong-db

	sleep 10s

	run_service kong-migrations

	sleep 10s

	run_service kong

	sleep 20s

	run_service edgex-proxy
fi

# [Workaround] there is no docker-compose-nexus-redis.yml now
if [ "$SECURITY_SERVICE_NEEDED" = true ]; then
        DATABASE=mongo
fi

if [ "${DATABASE:=redis}" = redis ]; then
	run_service redis
else
	run_service mongo
fi

run_service logging

run_service data

run_service app-service-rules

run_service notifications

run_service metadata

run_service command

run_service scheduler

run_service system

run_service device-virtual
