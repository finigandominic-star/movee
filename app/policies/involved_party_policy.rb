class InvolvedPartyPolicy < ApplicationPolicy
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
    user.present? && (user.admin? || record.user == user || record.user_associated?(user))
  end

  def destroy?
    user.present? && (user.admin? || record.user == user)
  end

  def assign_property?
    update?
  end

  def unassign_property?
    update?
  end

  def assign_transaction?
    update?
  end

  def unassign_transaction?
    update?
  end

  def show_personal_data?
    user.present? && (user.admin? || record.user_associated?(user))
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
