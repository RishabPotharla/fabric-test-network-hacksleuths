#!/usr/bin/env bash
#
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# This script is designed to be run by addOrg4.sh as the
# second step of the Adding an Org to a Channel tutorial.
# It joins the org4 peers to the channel previously setup in
# the test network tutorial.

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
# Import environment variables
# ---------------------------------------------------------------------------
export TEST_NETWORK_HOME="${PWD}/.."
. ${TEST_NETWORK_HOME}/scripts/envVar.sh

# ---------------------------------------------------------------------------
# Join channel
# ---------------------------------------------------------------------------
joinChannel() {
  ORG=$1
  setGlobals $ORG
  local rc=1
  local COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done

  cat log.txt
  verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME'"
}

# ---------------------------------------------------------------------------
# Set anchor peer
# ---------------------------------------------------------------------------
setAnchorPeer() {
  ORG=$1
  ${TEST_NETWORK_HOME}/scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME
}

# ---------------------------------------------------------------------------
# Fetch channel block
# ---------------------------------------------------------------------------
setGlobals 4
BLOCKFILE="${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}.block"

echo "Fetching channel config block from orderer..."
set -x
peer channel fetch 0 $BLOCKFILE \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  -c $CHANNEL_NAME \
  --tls \
  --cafile "$ORDERER_CA" >&log.txt
res=$?
{ set +x; } 2>/dev/null
cat log.txt
verifyResult $res "Fetching config block from orderer has failed"

# ---------------------------------------------------------------------------
# Join org4 peer
# ---------------------------------------------------------------------------
infoln "Joining org4 peer to the channel..."
joinChannel 4

# ---------------------------------------------------------------------------
# Set anchor peer for org4
# ---------------------------------------------------------------------------
infoln "Setting anchor peer for org4..."
setAnchorPeer 4

successln "Channel '$CHANNEL_NAME' joined"
successln "Org4 peer successfully added to network"
