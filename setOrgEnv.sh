#!/usr/bin/env bash
#
# SPDX-License-Identifier: Apache-2.0
#

# default to using Org1
ORG=${1:-Org1}

# ---------------------------------------------------------------------------
# Resolve TEST NETWORK HOME (directory where this script lives)
# ---------------------------------------------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEST_NETWORK_HOME="${SCRIPT_DIR}"

# ---------------------------------------------------------------------------
# TLS + CA paths
# ---------------------------------------------------------------------------
ORDERER_CA=${TEST_NETWORK_HOME}/organizations/ordererOrganizations/example.com/tlsca/tlsca.example.com-cert.pem

PEER0_ORG1_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
PEER0_ORG2_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
PEER0_ORG3_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem
PEER0_ORG4_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org4.example.com/tlsca/tlsca.org4.example.com-cert.pem
PEER0_ORGGOV_CA=${TEST_NETWORK_HOME}/organizations/peerOrganizations/orggov.example.com/tlsca/tlsca.orggov.example.com-cert.pem

# ---------------------------------------------------------------------------
# Org-specific configuration
# ---------------------------------------------------------------------------
if [[ ${ORG,,} == "org1" || ${ORG,,} == "digibank" ]]; then

  CORE_PEER_LOCALMSPID=Org1MSP
  CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
  CORE_PEER_ADDRESS=localhost:7051
  CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_ORG1_CA}

elif [[ ${ORG,,} == "org2" || ${ORG,,} == "magnetocorp" ]]; then

  CORE_PEER_LOCALMSPID=Org2MSP
  CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
  CORE_PEER_ADDRESS=localhost:9051
  CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_ORG2_CA}

elif [[ ${ORG,,} == "org3" ]]; then

  CORE_PEER_LOCALMSPID=Org3MSP
  CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
  CORE_PEER_ADDRESS=localhost:11051
  CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_ORG3_CA}

elif [[ ${ORG,,} == "org4" ]]; then

  CORE_PEER_LOCALMSPID=Org4MSP
  CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/org4.example.com/users/Admin@org4.example.com/msp
  CORE_PEER_ADDRESS=localhost:12051
  CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_ORG4_CA}

elif [[ ${ORG,,} == "orggov" || ${ORG,,} == "government" ]]; then

  CORE_PEER_LOCALMSPID=OrgGovMSP
  CORE_PEER_MSPCONFIGPATH=${TEST_NETWORK_HOME}/organizations/peerOrganizations/orggov.example.com/users/Admin@orggov.example.com/msp
  CORE_PEER_ADDRESS=localhost:15051
  CORE_PEER_TLS_ROOTCERT_FILE=${PEER0_ORGGOV_CA}

else
  echo "Unknown organization: ${ORG}"
  echo "Valid options: org1 | org2 | org3 | org4 | orggov"
  return 1
fi

# ---------------------------------------------------------------------------
# Export variables (SAFE for sourcing)
# ---------------------------------------------------------------------------
export CORE_PEER_TLS_ENABLED=true
export ORDERER_CA

export CORE_PEER_LOCALMSPID
export CORE_PEER_MSPCONFIGPATH
export CORE_PEER_ADDRESS
export CORE_PEER_TLS_ROOTCERT_FILE

# ---------------------------------------------------------------------------
# Echo for visibility
# ---------------------------------------------------------------------------
echo "CORE_PEER_TLS_ENABLED=true"
echo "CORE_PEER_LOCALMSPID=${CORE_PEER_LOCALMSPID}"
echo "CORE_PEER_ADDRESS=${CORE_PEER_ADDRESS}"
echo "CORE_PEER_MSPCONFIGPATH=${CORE_PEER_MSPCONFIGPATH}"
echo "CORE_PEER_TLS_ROOTCERT_FILE=${CORE_PEER_TLS_ROOTCERT_FILE}"
echo "ORDERER_CA=${ORDERER_CA}"
