# Any signed-in realtor can upload a client PDF; it is always saved as theirs.
class ClientDocumentPolicy < ApplicationPolicy
  def create?
    user.present?
  end
end
