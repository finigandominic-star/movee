# Public, unauthenticated view: the only thing a buyer/seller sees of a transaction
# when their agent shares a time-limited link to its conveyancing stage.
class SharedTransactionsController < ApplicationController
  layout "shared_link"

  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  def show
    @link = TransactionShareLink.find_by(token: params[:token])

    if @link.nil? || @link.expired?
      render :expired, status: :not_found
    else
      @transaction = @link.deal
    end
  end
end
