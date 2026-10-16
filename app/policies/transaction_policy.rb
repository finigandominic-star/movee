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

  def remove_involved_party?
    update?
  end

  def update_stage?
    update?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
