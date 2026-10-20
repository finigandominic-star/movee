# Agent profiles are visible to every signed-in agent so they can coordinate across chains.
class UserPolicy < ApplicationPolicy
  def show?
    user.present?
  end
end
