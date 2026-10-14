class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[show edit update destroy remove_involved_party update_stage]

  def index
    @transactions = policy_scope(Transaction).includes(:property, :chain, :involved_party, :user).order(created_at: :desc)
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
    @transaction = Transaction.new(transaction_params)
    @transaction.user = current_user if current_user.present?

    # Fallback to create a default chain if none exists and none specified
    if @transaction.chain_id.blank? && Chain.none?
      @transaction.chain = Chain.create(active: true, user: current_user)
    end
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
    redirect_back fallback_location: @transaction, notice: "Involved party was unassigned from this transaction."
  end

  def update_stage
    authorize @transaction
    stage = params[:legal_stage] || params.dig(:transaction, :legal_stage)

    if stage.present? && Transaction::LEGAL_STAGES.include?(stage)
      @transaction.update(legal_stage: stage)
      redirect_to @transaction, notice: "Legal conveyancing stage updated to: #{@transaction.legal_stage_title}."
    else
      redirect_to @transaction, alert: "Invalid legal stage selected."
    end
  end

  private

  def set_transaction
    @transaction = Transaction.includes(:property, :chain, :involved_party).find(params[:id])
  end

  def transaction_params
    params.require(:transaction).permit(:property_id, :chain_id, :involved_party_id, :completed, :legal_stage)
  end
end
