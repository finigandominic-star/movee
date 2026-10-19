# Headless policy for the guided new-sale flow (SalesController); the records it creates
# are authorised individually with their own policies.
class SalePolicy < ApplicationPolicy
  def new?
    user.present?
  end

  def create?
    user.present?
  end
end
