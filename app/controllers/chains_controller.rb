class ChainsController < ApplicationController
  before_action :set_chain, only: %i[show edit update destroy merge connect_property]

  def index
    @chains = policy_scope(Chain).includes(:user, transactions: [:property, :user, :involved_party]).order(created_at: :desc)
  end

  def show
    authorize @chain
    @available_merge_chains = Chain.where.not(id: @chain.id).order(:id)
    # Exclude properties already present in this chain so the user searches other properties across the network
    @connectable_properties = Property.where.not(id: @chain.transactions.pluck(:property_id).compact).order(:city, :street, :house_number)
  end

  def new
    @chain = Chain.new(active: true)
    authorize @chain
  end

  def create
    @chain = Chain.new(chain_params)
    @chain.user = current_user if current_user.present?
    authorize @chain

    if @chain.save
      redirect_to @chain, notice: "Chain was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @chain
  end

  def update
    authorize @chain
    if @chain.update(chain_params)
      redirect_to @chain, notice: "Chain was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @chain
    @chain.destroy
    redirect_to chains_path, notice: "Chain was successfully deleted."
  end

  def merge
    authorize @chain
    target_chain = Chain.find(params[:target_chain_id])
    surviving_chain = Chain.merge!(@chain, target_chain)
    redirect_to surviving_chain, notice: "Chains merged successfully! Inherited lowest ID: Chain ##{surviving_chain.id}."
  rescue ActiveRecord::RecordNotFound
    redirect_to @chain, alert: "Please select a valid chain to merge with."
  rescue => e
    redirect_to @chain, alert: "Failed to merge chains: #{e.message}"
  end

  # Connects a property to this chain without requiring the user to know or look up another chain ID.
  # If the selected property is already in another chain, the chains are automatically merged under the lowest ID.
  def connect_property
    authorize @chain
    property = Property.find(params[:property_id])
    position = params[:position] == "bottom" ? :bottom : :top

    surviving_chain = @chain.connect_property!(property, position: position, current_user: current_user)

    notice = if surviving_chain.id != @chain.id
               "Connected #{property.short_address}! Combined chains into Chain ##{surviving_chain.id} (inherited lowest ID)."
             else
               "Successfully connected #{property.short_address} to Chain ##{surviving_chain.id}."
             end

    redirect_to surviving_chain, notice: notice
  rescue ActiveRecord::RecordNotFound
    redirect_to @chain, alert: "Please select a valid property to connect."
  rescue => e
    redirect_to @chain, alert: "Failed to connect property: #{e.message}"
  end

  private

  def set_chain
    @chain = Chain.includes(:user, transactions: [:property, :user, :involved_party]).find(params[:id])
  end

  def chain_params
    params.require(:chain).permit(:name, :active)
  end
end
