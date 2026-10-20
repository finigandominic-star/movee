# One uploaded client PDF: the text we read from it and the details found.
# The PDF itself is not stored (to keep it later, add: has_one_attached :file).

class ClientDocument < ApplicationRecord
  # allowed values, used by the validations
  STATUSES = %w[processing done failed].freeze
  STEPS = %w[vendor buyer].freeze

  belongs_to :user

  # Rails will only accept the values gotten from the 2 constants (refuses e.g. status: "finished")
  validates :status, inclusion: { in: STATUSES }
  validates :step, inclusion: { in: STEPS }
  validates :filename, presence: true

  def processing? = status == "processing"
  def done? = status == "done"
  def failed? = status == "failed"
end
