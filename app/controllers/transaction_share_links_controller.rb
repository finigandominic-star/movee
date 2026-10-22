class TransactionShareLinksController < ApplicationController
  before_action :set_transaction

  def create
    authorize @transaction, :share_links?

    duration = params[:duration]
    if TransactionShareLink::DURATIONS.key?(duration)
      link = TransactionShareLink.create_for!(@transaction, user: current_user, duration: duration)
      flash[:share_link] = { url: shared_transaction_url(link.token), expires_at: link.expires_at }
    else
      flash[:alert] = "Choose how long the link should stay active."
    end

    redirect_to @transaction
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:transaction_id])
  end
end
