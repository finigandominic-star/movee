class Transaction < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :involved_party, optional: true
  belongs_to :chain
  belongs_to :property

  def creator_or_listing_user
    user || property&.user
  end

  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: [false, nil]) }

  def status_label
    completed? ? "Completed" : "In Progress"
  end

  def status_badge_class
    completed? ? "bg-success" : "bg-warning text-dark"
  end
end
