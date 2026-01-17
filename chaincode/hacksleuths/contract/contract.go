package hacksleuths

import (
	"encoding/json"
	"fmt"
	"math"

	"github.com/hyperledger/fabric-chaincode-go/pkg/statebased"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type HackChaincode struct {
	contractapi.Contract
}

/*
========================
SUBMIT RECORD
========================
- Called by any bank
- Only submitting bank endorsement (via SBE)
- Moves state to SUBMITTED
*/
func (c *HackChaincode) SubmitRecord(
	ctx contractapi.TransactionContextInterface,
	id string,
	dataHash string,
	explanation string,
	summary string,
	offshoreURL string,
	networkURL string,
) error {

	msp, _ := getMSP(ctx)

	// Prevent overwrite
	existing, _ := ctx.GetStub().GetState(id)
	if existing != nil {
		return fmt.Errorf("record already exists")
	}

	submitterLabel := getOrgLabel(ctx, msp)

	record := Record{
		ID:                 id,
		DataHash:           dataHash,
		ExplanationText:    explanation,
		SummaryText:        summary,
		OffshoreDiagramURL: offshoreURL,
		NetworkDiagramURL:  networkURL,

		SubmittedBy: submitterLabel,
		SubmittedAt: now(ctx),

		State: StateSubmitted,

		ApprovedBanks:    []string{},
		ApprovalCount:    0,
		RequiredApproval: 0,
	}

	bytes, _ := json.Marshal(record)
	if err := ctx.GetStub().PutState(id, bytes); err != nil {
		return err
	}

	// 🔐 SBE: only submitting bank endorses submission
	sbe, err := statebased.NewStateEP(nil)
	if err != nil {
		return err
	}
	sbe.AddOrgs(statebased.RoleTypePeer, msp)
	policy, err := sbe.Policy()
	if err != nil {
		return err
	}

	return ctx.GetStub().SetStateValidationParameter(id, policy)
}

/*
========================
GOVERNMENT VERIFICATION
========================
- Only government can call
- Moves SUBMITTED → GOV_VERIFIED
*/
func (c *HackChaincode) GovVerifyRecord(
	ctx contractapi.TransactionContextInterface,
	id string,
) error {

	msp, _ := getMSP(ctx)
	if msp != "OrgGovMSP" {
		return fmt.Errorf("only government can verify records")
	}

	bytes, err := ctx.GetStub().GetState(id)
	if err != nil || bytes == nil {
		return fmt.Errorf("record not found")
	}

	var record Record
	_ = json.Unmarshal(bytes, &record)

	if err := ensureMutable(&record); err != nil {
		return err
	}

	if record.State != StateSubmitted {
		return fmt.Errorf("record not in SUBMITTED state")
	}

	record.State = StateGovVerified
	record.GovtReviewedBy = getOrgLabel(ctx, msp)
	record.GovtReviewedAt = now(ctx)

	updated, _ := json.Marshal(record)
	if err := ctx.GetStub().PutState(id, updated); err != nil {
		return err
	}

	// 🔐 SBE: only government endorsement required
	sbe, err := statebased.NewStateEP(nil)
	if err != nil {
		return err
	}
	sbe.AddOrgs(statebased.RoleTypePeer, "OrgGovMSP")
	policy, err := sbe.Policy()
	if err != nil {
		return err
	}

	return ctx.GetStub().SetStateValidationParameter(id, policy)
}

/*
========================
BANK VOTE (51%)
========================
- Only after GOV_VERIFIED
- Excludes submitter & government
- When threshold reached → OFFICIAL
*/
func (c *HackChaincode) VoteRecord(
	ctx contractapi.TransactionContextInterface,
	id string,
) error {

	voterMSP, _ := getMSP(ctx)
	voterLabel := getOrgLabel(ctx, voterMSP)

	bytes, err := ctx.GetStub().GetState(id)
	if err != nil || bytes == nil {
		return fmt.Errorf("record not found")
	}

	var record Record
	_ = json.Unmarshal(bytes, &record)

	if err := ensureMutable(&record); err != nil {
		return err
	}

	if record.State != StateGovVerified {
		return fmt.Errorf("record not ready for voting")
	}

	// Exclude submitter & government
	if voterLabel == record.SubmittedBy || voterMSP == "OrgGovMSP" {
		return fmt.Errorf("this organization is not eligible to vote")
	}

	// Prevent double vote
	for _, b := range record.ApprovedBanks {
		if b == voterLabel {
			return fmt.Errorf("bank already voted")
		}
	}

	record.ApprovedBanks = append(record.ApprovedBanks, voterLabel)
	record.ApprovalCount = len(record.ApprovedBanks)

	// Compute required approval ONCE
	if record.RequiredApproval == 0 {
		activeBanks := c.countEligibleBanks(ctx, record.SubmittedBy)
		record.RequiredApproval = int(math.Ceil(float64(activeBanks) * 0.51))
	}

	// Finalize if threshold reached
	if record.ApprovalCount >= record.RequiredApproval {
		record.State = StateOfficial
		record.FinalizedAt = now(ctx)

		// 🔐 FINAL SBE: approving banks only
		sbe, err := statebased.NewStateEP(nil)
		if err != nil {
			return err
		}

		for _, bank := range record.ApprovedBanks {
			for mspID, label := range c.getOrgDirectory(ctx) {
				if label == bank {
					sbe.AddOrgs(statebased.RoleTypePeer, mspID)
				}
			}
		}

		policy, err := sbe.Policy()
		if err != nil {
			return err
		}
		if err := ctx.GetStub().SetStateValidationParameter(id, policy); err != nil {
			return err
		}
	}

	updated, _ := json.Marshal(record)
	return ctx.GetStub().PutState(id, updated)
}

/*
========================
HELPERS (INTERNAL)
========================
*/

func (c *HackChaincode) getOrgDirectory(
	ctx contractapi.TransactionContextInterface,
) map[string]string {

	bytes, _ := ctx.GetStub().GetState(OrgDirectoryKey)
	dir := OrgDirectory{}
	_ = json.Unmarshal(bytes, &dir)
	return dir.Orgs
}

func (c *HackChaincode) countEligibleBanks(
	ctx contractapi.TransactionContextInterface,
	submitter string,
) int {

	count := 0
	for msp, label := range c.getOrgDirectory(ctx) {
		if msp != "OrgGovMSP" && label != submitter {
			count++
		}
	}
	return count
}
