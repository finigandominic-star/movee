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
    authorize @transaction
  end

  def create
    # A property only ever has one transaction, so adding a buyer to it updates that one
    existing = Transaction.find_by(property_id: transaction_params[:property_id])
    return fill_existing_transaction(existing) if existing

    @transaction = Transaction.new(transaction_params)
    @transaction.user = current_user if current_user.present?
    authorize @transaction

    if @transaction.save
      redirect_to @transaction, notice: "Transaction was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @transaction
  end

  def update
    authorize @transaction
    if @transaction.update(transaction_params)
      redirect_to @transaction, notice: "Transaction was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @transaction
    @transaction.destroy
    redirect_to transactions_path, notice: "Transaction was successfully deleted."
  end

  def remove_involved_party
    authorize @transaction, :update?
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

  # Owners can change the whole transaction. Any agent can fill in a buyer where there isn't one yet
  # (as in the new-sale flow), but only the buyer: the chain and stage stay as they are.
  def fill_existing_transaction(existing)
    if policy(existing).update?
      authorize existing, :update?
      attrs = transaction_params
    elsif existing.involved_party_id.blank? && transaction_params[:involved_party_id].present?
      authorize existing, :create?
      attrs = transaction_params.slice(:involved_party_id)
    else
      authorize existing, :update?
    end

    if existing.update(attrs)
      redirect_to existing, notice: "Transaction was successfully updated."
    else
      @transaction = existing
      render :new, status: :unprocessable_entity
    end
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
