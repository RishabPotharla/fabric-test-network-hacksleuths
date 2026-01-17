#!/usr/bin/env bash

CHANNEL_NAME="$1"
DELAY="$2"
TIMEOUT="$3"
VERBOSE="$4"

: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}

MAX_RETRY=5
export TEST_NETWORK_HOME="$(cd "$(dirname "$0")/../.." && pwd)"
. ${TEST_NETWORK_HOME}/scripts/envVar.sh

joinChannel() {
  ORG=$1
  setGlobals $ORG
  rc=1
  COUNTER=1

  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    rc=$res
    COUNTER=$(expr $COUNTER + 1)
  done

  cat log.txt
  verifyResult $res "peer0.org${ORG} failed to join channel"
}

setAnchorPeer() {
  ORG=$1
  ${TEST_NETWORK_HOME}/scripts/setAnchorPeer.sh $ORG $CHANNEL_NAME
}

# OrgGov index = 5
setGlobals 5
BLOCKFILE="${TEST_NETWORK_HOME}/channel-artifacts/${CHANNEL_NAME}.block"

peer channel fetch 0 $BLOCKFILE \
  -o localhost:7050 \
  --ordererTLSHostnameOverride orderer.example.com \
  -c $CHANNEL_NAME \
  --tls \
  --cafile "$ORDERER_CA"

joinChannel 5
setAnchorPeer 5

echo "OrgGov joined channel $CHANNEL_NAME"
