# Read-only agent profile: contact details plus the properties and sales they manage.
class UsersController < ApplicationController
  def show
    @agent = User.find(params[:id])
    authorize @agent
    @properties = @agent.properties.order(:street, :house_number)
    @transactions = Transaction.left_joins(:property)
                               .where(user_id: @agent.id).or(Transaction.where(properties: { user_id: @agent.id }))
                               .includes(:property, :chain)
                               .order(created_at: :desc)
    @client_count = @agent.involved_parties.count
  end
end
