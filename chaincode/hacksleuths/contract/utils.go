package hacksleuths

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

func now(ctx contractapi.TransactionContextInterface) string {
	ts, _ := ctx.GetStub().GetTxTimestamp()
	return time.Unix(ts.Seconds, int64(ts.Nanos)).UTC().Format(time.RFC3339)
}

func getMSP(ctx contractapi.TransactionContextInterface) (string, error) {
	return ctx.GetClientIdentity().GetMSPID()
}

func getOrgLabel(ctx contractapi.TransactionContextInterface, mspID string) string {
	bytes, _ := ctx.GetStub().GetState(OrgDirectoryKey)

	var dir OrgDirectory
	_ = json.Unmarshal(bytes, &dir)

	if label, ok := dir.Orgs[mspID]; ok {
		return label
	}
	return mspID
}

func ensureMutable(record *Record) error {
	if record.State == StateOfficial {
		return fmt.Errorf("record is OFFICIAL and immutable")
	}
	return nil
}
