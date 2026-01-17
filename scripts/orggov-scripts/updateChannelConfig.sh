#!/usr/bin/env bash

CHANNEL_NAME="$1"
DELAY="$2"
TIMEOUT="$3"
VERBOSE="$4"

: ${CHANNEL_NAME:="mychannel"}

export TEST_NETWORK_HOME="$(cd "$(dirname "$0")/../.." && pwd)"
. ${TEST_NETWORK_HOME}/scripts/configUpdate.sh

echo "Creating config tx to add OrgGov"

fetchChannelConfig 1 ${CHANNEL_NAME} ${TEST_NETWORK_HOME}/channel-artifacts/config.json

jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups":{"OrgGovMSP":.[1]}}}}}' \
  ${TEST_NETWORK_HOME}/channel-artifacts/config.json \
  ${TEST_NETWORK_HOME}/organizations/peerOrganizations/orggov.example.com/orggov.json \
  > ${TEST_NETWORK_HOME}/channel-artifacts/modified_config.json

createConfigUpdate \
  ${CHANNEL_NAME} \
  ${TEST_NETWORK_HOME}/channel-artifacts/config.json \
  ${TEST_NETWORK_HOME}/channel-artifacts/modified_config.json \
  ${TEST_NETWORK_HOME}/channel-artifacts/orggov_update_in_envelope.pb

signConfigtxAsPeerOrg 1 ${TEST_NETWORK_HOME}/channel-artifacts/orggov_update_in_envelope.pb

setGlobals 2
peer channel update \
  -f ${TEST_NETWORK_HOME}/channel-artifacts/orggov_update_in_envelope.pb \
  -c ${CHANNEL_NAME} \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile "$ORDERER_CA"

echo "OrgGov MSP added to channel"
