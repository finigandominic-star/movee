class ChainsController < ApplicationController
  before_action :set_chain, only: %i[show edit update destroy]

  def index
    @chains = policy_scope(Chain).includes(:user, transactions: [:property, :user, :involved_party]).order(created_at: :desc)
  end

  def show
    authorize @chain
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

  private

  def set_chain
    @chain = Chain.includes(:user, transactions: [:property, :user, :involved_party]).find(params[:id])
  end

  def chain_params
    params.require(:chain).permit(:active)
  end
end
