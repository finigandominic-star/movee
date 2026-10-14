class Transaction < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :involved_party, optional: true
  belongs_to :chain
  belongs_to :property

  # The 8 statutory/procedural stages of UK residential property conveyancing post-offer acceptance
  LEGAL_STAGES = %w[
    offer_accepted
    solicitors_instructed
    draft_contract_pack
    searches_and_enquiries
    survey_and_mortgage
    enquiries_resolved
    exchange_of_contracts
    completion
  ].freeze

  LEGAL_STAGE_DEFINITIONS = {
    "offer_accepted" => {
      index: 1,
      name: "Offer Accepted & Sales Memo",
      short_name: "Offer Accepted",
      lead_actor: "Estate Agent",
      icon: "fa-handshake",
      badge_class: "bg-info text-dark",
      status_pill_class: "text-info border-info-subtle bg-info-subtle",
      timeline: "Day 1 - 3",
      summary: "Offer agreed Subject to Contract (SSTC). Memorandum of Sale issued to buyer, vendor, and both solicitors.",
      tooltip: "The sale is agreed Subject to Contract (SSTC). The estate agent drafts and issues the Memorandum of Sale setting out the agreed price, parties, special conditions, and conveyancer details. Not yet legally binding.",
      legal_context: "In England and Wales, residential property sales remain non-binding until exchange of contracts. Either party can withdraw or renegotiate at this stage without legal liability. The sales memo formally triggers conveyancing.",
      agent_action: "Confirm buyer's mortgage Agreement in Principle (AIP), verify proof of deposit funds, verify both parties' solicitor details, and issue the Memorandum of Sale."
    },
    "solicitors_instructed" => {
      index: 2,
      name: "Solicitors Instructed & AML Checks",
      short_name: "Solicitors Instructed",
      lead_actor: "Buyer & Seller Solicitors",
      icon: "fa-scale-balanced",
      badge_class: "bg-primary text-white",
      status_pill_class: "text-primary border-primary-subtle bg-primary-subtle",
      timeline: "Week 1 - 2",
      summary: "Both parties formally instruct legal representatives. AML/KYC identity checks and money on account submitted.",
      tooltip: "Solicitors cannot start legal work until signed client care letters, Anti-Money Laundering (AML) identity validation, and upfront disbursement funds for search fees are received.",
      legal_context: "Regulated conveyancers are bound by statutory Anti-Money Laundering Regulations and the SRA/CLC rules. Proof of identity and source of wealth/funds must be strictly verified before opening the file.",
      agent_action: "Chase buyer and seller to return signed client care forms, provide ID/passport copies, and pay £300-£500 search disbursement funds promptly."
    },
    "draft_contract_pack" => {
      index: 3,
      name: "Draft Contract Pack Issued",
      short_name: "Draft Contracts",
      lead_actor: "Seller's Solicitor",
      icon: "fa-file-signature",
      badge_class: "bg-primary text-white",
      status_pill_class: "text-primary border-primary-subtle bg-primary-subtle",
      timeline: "Week 2 - 3",
      summary: "Seller's solicitor prepares title deeds, TA6 property info, TA10 fittings forms, and issues draft contract.",
      tooltip: "The seller's solicitor obtains Land Registry official copies and has the vendor complete Law Society forms: TA6 (Property Info) and TA10 (Fittings & Contents). For flats, TA7 and the LPE1 management pack are also required.",
      legal_context: "Under the Law Society Conveyancing Protocol, the seller's conveyancer draws up the contract using official Land Registry title entries and plans. Any un-disclosed restrictions or defects here can stall the whole chain.",
      agent_action: "Ensure the vendor completes TA6 and TA10 questionnaires diligently. If the property is leasehold, urge immediate ordering of the Management Information Pack (LPE1)."
    },
    "searches_and_enquiries" => {
      index: 4,
      name: "Searches Ordered & Enquiries Raised",
      short_name: "Searches & Enquiries",
      lead_actor: "Buyer's Solicitor & Authorities",
      icon: "fa-magnifying-glass-chart",
      badge_class: "bg-warning text-dark",
      status_pill_class: "text-warning-emphasis border-warning-subtle bg-warning-subtle",
      timeline: "Week 3 - 6",
      summary: "Statutory searches (Local Authority, Drainage, Environmental) submitted and pre-contract enquiries raised.",
      tooltip: "Buyer's solicitor orders conveyancing searches (LLC1/CON29 local council, water/drainage, environmental) and raises specific legal enquiries regarding planning permissions, building regs, and boundaries.",
      legal_context: "Caveat emptor ('buyer beware') applies in UK property law. The buyer's solicitor must investigate all risks, rights of access, planning history, and covenants before advising the client or mortgage lender to proceed.",
      agent_action: "Track search turnaround times with local councils. Help the seller locate missing documents (e.g. FENSA window certificates, Gas Safety, electrical certificates, planning permissions)."
    },
    "survey_and_mortgage" => {
      index: 5,
      name: "Survey & Mortgage Offer",
      short_name: "Survey & Mortgage",
      lead_actor: "Mortgage Lender & RICS Surveyor",
      icon: "fa-landmark",
      badge_class: "bg-warning text-dark",
      status_pill_class: "text-warning-emphasis border-warning-subtle bg-warning-subtle",
      timeline: "Week 4 - 7",
      summary: "RICS survey performed and formal binding Mortgage Offer issued by the lender.",
      tooltip: "The lender completes property valuation and formal underwriting to release the Mortgage Offer. The buyer arranges an independent RICS Home Survey (Level 2 or 3) to uncover structural defects.",
      legal_context: "A mortgage offer is required by the buyer's conveyancer before exchange, ensuring funds will be drawn down for completion. If the valuation comes in low, renegotiations or structural retentions must be resolved.",
      agent_action: "Coordinate surveyor and valuer access to the property. Liaise with the mortgage broker on valuation turnaround and offer dispatch."
    },
    "enquiries_resolved" => {
      index: 6,
      name: "Enquiries Resolved & Contracts Signed",
      short_name: "Contracts Signed",
      lead_actor: "Buyer & Seller with Solicitors",
      icon: "fa-pen-to-square",
      badge_class: "bg-info text-dark",
      status_pill_class: "text-info border-info-subtle bg-info-subtle",
      timeline: "Week 8 - 10",
      summary: "All enquiries answered, Report on Title sent, contracts and TR1 signed, and 10% deposit lodged.",
      tooltip: "All legal enquiries are satisfied. The buyer receives their Report on Title. Both parties sign contracts and TR1 transfer deeds in counterpart. The buyer sends cleared deposit funds (usually 10%) to their solicitor.",
      legal_context: "Before exchange, solicitors must obtain formal, unequivocal written authority from clients, hold signed identical contracts, and hold cleared deposit funds in their client account.",
      agent_action: "Verify all parties in the chain are in funds with signed contracts. Coordinate and align a mutually acceptable completion date across all agents and parties in the chain."
    },
    "exchange_of_contracts" => {
      index: 7,
      name: "Exchange of Contracts (Legally Binding)",
      short_name: "Exchange of Contracts",
      lead_actor: "Solicitors (Both Sides)",
      icon: "fa-file-shield",
      badge_class: "bg-success text-white",
      status_pill_class: "text-success border-success-subtle bg-success-subtle",
      timeline: "Week 10 - 12",
      summary: "Contracts formally exchanged by telephone (Law Society Formula). Deal is legally binding and completion date is fixed.",
      tooltip: "The pivotal milestone in UK conveyancing! Solicitors exchange contracts by phone. The contract is now legally binding: neither party can back out without severe financial penalty. Deposit is locked in.",
      legal_context: "Under the Law Society Formula (typically Formula B), solicitors effect legal exchange on a recorded telephone call. Once complete, the vendor is bound to sell and the purchaser is bound to buy on the agreed completion date.",
      agent_action: "Congratulate both parties! Reconfirm the fixed completion date, remind buyer to place buildings insurance on risk immediately, and arrange key handover logistics for completion day."
    },
    "completion" => {
      index: 8,
      name: "Completion & Keys Released",
      short_name: "Completion",
      lead_actor: "Estate Agent & Solicitors",
      icon: "fa-key",
      badge_class: "bg-success text-white",
      status_pill_class: "text-success border-success-subtle bg-success-subtle",
      timeline: "Completion Day",
      summary: "Purchase funds transferred, mortgages redeemed, ownership legally transferred, and keys handed over.",
      tooltip: "Completion Day! Final balance of purchase funds is wired via CHAPS. Once seller's solicitor confirms receipt of funds, they contact the estate agent with formal authority to release the keys.",
      legal_context: "Legal title passes when purchase money is received by the seller's solicitor. The buyer's solicitor subsequently lodges the TR1 transfer deed and mortgage charge with HM Land Registry and pays Stamp Duty (SDLT).",
      agent_action: "Wait for verbal/written release authority from the seller's solicitor before handing over keys. Take final utility meter readings and present keys to the buyer."
    }
  }.freeze

  validates :legal_stage, inclusion: { in: LEGAL_STAGES }

  before_validation :sync_completion_and_stage

  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: [false, nil]) }
  scope :by_legal_stage, ->(stage) { where(legal_stage: stage) }

  def creator_or_listing_user
    user || property&.user
  end

  def status_label
    completed? ? "Completed" : "In Progress"
  end

  def status_badge_class
    completed? ? "bg-success" : "bg-warning text-dark"
  end

  # Legal stage helper methods
  def legal_stage_definition
    LEGAL_STAGE_DEFINITIONS[legal_stage] || LEGAL_STAGE_DEFINITIONS["offer_accepted"]
  end

  def legal_stage_index
    legal_stage_definition[:index]
  end

  def legal_stage_title
    legal_stage_definition[:name]
  end

  def legal_stage_short_title
    legal_stage_definition[:short_name]
  end

  def legal_stage_badge_class
    legal_stage_definition[:badge_class]
  end

  def legal_stage_completed?(stage_key)
    target_idx = LEGAL_STAGE_DEFINITIONS.dig(stage_key.to_s, :index) || 0
    legal_stage_index >= target_idx
  end

  def legal_stage_current?(stage_key)
    legal_stage == stage_key.to_s
  end

  def legal_stage_percentage
    ((legal_stage_index / LEGAL_STAGES.size.to_f) * 100).round
  end

  def next_legal_stage
    curr_idx = LEGAL_STAGES.index(legal_stage) || 0
    LEGAL_STAGES[curr_idx + 1]
  end

  def previous_legal_stage
    curr_idx = LEGAL_STAGES.index(legal_stage) || 0
    curr_idx.positive? ? LEGAL_STAGES[curr_idx - 1] : nil
  end

  def advance_stage!
    if (nxt = next_legal_stage)
      update!(legal_stage: nxt)
    end
  end

  def rollback_stage!
    if (prev = previous_legal_stage)
      update!(legal_stage: prev)
    end
  end

  private

  def sync_completion_and_stage
    self.legal_stage ||= "offer_accepted"

    if new_record?
      if completed? && legal_stage == "offer_accepted"
        self.legal_stage = "completion"
      elsif legal_stage == "completion"
        self.completed = true
      end
    else
      if will_save_change_to_completed? && completed? && legal_stage != "completion"
        self.legal_stage = "completion"
      elsif will_save_change_to_legal_stage?
        if legal_stage == "completion"
          self.completed = true
        elsif completed?
          self.completed = false
        end
      end
    end
  end
end
