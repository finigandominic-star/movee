class Transaction < ApplicationRecord
  belongs_to :involved_party, optional: true
  belongs_to :chain
  belongs_to :property

  scope :completed, -> { where(completed: true) }
  scope :pending, -> { where(completed: [false, nil]) }

  def status_label
    completed? ? "Completed" : "In Progress"
  end

  def status_badge_class
    completed? ? "bg-success" : "bg-warning text-dark"
  end
end
