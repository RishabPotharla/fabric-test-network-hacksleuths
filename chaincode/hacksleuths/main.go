package main

import (
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	cc "hacksleuths/contract"
)

func main() {
	chaincode, err := contractapi.NewChaincode(&cc.HackChaincode{})
	if err != nil {
		log.Panicf("Error creating chaincode: %v", err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panicf("Error starting chaincode: %v", err)
	}
}
