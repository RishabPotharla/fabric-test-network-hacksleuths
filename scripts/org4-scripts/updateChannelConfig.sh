#!/usr/bin/env bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is designed to be run by addOrg4.sh as the
# first step of the Adding an Org to a Channel tutorial.
# It creates and submits a configuration transaction to
# add org4 to the test network

CHANNEL_NAME="$1"
DELAY="$2"
TIMEOUT="$3"
VERBOSE="$4"

: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}

COUNTER=1
MAX_RETRY=5

# ---------------------------------------------------------------------------
# Imports
# ---------------------------------------------------------------------------
export TEST_NETWORK_HOME="${PWD}/.."
. ${TEST_NETWORK_HOME}/scripts/configUpdate.sh 

infoln "Creating config transaction to add org4 to network"

# ---------------------------------------------------------------------------
# Fetch the current channel configuration
# ---------------------------------------------------------------------------
fetchChannelConfig 1 ${CHANNEL_NAME} ${TEST_NETWORK_HOME}/channel-artifacts/config.json

# ---------------------------------------------------------------------------
# Modify the configuration to append Org4
# ---------------------------------------------------------------------------
set -x
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org4MSP":.[1]}}}}}' \
  ${TEST_NETWORK_HOME}/channel-artifacts/config.json \
  ${TEST_NETWORK_HOME}/organizations/peerOrganizations/org4.example.com/org4.json \
  > ${TEST_NETWORK_HOME}/channel-artifacts/modified_config.json
{ set +x; } 2>/dev/null

# ---------------------------------------------------------------------------
# Compute the config update transaction
# ---------------------------------------------------------------------------
createConfigUpdate \
  ${CHANNEL_NAME} \
  ${TEST_NETWORK_HOME}/channel-artifacts/config.json \
  ${TEST_NETWORK_HOME}/channel-artifacts/modified_config.json \
  ${TEST_NETWORK_HOME}/channel-artifacts/org4_update_in_envelope.pb

infoln "Signing config transaction"
signConfigtxAsPeerOrg 1 ${TEST_NETWORK_HOME}/channel-artifacts/org4_update_in_envelope.pb

infoln "Submitting transaction from a different peer (peer0.org2) which also signs it"
setGlobals 2
set -x
peer channel update \
  -f ${TEST_NETWORK_HOME}/channel-artifacts/org4_update_in_envelope.pb \
  -c ${CHANNEL_NAME} \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  --tls \
  --cafile "$ORDERER_CA"
{ set +x; } 2>/dev/null

successln "Config transaction to add org4 to network submitted"
