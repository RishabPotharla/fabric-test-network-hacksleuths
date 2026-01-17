#!/usr/bin/env bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script extends the Hyperledger Fabric test network by adding
# adding a fourth organization to the network
#

export PATH=${PWD}/../../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/../../config
export VERBOSE=false

. ../scripts/utils.sh

: ${CONTAINER_CLI:="docker"}
if command -v ${CONTAINER_CLI}-compose > /dev/null 2>&1; then
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI}-compose"}
else
    : ${CONTAINER_CLI_COMPOSE:="${CONTAINER_CLI} compose"}
fi
infoln "Using ${CONTAINER_CLI} and ${CONTAINER_CLI_COMPOSE}"

function printHelp () {
  echo "Usage: "
  echo "  addOrg4.sh up|down|generate [-c <channel name>] [-t <timeout>] [-d <delay>] [-s <dbtype>]"
}

# ---------------------------------------------------------------------------
# Generate crypto material for Org4
# ---------------------------------------------------------------------------
function generateOrg4() {

  if [ "$CRYPTO" == "cryptogen" ]; then
    infoln "Generating certificates using cryptogen tool"
    cryptogen generate --config=org4-crypto.yaml --output="../organizations"
    if [ $? -ne 0 ]; then
      fatalln "Failed to generate certificates for Org4"
    fi
  fi

  if [ "$CRYPTO" == "Certificate Authorities" ]; then
    infoln "Generating certificates using Fabric CA"
    ${CONTAINER_CLI_COMPOSE} -f ${COMPOSE_FILE_CA_BASE} -f ${COMPOSE_FILE_CA_ORG4} up -d
    . fabric-ca/registerEnroll.sh
    sleep 10
    createOrg4
  fi

  infoln "Generating CCP files for Org4"
  ./ccp-generate.sh
}

# ---------------------------------------------------------------------------
# Generate Org4 definition
# ---------------------------------------------------------------------------
function generateOrg4Definition() {
  infoln "Generating Org4 organization definition"
  export FABRIC_CFG_PATH=$PWD
  configtxgen -printOrg Org4MSP > ../organizations/peerOrganizations/org4.example.com/org4.json
  if [ $? -ne 0 ]; then
    fatalln "Failed to generate Org4 definition"
  fi
}

# ---------------------------------------------------------------------------
# Bring up Org4 peer
# ---------------------------------------------------------------------------
function Org4Up () {

  if [ "${DATABASE}" == "couchdb" ]; then
    DOCKER_SOCK=${DOCKER_SOCK} ${CONTAINER_CLI_COMPOSE} \
      -f ${COMPOSE_FILE_BASE} \
      -f ${COMPOSE_FILE_ORG4} \
      -f ${COMPOSE_FILE_COUCH_BASE} \
      -f ${COMPOSE_FILE_COUCH_ORG4} up -d
  else
    DOCKER_SOCK=${DOCKER_SOCK} ${CONTAINER_CLI_COMPOSE} \
      -f ${COMPOSE_FILE_BASE} \
      -f ${COMPOSE_FILE_ORG4} up -d
  fi

  if [ $? -ne 0 ]; then
    fatalln "ERROR !!!! Unable to start Org4 network"
  fi
}

# ---------------------------------------------------------------------------
# Add Org4 to channel
# ---------------------------------------------------------------------------
function addOrg4 () {

  if [ ! -d ../organizations/ordererOrganizations ]; then
    fatalln "ERROR: Please run ./network.sh up and createChannel first"
  fi

  if [ ! -d "../organizations/peerOrganizations/org4.example.com" ]; then
    generateOrg4
    generateOrg4Definition
  fi

  infoln "Bringing up Org4 peer"
  Org4Up

  infoln "Generating and submitting config tx to add Org4"
  export FABRIC_CFG_PATH=${PWD}/../../config
  . ../scripts/org4-scripts/updateChannelConfig.sh $CHANNEL_NAME $CLI_DELAY $CLI_TIMEOUT $VERBOSE

  infoln "Joining Org4 peer to channel"
  . ../scripts/org4-scripts/joinChannel.sh $CHANNEL_NAME $CLI_DELAY $CLI_TIMEOUT $VERBOSE
}

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
CRYPTO="cryptogen"
CLI_TIMEOUT=10
CLI_DELAY=3
CHANNEL_NAME="mychannel"

COMPOSE_FILE_BASE=compose/compose-org4.yaml
COMPOSE_FILE_ORG4=compose/${CONTAINER_CLI}/docker-compose-org4.yaml
COMPOSE_FILE_COUCH_BASE=compose/compose-couch-org4.yaml
COMPOSE_FILE_COUCH_ORG4=compose/${CONTAINER_CLI}/docker-compose-couch-org4.yaml
COMPOSE_FILE_CA_BASE=compose/compose-ca-org4.yaml
COMPOSE_FILE_CA_ORG4=compose/${CONTAINER_CLI}/docker-compose-ca-org4.yaml

DATABASE="leveldb"

SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
MODE=$1
shift

while [[ $# -ge 1 ]] ; do
  case "$1" in
    -c ) CHANNEL_NAME="$2"; shift ;;
    -ca ) CRYPTO="Certificate Authorities" ;;
    -t ) CLI_TIMEOUT="$2"; shift ;;
    -d ) CLI_DELAY="$2"; shift ;;
    -s ) DATABASE="$2"; shift ;;
    -verbose ) VERBOSE=true ;;
  esac
  shift
done

if [ "$MODE" == "up" ]; then
  infoln "Adding Org4 to channel '${CHANNEL_NAME}'"
  addOrg4
elif [ "$MODE" == "down" ]; then
  cd ..
  ./network.sh down
elif [ "$MODE" == "generate" ]; then
  generateOrg4
  generateOrg4Definition
else
  printHelp
fi
