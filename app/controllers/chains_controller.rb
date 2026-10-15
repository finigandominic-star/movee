class ChainsController < ApplicationController
  #before_action :authenticate_user!
  before_action :set_chain, only: %i[show edit update destroy]

  def index
    @chains = Chain.includes(transactions: [:property, :involved_party]).all
  end

  def show
  end

  def new
    @chain = Chain.new
  end

  def create
    @chain = Chain.new(chain_params)

    if @chain.save
      redirect_to @chain, notice: "Chain was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @chain.update(chain_params)
      redirect_to @chain, notice: "Chain was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @chain.destroy
    redirect_to chains_path, notice: "Chain was successfully deleted."
  end

  private

  def set_chain
    @chain = Chain.includes(transactions: [:property, :involved_party]).find(params[:id])
  end

  def chain_params
    params.require(:chain).permit(:active)
  end
end
