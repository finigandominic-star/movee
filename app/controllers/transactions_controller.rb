class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show edit update destroy remove_involved_party update_stage]

  def index
    @transactions = policy_scope(Transaction).includes(:property, :involved_party, :user, chain: { transactions: :property }).search(params[:q]).order(created_at: :desc)
  end

  def show
    authorize @transaction
  end

  def new
    @transaction = Transaction.new
    @transaction.property_id = params[:property_id] if params[:property_id].present?
    @transaction.chain_id = params[:chain_id] if params[:chain_id].present?
    @transaction.involved_party_id = params[:involved_party_id] if params[:involved_party_id].present?
    default_buyer_from_chain
    authorize @transaction
  end

  def create
    # A property only ever has one transaction, so adding a buyer to it updates that one
    existing = Transaction.find_by(property_id: transaction_params[:property_id])
    return fill_existing_transaction(existing, join: true) if existing

    @transaction = Transaction.new(transaction_params)
    @transaction.user = current_user if current_user.present?
    authorize @transaction

    return render :new, status: :unprocessable_entity if warn_unlinked_chains?(@transaction)

    if @transaction.save
      return redirect_to buyers_sale_for(@transaction), notice: "Transaction was created and its chains were linked." if merge_unlinked_chains(@transaction)

      redirect_to buyers_sale_for(@transaction), notice: "Transaction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @transaction
  end

  def update
    fill_existing_transaction(@transaction, view: :edit)
  end

  def destroy
    authorize @transaction
    @transaction.destroy
    redirect_to transactions_path, notice: "Transaction was successfully deleted."
  end

  def remove_involved_party
    authorize @transaction, :remove_involved_party?
    @transaction.update(involved_party_id: nil)
    redirect_back fallback_location: @transaction, notice: "Buyer was removed from this transaction."
  end

  def update_stage
    authorize @transaction
    stage = params[:legal_stage] || params.dig(:transaction, :legal_stage)
    approval_date = if params[:approval_date].present?
                      Date.parse(params[:approval_date]) rescue Date.current
                    else
                      Date.current
                    end

    if stage.present? && Transaction::LEGAL_STAGES.include?(stage)
      @transaction.set_legal_stage_with_timing!(stage, approval_date)
      redirect_to @transaction, notice: "Legal conveyancing stage updated to: #{@transaction.legal_stage_title}."
    else
      redirect_to @transaction, alert: "Invalid legal stage selected."
    end
  end

  private

  # Adding to a chain extends it past its last property, so the buyer is whoever sells that property
  # (unless they're leaving the market and not buying onward)
  def default_buyer_from_chain
    return if @transaction.involved_party_id.present? || @transaction.chain_id.blank?

    seller = Chain.find_by(id: @transaction.chain_id)&.end_transaction&.property&.involved_party
    @transaction.involved_party_id = seller.id if seller && !seller.leaving_market?
  end

  # Used by create and update. Owners can change the whole transaction. Any agent can fill in a buyer where there isn't one yet
  # (as in the new-sale flow), but only the buyer: the chain, stage and dates stay as they are.
  # When adding to a chain (join) a property that has no buyer yet, its chain is merged with the chosen one instead of moved.
  def fill_existing_transaction(existing, view: :new, join: false)
    # Adding a transaction never replaces a buyer: that's done by editing the transaction
    if join && existing.involved_party_id.present?
      authorize existing, :create?
      @transaction = Transaction.new(transaction_params)
      @transaction.errors.add(:property, "already has a buyer")
      return render :new, status: :unprocessable_entity
    end

    if policy(existing).update?
      authorize existing, :update?
      attrs = transaction_params
    elsif existing.involved_party_id.blank? && transaction_params[:involved_party_id].present?
      authorize existing, :create?
      attrs = transaction_params.slice(:involved_party_id)
    else
      authorize existing, :update?
    end

    chain_to_join = chain_to_join(existing) if join && existing.involved_party_id.blank?
    attrs = attrs.except(:chain_id) if chain_to_join
    existing.assign_attributes(attrs)
    @transaction = existing
    return render view, status: :unprocessable_entity if !chain_to_join && warn_unlinked_chains?(existing)

    if existing.save
      if chain_to_join
        Chain.merge!(existing.chain, chain_to_join)
        return redirect_to (join ? buyers_sale_for(existing) : existing), notice: "Transaction was updated and its chains were joined."
      end
      return redirect_to existing, notice: "Transaction was updated and its chains were linked." if merge_unlinked_chains(existing)

      redirect_to existing, notice: "Transaction was successfully updated."
    else
      render view, status: :unprocessable_entity
    end
  end

  # After adding a buyer, land on the sale of the property that buyer is selling (the next link in the chain),
  # or on the transaction itself when they aren't selling one here
  def buyers_sale_for(transaction)
    buyer_id = transaction.involved_party_id
    return transaction if buyer_id.blank?

    Transaction.joins(:property)
               .where(chain_id: transaction.reload.chain_id, properties: { involved_party_id: buyer_id })
               .where.not(id: transaction.id)
               .order(:id).first || transaction
  end

  # The chosen chain, when it isn't the one the existing transaction is already in
  def chain_to_join(existing)
    chain = Chain.find_by(id: transaction_params[:chain_id])
    chain unless chain.nil? || chain.id == existing.chain_id
  end

  # Joins the buyer's other chains into this transaction's chain when the warning's "Link the chains" was chosen.
  # Returns true if any chains were merged.
  def merge_unlinked_chains(transaction)
    return false unless params[:merge_chains] == "1"

    chains = transaction.unlinked_buyer_chains.to_a
    chains.each { |other| Chain.merge!(transaction.reload.chain, other) }
    chains.any?
  end

  # A buyer who is selling their own home in another chain should normally be linked into that chain.
  # Sets @unlinked_chains and returns true so the form can ask for confirmation, unless it was already given.
  def warn_unlinked_chains?(transaction)
    return false if params[:confirm_unlinked] == "1" || params[:merge_chains] == "1"
    return false unless transaction.new_record? || transaction.involved_party_id_changed?

    @unlinked_chains = transaction.unlinked_buyer_chains.to_a
    @unlinked_chains.any?
  end

  def set_transaction
    @transaction = Transaction.includes(:property, :chain, :involved_party).find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(
      :property_id,
      :chain_id,
      :involved_party_id,
      :completed,
      :legal_stage,
      :estimated_completion_date,
      :actual_completion_date
    )
  end
end
