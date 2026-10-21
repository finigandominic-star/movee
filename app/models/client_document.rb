# One uploaded client PDF: the text we read from it and the details found.
# The PDF itself is not stored (to keep it later, add: has_one_attached :file).

class ClientDocument < ApplicationRecord
  # allowed values, used by the validations
  STATUSES = %w[processing done failed].freeze
  STEPS = %w[vendor buyer].freeze
  # Still processing after 2 minutes: the background job is probably not running
  STUCK_AFTER = 2.minutes
  # Which found details fit which field (needed to have the fill_from_form functionality in the sales_stepper,
  #   and also in the new_client & new_property)
  CLIENT_FIELDS = %w[first_name last_name email phone onward_purchase].freeze
  ADDRESS_FIELDS = %w[house_number street second_line_of_address city post_code].freeze

  belongs_to :user

  # Rails will only accept the values gotten from the 2 constants (refuses e.g. status: "finished")
  validates :status, inclusion: { in: STATUSES }
  validates :step, inclusion: { in: STEPS }
  validates :filename, presence: true

  def processing? = status == "processing"
  def done? = status == "done"
  def failed? = status == "failed"

  # informing user that the AI fill-form process is stuck
  def stuck? = processing? && created_at < STUCK_AFTER.ago

  # The client's details found in the PDF, ready for InvolvedParty.new (empty until done)
  def client_details
    return {} unless done?

    extracted_data.slice(*CLIENT_FIELDS).compact.symbolize_keys
  end

  # The client's current address, ready for Property.new (empty until done, or if they're clearly not selling)
  def property_address
    return {} unless done?
    return {} if extracted_data["selling"] == false

    extracted_data.slice(*ADDRESS_FIELDS).compact.symbolize_keys
  end
end
