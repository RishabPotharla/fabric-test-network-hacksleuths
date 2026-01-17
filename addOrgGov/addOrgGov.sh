#!/usr/bin/env bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#

# This script extends the Hyperledger Fabric test network by adding
# the government organization (OrgGov) to the network
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

# ---------------------------------------------------------------------------
# Print help
# ---------------------------------------------------------------------------
function printHelp () {
  echo "Usage: "
  echo "  addOrgGov.sh up|down|generate [-c <channel name>] [-t <timeout>] [-d <delay>] [-s <dbtype>]"
}

# ---------------------------------------------------------------------------
# Generate crypto material (cryptogen ONLY)
# ---------------------------------------------------------------------------
function generateOrgGov() {

  which cryptogen
  if [ "$?" -ne 0 ]; then
    fatalln "cryptogen tool not found. exiting"
  fi

  infoln "Generating certificates using cryptogen tool"
  infoln "Creating OrgGov identities"

  set -x
  cryptogen generate --config=orggov-crypto.yaml --output="../organizations"
  res=$?
  { set +x; } 2>/dev/null

  if [ $res -ne 0 ]; then
    fatalln "Failed to generate OrgGov certificates"
  fi

  infoln "Generating CCP files for OrgGov"
  ./ccp-generate.sh
}

# ---------------------------------------------------------------------------
# Generate OrgGov definition
# ---------------------------------------------------------------------------
function generateOrgGovDefinition() {

  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatalln "configtxgen tool not found. exiting"
  fi

  infoln "Generating OrgGov organization definition"
  export FABRIC_CFG_PATH=$PWD

  set -x
  configtxgen -printOrg OrgGovMSP > ../organizations/peerOrganizations/orggov.example.com/orggov.json
  res=$?
  { set +x; } 2>/dev/null

  if [ $res -ne 0 ]; then
    fatalln "Failed to generate OrgGov organization definition"
  fi
}

# ---------------------------------------------------------------------------
# Start OrgGov peer
# ---------------------------------------------------------------------------
function OrgGovUp () {

  if [ "${DATABASE}" == "couchdb" ]; then
    DOCKER_SOCK=${DOCKER_SOCK} ${CONTAINER_CLI_COMPOSE} \
      -f ${COMPOSE_FILE_BASE} \
      -f ${COMPOSE_FILE_ORGGOV} \
      -f ${COMPOSE_FILE_COUCH_BASE} \
      -f ${COMPOSE_FILE_COUCH_ORGGOV} up -d 2>&1
  else
    DOCKER_SOCK=${DOCKER_SOCK} ${CONTAINER_CLI_COMPOSE} \
      -f ${COMPOSE_FILE_BASE} \
      -f ${COMPOSE_FILE_ORGGOV} up -d 2>&1
  fi

  if [ $? -ne 0 ]; then
    fatalln "ERROR !!!! Unable to start OrgGov network"
  fi
}

# ---------------------------------------------------------------------------
# Add OrgGov to channel
# ---------------------------------------------------------------------------
function addOrgGov () {

  if [ ! -d ../organizations/ordererOrganizations ]; then
    fatalln "ERROR: Please run ./network.sh up and createChannel first."
  fi

  if [ ! -d "../organizations/peerOrganizations/orggov.example.com" ]; then
    generateOrgGov
    generateOrgGovDefinition
  fi

  infoln "Bringing up OrgGov peer"
  OrgGovUp

  infoln "Generating and submitting config tx to add OrgGov"
  export FABRIC_CFG_PATH=${PWD}/../../config
  . ../scripts/orggov-scripts/updateChannelConfig.sh $CHANNEL_NAME $CLI_DELAY $CLI_TIMEOUT $VERBOSE

  infoln "Joining OrgGov peer to network"
  . ../scripts/orggov-scripts/joinChannel.sh $CHANNEL_NAME $CLI_DELAY $CLI_TIMEOUT $VERBOSE
}

# ---------------------------------------------------------------------------
# Network down
# ---------------------------------------------------------------------------
function networkDown () {
  cd ..
  ./network.sh down
}

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
CRYPTO="cryptogen"
CLI_TIMEOUT=10
CLI_DELAY=3
CHANNEL_NAME="mychannel"

COMPOSE_FILE_BASE=compose/compose-orggov.yaml
COMPOSE_FILE_ORGGOV=compose/${CONTAINER_CLI}/docker-compose-orggov.yaml
COMPOSE_FILE_COUCH_BASE=compose/compose-couch-orggov.yaml
COMPOSE_FILE_COUCH_ORGGOV=compose/${CONTAINER_CLI}/docker-compose-couch-orggov.yaml

DATABASE="leveldb"

SOCK="${DOCKER_HOST:-/var/run/docker.sock}"
DOCKER_SOCK="${SOCK##unix://}"

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------
MODE=$1
shift

while [[ $# -ge 1 ]] ; do
  case "$1" in
    -c ) CHANNEL_NAME="$2"; shift ;;
    -t ) CLI_TIMEOUT="$2"; shift ;;
    -d ) CLI_DELAY="$2"; shift ;;
    -s ) DATABASE="$2"; shift ;;
    -verbose ) VERBOSE=true ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Execute
# ---------------------------------------------------------------------------
if [ "$MODE" == "up" ]; then
  infoln "Adding OrgGov to channel '${CHANNEL_NAME}'"
  addOrgGov
elif [ "$MODE" == "down" ]; then
  networkDown
elif [ "$MODE" == "generate" ]; then
  generateOrgGov
  generateOrgGovDefinition
else
  printHelp
  exit 1
fi
