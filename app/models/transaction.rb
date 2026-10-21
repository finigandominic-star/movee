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

  # Standard day offsets from commencement (12-week / 84-day benchmark for England & Wales conveyancing)
  STAGE_DEFAULT_OFFSETS = {
    "offer_accepted"        => 3,
    "solicitors_instructed" => 14,
    "draft_contract_pack"   => 21,
    "searches_and_enquiries"=> 42,
    "survey_and_mortgage"   => 56,
    "enquiries_resolved"    => 70,
    "exchange_of_contracts" => 77,
    "completion"            => 84
  }.freeze

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
      default_days: 3,
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
      default_days: 14,
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
      default_days: 21,
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
      default_days: 42,
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
      default_days: 56,
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
      default_days: 70,
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
      default_days: 77,
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
      default_days: 84,
      summary: "Purchase funds transferred, mortgages redeemed, ownership legally transferred, and keys handed over.",
      tooltip: "Completion Day! Final balance of purchase funds is wired via CHAPS. Once seller's solicitor confirms receipt of funds, they contact the estate agent with formal authority to release the keys.",
      legal_context: "Legal title passes when purchase money is received by the seller's solicitor. The buyer's solicitor subsequently lodges the TR1 transfer deed and mortgage charge with HM Land Registry and pays Stamp Duty (SDLT).",
      agent_action: "Wait for verbal/written release authority from the seller's solicitor before handing over keys. Take final utility meter readings and present keys to the buyer."
    }
  }.freeze

  validates :legal_stage, inclusion: { in: LEGAL_STAGES }

  before_validation :ensure_chain, on: :create
  before_validation :sync_completion_and_stage
  before_validation :initialize_stage_and_completion_dates

  after_save :handle_chain_reassignment, if: :saved_change_to_chain_id?
  after_save :sync_chain_status
  after_create :auto_merge_chains_sharing_property
  after_destroy :cleanup_empty_chain_and_sync
  after_save :refresh_property_sold_status
  after_destroy :refresh_property_sold_status

  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: [false, nil]) }
  scope :by_legal_stage, ->(stage) { where(legal_stage: stage) }

  scope :search, ->(query) {
    return all if query.blank?

    q = "%#{sanitize_sql_like(query)}%"
    left_joins(:property, :involved_party, :chain)
      .where("properties.house_number ILIKE :q OR properties.street ILIKE :q OR properties.city ILIKE :q OR properties.post_code ILIKE :q
              OR involved_parties.first_name ILIKE :q OR involved_parties.last_name ILIKE :q
              OR chains.name ILIKE :q OR transactions.legal_stage ILIKE :q", q: q)
      .distinct
  }

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

  # Timeline & Target Estimation Methods
  def transaction_start_date
    (created_at || Date.current).to_date
  end

  # Calculates or returns the estimated completion date for any stage.
  # The estimation is based on the target completion date or standard timeline from creation.
  def stage_estimated_date(stage_key)
    stage_key = stage_key.to_s
    if stage_dates.is_a?(Hash) && stage_dates.dig(stage_key, "estimated_date").present?
      Date.parse(stage_dates[stage_key]["estimated_date"])
    else
      start = transaction_start_date
      target_comp = estimated_completion_date || (start + 84.days)
      span = [target_comp - start, 7].max.to_f
      offset_ratio = (STAGE_DEFAULT_OFFSETS[stage_key] || 84) / 84.0
      start + (offset_ratio * span).round.days
    end
  end

  def stage_actual_date(stage_key)
    stage_key = stage_key.to_s
    if stage_dates.is_a?(Hash) && stage_dates.dig(stage_key, "actual_date").present?
      Date.parse(stage_dates[stage_key]["actual_date"])
    elsif stage_key == "completion" && actual_completion_date.present?
      actual_completion_date
    end
  end

  # Returns detailed timing metrics comparing estimated vs actual completion dates
  def stage_timing(stage_key)
    stage_key = stage_key.to_s
    est = stage_estimated_date(stage_key)
    act = stage_actual_date(stage_key)
    is_done = legal_stage_completed?(stage_key) || act.present?
    is_curr = legal_stage_current?(stage_key)

    if act.present?
      diff = (act - est).to_i
      if diff < 0
        {
          status: :ahead,
          label: "#{diff.abs}d ahead",
          full_label: "#{diff.abs} days ahead of target",
          badge_class: "bg-success-subtle text-success border border-success-subtle",
          text_class: "text-success",
          estimated_date: est,
          actual_date: act,
          days_diff: diff,
          days: diff.abs,
          days_over: 0
        }
      elsif diff == 0
        {
          status: :on_target,
          label: "On target",
          full_label: "Completed on target date",
          badge_class: "bg-success-subtle text-success border border-success-subtle",
          text_class: "text-success",
          estimated_date: est,
          actual_date: act,
          days_diff: 0,
          days: 0,
          days_over: 0
        }
      else
        {
          status: :behind,
          label: "+#{diff}d behind",
          full_label: "#{diff} days behind target",
          badge_class: "bg-danger-subtle text-danger border border-danger-subtle",
          text_class: "text-danger",
          estimated_date: est,
          actual_date: act,
          days_diff: diff,
          days: diff,
          days_over: diff
        }
      end
    elsif is_curr
      diff = (Date.current - est).to_i
      if diff > 0
        {
          status: :overdue,
          label: "+#{diff}d overdue",
          full_label: "Behind target (overdue by #{diff} days)",
          badge_class: "bg-danger-subtle text-danger border border-danger-subtle",
          text_class: "text-danger",
          estimated_date: est,
          actual_date: nil,
          days_diff: diff,
          days: diff,
          days_over: diff
        }
      elsif diff == 0
        {
          status: :due_today,
          label: "Due today",
          full_label: "Target deadline is today",
          badge_class: "bg-warning-subtle text-warning-emphasis border border-warning-subtle",
          text_class: "text-warning",
          estimated_date: est,
          actual_date: nil,
          days_diff: 0,
          days: 0,
          days_over: 0
        }
      else
        days_left = diff.abs
        {
          status: :on_track,
          label: "#{days_left}d left",
          full_label: "On track (#{days_left} days remaining)",
          badge_class: "bg-primary-subtle text-primary border border-primary-subtle",
          text_class: "text-primary",
          estimated_date: est,
          actual_date: nil,
          days_diff: diff,
          days: days_left,
          days_over: 0
        }
      end
    else
      {
        status: :pending,
        label: "Est: #{est&.strftime('%d %b')}",
        full_label: "Target: #{est&.strftime('%d %B %Y')}",
        badge_class: "bg-light text-secondary border",
        text_class: "text-secondary",
        estimated_date: est,
        actual_date: nil,
        days_diff: nil,
        days: 0,
        days_over: 0
      }
    end
  end

  def overall_timing_status
    est = estimated_completion_date || stage_estimated_date("completion")
    if completed?
      act = actual_completion_date || stage_actual_date("completion") || updated_at.to_date
      diff = (act - est).to_i
      if diff < 0
        {
          status: :completed_ahead,
          label: "Completed #{diff.abs}d ahead of target",
          full_label: "Completed #{diff.abs} days ahead of target",
          badge_class: "bg-success text-white",
          days_diff: diff,
          days: diff.abs,
          days_over: 0
        }
      elsif diff == 0
        {
          status: :completed,
          label: "Completed on target",
          full_label: "Completed on target date",
          badge_class: "bg-success text-white",
          days_diff: 0,
          days: 0,
          days_over: 0
        }
      else
        {
          status: :completed_behind,
          label: "Completed #{diff}d behind target",
          full_label: "Completed #{diff} days behind target",
          badge_class: "bg-secondary text-white",
          days_diff: diff,
          days: diff,
          days_over: diff
        }
      end
    else
      curr_timing = stage_timing(legal_stage)
      est_stage = stage_estimated_date(legal_stage)
      stage_days_over = (curr_timing[:days_over] || (Date.current > est_stage ? (Date.current - est_stage).to_i : 0)).to_i
      overall_days_over = (est.present? && Date.current > est) ? (Date.current - est).to_i : 0
      days = [stage_days_over, overall_days_over].max.to_i

      if curr_timing[:status] == :overdue || days > 0 || (est.present? && Date.current > est)
        days = 1 if days < 1
        {
          status: :behind,
          label: "Behind Target (+#{days}d)",
          full_label: "Behind target (overdue by #{days} #{'day'.pluralize(days)})",
          badge_class: "bg-danger text-white",
          days_diff: days,
          days: days,
          days_over: days
        }
      elsif curr_timing[:status] == :ahead
        ahead_days = curr_timing[:days].to_i
        ahead_days = 1 if ahead_days < 1
        {
          status: :ahead,
          label: "Ahead of Target (#{ahead_days}d)",
          full_label: "Ahead of target by #{ahead_days} #{'day'.pluralize(ahead_days)}",
          badge_class: "bg-success text-white",
          days_diff: -ahead_days,
          days: ahead_days,
          days_over: 0
        }
      else
        {
          status: :on_track,
          label: "On Course",
          full_label: "On course towards target completion",
          badge_class: "bg-success-subtle text-success border border-success-subtle",
          days_diff: 0,
          days: 0,
          days_over: 0
        }
      end
    end
  end

  # Updates stage and automatically records approval dates for completed stages
  def set_legal_stage_with_timing!(new_stage, approval_date = Date.current)
    new_idx = LEGAL_STAGE_DEFINITIONS.dig(new_stage.to_s, :index) || 1
    curr_idx = legal_stage_index

    self.stage_dates ||= {}

    # If moving forward, record actual approval dates for preceding stages if not already recorded
    if new_idx > curr_idx
      LEGAL_STAGES.each do |stg|
        s_idx = LEGAL_STAGE_DEFINITIONS[stg][:index]
        if s_idx < new_idx && stage_actual_date(stg).nil?
          self.stage_dates[stg] ||= {}
          self.stage_dates[stg]["estimated_date"] ||= stage_estimated_date(stg).to_s
          self.stage_dates[stg]["actual_date"] = approval_date.to_s
        end
      end
    end

    self.legal_stage = new_stage
    if new_stage == "completion"
      self.completed = true
      self.actual_completion_date ||= approval_date
      self.stage_dates["completion"] ||= {}
      self.stage_dates["completion"]["estimated_date"] ||= stage_estimated_date("completion").to_s
      self.stage_dates["completion"]["actual_date"] = approval_date.to_s
    elsif completed?
      self.completed = false
      self.actual_completion_date = nil
    end

    save!
  end

  def advance_stage!(approval_date = Date.current)
    if (nxt = next_legal_stage)
      set_legal_stage_with_timing!(nxt, approval_date)
    end
  end

  def rollback_stage!
    if (prev = previous_legal_stage)
      set_legal_stage_with_timing!(prev)
    end
  end

  def join_chain!(target_chain)
    target_id = target_chain.is_a?(Chain) ? target_chain.id : target_chain
    return if chain_id == target_id

    update!(chain_id: target_id)
  end

  private

  def ensure_chain
    return if chain.present? || chain_id.present?

    self.chain = Chain.new(user: creator_or_listing_user, active: true)
  end

  def handle_chain_reassignment
    old_id, new_id = saved_changes["chain_id"]
    if old_id.present?
      old_chain = Chain.find_by(id: old_id)
      if old_chain && !old_chain.destroyed?
        if old_chain.transactions.reload.empty?
          old_chain.destroy
        else
          old_chain.sync_status!
        end
      end
    end
    if new_id.present?
      Chain.find_by(id: new_id)&.sync_status!
    end
  end

  # The property's sold status follows its transactions (buyer attached / conveyancing started)
  def refresh_property_sold_status
    property&.refresh_sold_status!
    old_property_id = saved_change_to_property_id? ? property_id_before_last_save : nil
    Property.find_by(id: old_property_id)&.refresh_sold_status! if old_property_id
  end

  def sync_chain_status
    chain&.sync_status!
  end

  def cleanup_empty_chain_and_sync
    return unless chain_id.present?

    ch = Chain.find_by(id: chain_id)
    return unless ch && !ch.destroyed?

    if ch.transactions.reload.empty?
      ch.destroy
    else
      ch.sync_status!
    end
  end

  def auto_merge_chains_sharing_property
    return unless chain.present? && property.present?

    # Check if this property already has transactions in another chain
    other_chain = property.chains.where.not(id: chain_id).first ||
                  property.transactions.where.not(chain_id: chain_id).first&.chain

    if other_chain.present? && other_chain.id != chain_id
      Chain.merge!(chain, other_chain)
    end
  end

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

  def initialize_stage_and_completion_dates
    start = transaction_start_date
    self.estimated_completion_date ||= start + 84.days
    self.stage_dates ||= {}

    span = [estimated_completion_date - start, 7].max.to_f
    LEGAL_STAGES.each do |stg|
      self.stage_dates[stg] ||= {}
      if self.stage_dates[stg]["estimated_date"].blank?
        offset_ratio = (STAGE_DEFAULT_OFFSETS[stg] || 84) / 84.0
        self.stage_dates[stg]["estimated_date"] = (start + (offset_ratio * span).round.days).to_s
      end
    end

    if completed?
      self.actual_completion_date ||= (updated_at&.to_date || Date.current)
      self.stage_dates["completion"] ||= {}
      self.stage_dates["completion"]["actual_date"] ||= self.actual_completion_date.to_s
    end
  end
end
