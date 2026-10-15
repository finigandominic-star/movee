class ChainsController < ApplicationController
  before_action :set_chain, only: %i[show edit update destroy merge]

  def index
    @chains = policy_scope(Chain).includes(:user, transactions: [:property, :user, :involved_party]).order(created_at: :desc)
  end

  def show
    authorize @chain
    @available_merge_chains = Chain.where.not(id: @chain.id).order(:id)
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

  private

  def set_chain
    @chain = Chain.includes(:user, transactions: [:property, :user, :involved_party]).find(params[:id])
  end

  def chain_params
    params.require(:chain).permit(:active)
  end
end
