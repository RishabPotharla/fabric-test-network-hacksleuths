package hacksleuths

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

const OrgDirectoryKey = "ORG_DIRECTORY"

type OrgDirectory struct {
	Orgs map[string]string `json:"orgs"`
}

func (c *HackChaincode) RegisterBank(
	ctx contractapi.TransactionContextInterface,
	mspID string,
	displayName string,
) error {

	callerMSP, _ := ctx.GetClientIdentity().GetMSPID()
	if callerMSP != "OrgGovMSP" {
		return fmt.Errorf("only government can register banks")
	}

	if displayName == "" {
		return fmt.Errorf("display name cannot be empty")
	}

	bytes, _ := ctx.GetStub().GetState(OrgDirectoryKey)

	dir := OrgDirectory{Orgs: map[string]string{}}
	if bytes != nil {
		_ = json.Unmarshal(bytes, &dir)
	}

	if _, exists := dir.Orgs[mspID]; exists {
		return fmt.Errorf("bank already registered")
	}

	dir.Orgs[mspID] = displayName

	updated, _ := json.Marshal(dir)
	return ctx.GetStub().PutState(OrgDirectoryKey, updated)
}
