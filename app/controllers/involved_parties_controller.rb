class InvolvedPartiesController < ApplicationController
  before_action :set_involved_party, only: %i[show edit update destroy assign_property unassign_property assign_transaction unassign_transaction]

  def index
    @involved_parties = InvolvedParty.includes(:properties, :transactions).order(created_at: :desc)
  end

  def show
    @available_properties = Property.where(involved_party_id: nil)
    @available_transactions = Transaction.where(involved_party_id: nil)
  end

  def new
    @involved_party = InvolvedParty.new
  end

  def create
    @involved_party = InvolvedParty.new(involved_party_params)

    if @involved_party.save
      redirect_to @involved_party, notice: "Involved party was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @involved_party.update(involved_party_params)
      redirect_to @involved_party, notice: "Involved party was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @involved_party.destroy
    redirect_to involved_parties_path, notice: "Involved party was successfully deleted."
  end

  # Assign an existing property to this involved party
  def assign_property
    property = Property.find_by(id: params[:property_id])
    if property
      property.update(involved_party: @involved_party)
      redirect_to @involved_party, notice: "Property (#{property.short_address}) was assigned to #{@involved_party.full_name}."
    else
      redirect_to @involved_party, alert: "Property could not be found."
    end
  end

  # Remove/unassign a property from this involved party
  def unassign_property
    property = @involved_party.properties.find_by(id: params[:property_id]) || Property.find_by(id: params[:property_id])
    if property
      property.update(involved_party: nil)
      redirect_to @involved_party, notice: "Property (#{property.short_address}) was unassigned from #{@involved_party.full_name}."
    else
      redirect_to @involved_party, alert: "Property was not assigned to this party."
    end
  end

  # Assign an existing transaction to this involved party
  def assign_transaction
    transaction = Transaction.find_by(id: params[:transaction_id])
    if transaction
      transaction.update(involved_party: @involved_party)
      redirect_to @involved_party, notice: "Transaction ##{transaction.id} was assigned to #{@involved_party.full_name}."
    else
      redirect_to @involved_party, alert: "Transaction could not be found."
    end
  end

  # Remove/unassign a transaction from this involved party
  def unassign_transaction
    transaction = @involved_party.transactions.find_by(id: params[:transaction_id]) || Transaction.find_by(id: params[:transaction_id])
    if transaction
      transaction.update(involved_party: nil)
      redirect_to @involved_party, notice: "Transaction ##{transaction.id} was unassigned from #{@involved_party.full_name}."
    else
      redirect_to @involved_party, alert: "Transaction was not assigned to this party."
    end
  end

  private

  def set_involved_party
    @involved_party = InvolvedParty.includes(:properties, transactions: [:property, :chain]).find(params[:id])
  end

  def involved_party_params
    params.require(:involved_party).permit(:first_name, :last_name, :email, :phone, :contact_info, :seller, :buyer)
  end
end
