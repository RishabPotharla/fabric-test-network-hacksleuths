package hacksleuths

import (
	"encoding/json"
	"fmt"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

/*
========================
QUERY: SUBMITTED
========================
*/
func (c *HackChaincode) QuerySubmitted(
	ctx contractapi.TransactionContextInterface,
) ([]*Record, error) {

	return c.queryByState(ctx, StateSubmitted)
}

/*
========================
QUERY: GOV_VERIFIED
========================
*/
func (c *HackChaincode) QueryGovVerified(
	ctx contractapi.TransactionContextInterface,
) ([]*Record, error) {

	return c.queryByState(ctx, StateGovVerified)
}

/*
========================
QUERY: OFFICIAL
========================
*/
func (c *HackChaincode) QueryOfficial(
	ctx contractapi.TransactionContextInterface,
) ([]*Record, error) {

	return c.queryByState(ctx, StateOfficial)
}

/*
========================
INTERNAL QUERY ENGINE
========================
*/
func (c *HackChaincode) queryByState(
	ctx contractapi.TransactionContextInterface,
	state string,
) ([]*Record, error) {

	query := fmt.Sprintf(`{
		"selector": {
			"state": "%s"
		}
	}`, state)

	resultsIterator, err := ctx.GetStub().GetQueryResult(query)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var results []*Record

	for resultsIterator.HasNext() {
		res, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var record Record
		if err := json.Unmarshal(res.Value, &record); err != nil {
			return nil, err
		}

		results = append(results, &record)
	}

	return results, nil
}
