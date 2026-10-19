class DashboardsController < ApplicationController
  # Signed-in home: the agent's own clients, listings, transactions and chains, plus what needs doing next.
  def show
    load_counts
    load_attention_items
    @recent_transactions = my_transactions.includes(:property, chain: { transactions: :property })
                                          .order(created_at: :desc)
                                          .limit(5)
  end

  private

  def my_properties
    Property.where(user_id: current_user.id)
  end

  # Transactions the agent created, or on properties they list
  def my_transactions
    Transaction.where(user_id: current_user.id)
               .or(Transaction.where(property_id: my_properties.select(:id)))
  end

  def active_transactions
    @active_transactions ||= my_transactions.pending.includes(:property).to_a
  end

  def load_counts
    @clients_count = InvolvedParty.where(user_id: current_user.id)
                                  .or(InvolvedParty.where(id: my_properties.select(:involved_party_id)))
                                  .count
    @properties_count = my_properties.count
    @active_transactions_count = active_transactions.size
    @open_chains = Chain.where(id: my_transactions.select(:chain_id))
                        .includes(transactions: :property)
                        .order(:id)
                        .reject(&:chain_completed?)
  end

  # Behind-schedule transactions, chains with an open end, listings missing a vendor or a sale
  def load_attention_items
    @overdue_transactions = active_transactions.select do |tx|
      %i[behind overdue].include?(tx.overall_timing_status[:status])
    end
    @open_end_chains = @open_chains.reject(&:both_ends_closed?)

    unsold = my_properties.where(sold: [false, nil])
    @unfinished_properties = unsold.where(involved_party_id: nil)
                                   .or(unsold.where.not(id: Transaction.select(:property_id)))
                                   .includes(:transactions)
                                   .order(created_at: :desc)
  end
end
