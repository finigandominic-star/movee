class TransactionPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    true
  end

  def update?
    user.present? && (user.admin? || record.user == user || record.property&.user == user)
  end

  def destroy?
    user.present? && (user.admin? || record.user == user || record.property&.user == user)
  end

  # The agent who manages the buyer can take their own client off a transaction, not only the transaction's owner
  def remove_involved_party?
    update? || (user.present? && record.involved_party&.user_id == user.id)
  end

  def update_stage?
    update?
  end

  # The agent who manages the client can share the status with them, not only the transaction's owner
  def share_links?
    update? || (user.present? && record.involved_party&.user_id == user.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
