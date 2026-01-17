package hacksleuths

const (
	StateSubmitted   = "SUBMITTED"
	StateGovVerified = "GOV_VERIFIED"
	StateOfficial    = "OFFICIAL"
)

type Record struct {
	ID                 string   `json:"id"`
	DataHash           string   `json:"dataHash"`
	ExplanationText    string   `json:"explanationText"`
	SummaryText        string   `json:"summaryText"`
	OffshoreDiagramURL string   `json:"offshoreDiagramURL"`
	NetworkDiagramURL  string   `json:"networkDiagramURL"`

	SubmittedBy        string   `json:"submittedBy"`
	SubmittedAt        string   `json:"submittedAt"`

	State              string   `json:"state"`

	ApprovedBanks      []string `json:"approvedBanks"`
	ApprovalCount      int      `json:"approvalCount"`
	RequiredApproval   int      `json:"requiredApproval"`

	GovtReviewedBy     string   `json:"govtReviewedBy,omitempty"`
	GovtReviewedAt     string   `json:"govtReviewedAt,omitempty"`

	FinalizedAt        string   `json:"finalizedAt,omitempty"`
}
