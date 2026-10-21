class Chain < ApplicationRecord
  belongs_to :user, optional: true
  has_many :transactions, dependent: :destroy

  normalizes :name, with: ->(name) { name.strip.presence }
  validates :name, length: { maximum: 60 }
  has_many :properties, through: :transactions
  has_many :involved_parties, through: :transactions

  has_many :buyers, through: :transactions, source: :involved_party
  has_many :sellers, through: :properties, source: :involved_party

  scope :search, ->(query) {
    return all if query.blank?

    q = "%#{sanitize_sql_like(query)}%"
    left_joins(:properties, :user)
      .where("chains.name ILIKE :q OR properties.house_number ILIKE :q OR properties.street ILIKE :q
              OR properties.city ILIKE :q OR properties.post_code ILIKE :q
              OR users.user_name ILIKE :q OR users.company ILIKE :q", q: q)
      .distinct
  }

  def all_parties
    InvolvedParty.where(id: (buyer_ids + seller_ids).uniq)
  end

  # Orders transactions along buyer-seller relationships:
  # Bottom link (Start) -> intermediate links -> Top link (End)
  def ordered_transactions
    txs = transactions.includes(:involved_party, property: :involved_party).to_a
    return [] if txs.empty?
    return txs if txs.size == 1

    tx_by_buyer = {}
    txs.each do |tx|
      tx_by_buyer[tx.involved_party_id] = tx if tx.involved_party_id.present?
    end

    tx_by_seller = {}
    txs.each do |tx|
      seller_id = tx.property&.involved_party_id
      tx_by_seller[seller_id] = tx if seller_id.present?
    end

    predecessor_of = {}
    txs.each do |tx_b|
      b_buyer_id = tx_b.involved_party_id
      if b_buyer_id.present? && tx_by_seller[b_buyer_id].present? && tx_by_seller[b_buyer_id].id != tx_b.id
        predecessor_of[tx_b.id] = tx_by_seller[b_buyer_id]
      end
    end

    successor_of = {}
    txs.each do |tx_a|
      a_seller_id = tx_a.property&.involved_party_id
      if a_seller_id.present? && tx_by_buyer[a_seller_id].present? && tx_by_buyer[a_seller_id].id != tx_a.id
        successor_of[tx_a.id] = tx_by_buyer[a_seller_id]
      end
    end

    start_candidates = txs.reject { |tx| predecessor_of.key?(tx.id) }
    start_tx = start_candidates.find { |tx| tx.involved_party&.buyer? && !tx.involved_party&.seller? } ||
               start_candidates.first ||
               txs.min_by(&:id)

    ordered = []
    visited = Set.new
    current = start_tx

    while current && !visited.include?(current.id)
      ordered << current
      visited.add(current.id)
      current = successor_of[current.id]
    end

    remaining = txs.reject { |tx| visited.include?(tx.id) }.sort_by(&:id)
    ordered + remaining
  end

  def start_transaction
    ordered_transactions.first
  end

  def end_transaction
    ordered_transactions.last
  end

  # UK property chain start boundary rule:
  # Closed when the bottom purchaser is a First-Time Buyer (no property to sell).
  def first_time_buyer_at_start?
    start_tx = start_transaction
    return false if start_tx.nil?

    party = start_tx.involved_party
    party.present? && party.buyer? && !party.seller?
  end

  # UK property chain end boundary rule:
  # Closed when the top vendor is leaving the property market (no onward purchase).
  def leaving_market_at_end?
    end_tx = end_transaction
    return false if end_tx.nil?

    seller_party = end_tx.property&.involved_party
    seller_party.present? && seller_party.leaving_market?
  end

  # A chain's ends are closed when both start (FTB) and end (leaving market) boundaries are satisfied.
  def both_ends_closed?
    first_time_buyer_at_start? && leaving_market_at_end?
  end

  def all_transactions_completed?
    txs = transactions
    txs.any? && txs.all?(&:completed?)
  end

  # A chain is completed IF AND ONLY IF:
  # 1. Both ends are closed (first-time buyer at start, person leaving property market at end).
  # 2. All transactions in the chain are completed.
  def chain_completed?
    both_ends_closed? && all_transactions_completed?
  end

  # A chain remains OPEN until both ends are closed and all transactions are completed.
  def chain_open?
    !chain_completed?
  end

  # Synchronizes the active column with whether the chain is open.
  def sync_status!
    new_active = chain_open?
    update_columns(active: new_active) if active != new_active
    new_active
  end

  # Merges two chains.
  # The merged chain ALWAYS inherits the lowest ID.
  # All transactions from the higher ID chain are reassigned to the lowest ID chain.
  # The higher ID chain is destroyed.
  def self.merge!(chain_a, chain_b)
    raise ArgumentError, "Both chains must be present to merge" if chain_a.nil? || chain_b.nil?
    return chain_a if chain_a.id == chain_b.id

    winner, loser = [chain_a, chain_b].sort_by(&:id)

    ActiveRecord::Base.transaction do
      winner.user ||= loser.user
      winner.save! if winner.changed?

      loser.transactions.update_all(chain_id: winner.id)
      loser.reload.destroy!
      winner.reload
      winner.sync_status!
    end

    winner
  end

  def merge_with!(other_chain)
    Chain.merge!(self, other_chain)
  end

  # Connects a property to this chain without requiring the user to identify or know any other chain.
  # If the property is already part of another chain, the chains are automatically merged under the lowest ID.
  # If the property is not yet in a chain, it creates a linking transaction.
  def connect_property!(property, position: :top, current_user: nil)
    raise ArgumentError, "Property must be present" if property.nil?

    # Check if property already belongs to another chain
    existing_other_chain = property.chains.where.not(id: id).first ||
                           property.transactions.where.not(chain_id: id).first&.chain

    if existing_other_chain.present? && existing_other_chain.id != id
      return Chain.merge!(self, existing_other_chain)
    end

    # Otherwise, create a transaction connecting this chain to the property
    if position.to_sym == :top
      buyer = end_transaction&.property&.involved_party
      Transaction.create!(
        chain: self,
        property: property,
        involved_party: buyer,
        user: current_user || property.user,
        legal_stage: "offer_accepted"
      )
    else
      seller = start_transaction&.involved_party
      property.update!(involved_party: seller) if seller.present? && property.involved_party.nil?
      Transaction.create!(
        chain: self,
        property: property,
        involved_party: nil,
        user: current_user || property.user,
        legal_stage: "offer_accepted"
      )
    end

    reload
    sync_status!
    self
  end

  # UI Presentation Helpers
  def status_label
    if chain_completed?
      "Completed Chain"
    elsif both_ends_closed?
      "Open (In Progress)"
    elsif !first_time_buyer_at_start? && !leaving_market_at_end?
      "Open (Both Ends Incomplete)"
    elsif !first_time_buyer_at_start?
      "Open (No First-Time Buyer at Start)"
    else
      "Open (Vendor Buying Onward at End)"
    end
  end

  def status_badge_class
    if chain_completed?
      "bg-success"
    elsif both_ends_closed?
      "bg-primary"
    else
      "bg-warning text-dark"
    end
  end

  def start_node_status
    if first_time_buyer_at_start?
      {
        closed: true,
        label: "Closed (First-Time Buyer)",
        badge_class: "bg-success text-white",
        party_name: start_transaction.involved_party.full_name,
        description: "#{start_transaction.involved_party.full_name} is a first-time buyer with no property to sell."
      }
    elsif start_transaction&.involved_party.present?
      {
        closed: false,
        label: "Open (Buyer has property to sell)",
        badge_class: "bg-warning text-dark",
        party_name: start_transaction.involved_party.full_name,
        description: "#{start_transaction.involved_party.full_name} has a property to sell (chain continuing downward)."
      }
    else
      {
        closed: false,
        label: "Open (No Buyer Assigned)",
        badge_class: "bg-secondary text-white",
        party_name: "Unassigned",
        description: "No purchaser assigned to start of chain."
      }
    end
  end

  def end_node_status
    if leaving_market_at_end?
      {
        closed: true,
        label: "Closed (Leaving Property Market)",
        badge_class: "bg-success text-white",
        party_name: end_transaction.property.involved_party.full_name,
        description: "#{end_transaction.property.involved_party.full_name} has no onward purchase (leaving market / no onward chain)."
      }
    elsif end_transaction&.property&.involved_party&.onward_purchase == "undecided"
      {
        closed: false,
        label: "Open (Onward plans unknown)",
        badge_class: "bg-warning text-dark",
        party_name: end_transaction.property.involved_party.full_name,
        description: "Confirm whether #{end_transaction.property.involved_party.full_name} is buying onward or leaving the market."
      }
    elsif end_transaction&.property&.involved_party.present?
      {
        closed: false,
        label: "Open (Vendor purchasing onward)",
        badge_class: "bg-warning text-dark",
        party_name: end_transaction.property.involved_party.full_name,
        description: "#{end_transaction.property.involved_party.full_name} has an onward purchase (chain continuing upward)."
      }
    else
      {
        closed: false,
        label: "Open (No Vendor Assigned)",
        badge_class: "bg-secondary text-white",
        party_name: "Unassigned",
        description: "No vendor assigned to end of chain."
      }
    end
  end
end
