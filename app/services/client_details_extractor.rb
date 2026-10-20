# Finds a client's details in the text of a PDF: the AI suggests them, and we keep an
# email, phone or post code only if it really appears in the text (better empty than wrong).
# This reuses the fake chat idea from the other test.
# 1. Ask the AI (ClientDetailsAi) for the client's details.
# 2. Tidy every text answer: remove extra spaces, and turn "" into nil.
# 3. Check the answers that ClientDetailsAi can verify:
#   - email: must be one of the emails really in the PDF. Otherwise nil.
#   - phone: must be one of the phone numbers really in the PDF. Compares digits only,
#     so +44 7700 900123 and 07700 900123 count as the same, and the version as written in the PDF is kept.
#   - post code: formatted the UK way, and must be in the PDF.
#   - onward_purchase: must be one of your 3 allowed values. Otherwise "undecided".
# 4. Return the checked details as a Hash.

class ClientDetailsExtractor
  def self.call(text, llm: RubyLLM.chat)
    new(text, llm: llm).call
  end

  def initialize(text, llm: RubyLLM.chat)
    @text = text
    @llm = llm
    @found = ContactDetailsFinder.new(text)
  end

  def call
    # with .transform_valueschanges every value of a hash & keeps the keys
    details = ClientDetailsAi.call(@text, llm: @llm).transform_values { |value| tidy(value) }
    details["email"] = checked_email(details["email"])
    details["phone"] = checked_phone(details["phone"])
    details["post_code"] = checked_post_code(details["post_code"])
    details["onward_purchase"] = checked_onward_purchase(details["onward_purchase"])
    details
  end

  private

  # " Tunde  " → "Tunde", "" → nil; true/false/nil stay as they are
  def tidy(value)
    # .presence gives the value back, or nil if it's blank
    value.is_a?(String) ? value.squish.presence : value
  end

  def checked_email(email)
    return nil if email.nil?

    email = email.downcase
    # .include checks "is x in the list?"
    @found.emails.include?(email) ? email : nil
  end

  # Returns the number as written in the PDF, or nil if the AI's number isn't in the PDF
  def checked_phone(phone)
    return nil if phone.nil?

    # find the first item in a list for which the block is true, or nil
    @found.phone_numbers.find { |found| phone_digits(found) == phone_digits(phone) }
  end

  def checked_post_code(post_code)
    return nil if post_code.nil?

    post_code = ContactDetailsFinder.format_post_code(post_code)
    @found.post_codes.include?(post_code) ? post_code : nil
  end

  # "+44 (0)7700 900123" and "07700 900123" both → "7700900123"
  def phone_digits(phone)
    # .gsub: removes everything that isn't a digit (\D = "not a digit")
    # .delete: removes "44" only if the text starts with it
    phone.gsub(/\D/, "").delete_prefix("44").delete_prefix("0")
  end

  # Only the values the InvolvedParty model allowed; anything else becomes "undecided"
  def checked_onward_purchase(value)
    InvolvedParty::ONWARD_PURCHASE_OPTIONS.key?(value) ? value : "undecided"
  end

end
