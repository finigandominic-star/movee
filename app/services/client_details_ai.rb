# Asks OpenAI to find the client's details in the text of a PDF.
# Returns a Hash with exactly the FIELDS below (nil when not found). Nothing is saved or checked here.
class ClientDetailsAi
  class Error < StandardError; end

  FIELDS = %w[
    first_name last_name email phone
    selling buying onward_purchase
    house_number street second_line_of_address city post_code
  ].freeze

  INSTRUCTIONS = <<~PROMPT
    You read documents from UK estate agents and find the details of the CLIENT:
    the person buying and/or selling a home. Ignore the estate agent, the agency
    and anyone else.

    Rules:
    - Copy email, phone and post code exactly as written. Never invent or change them.
    - If something is not clearly in the document, answer null. Never guess.
    - Names: find the client's first name and last name, in whatever order or format they are written
      (e.g. "Tunde Adebayo", "ADEBAYO, Tunde", "Adebayo Tunde").
    - Keep the spelling of names exactly as written.
      Only if a name is written entirely in capitals, write it in normal case,
      keeping parts like Mc, O' and hyphens correct
      (e.g. "MCBRIDE" → "McBride", "SMITH-JONES" → "Smith-Jones").
    - Put middle names after the first name in first_name. Leave out titles (Mr, Mrs, Dr).
    - Particles such as van, van der, de, da, von and le are part of the last name
      (e.g. "Anna van der Berg" → first_name "Anna", last_name "van der Berg").
      If written entirely in capitals, write the particles in small letters.
    - The address is the client's current home address. Split it into:
      house_number: the number or name of the house, e.g. "14" or "Rose Cottage".
      street: the street name, e.g. "Maple Grove".
      second_line_of_address: everything between the street and the city, such as a flat number or a district,
        e.g. "Flat 4" or "Ealing". Use null only if there is nothing there.
      city: the town or city, e.g. "London".
      post_code: the post code, e.g. "W5 3PL".
    - selling: true if they are selling a property, false if clearly not, null if unclear.
    - buying: true if they are buying a property, false if clearly not, null if unclear.
    - onward_purchase: "buying" if they sell and also buy another home,
      "leaving_market" if they sell and clearly do not buy, otherwise "undecided".
    - The address is the client's current home address, split into its parts.
  PROMPT

  nullable_string = { type: %w[string null] }
  nullable_boolean = { type: %w[boolean null] }

  SCHEMA = {
    name: "client_details",
    schema: {
      type: "object",
      additionalProperties: false,
      required: FIELDS,
      properties: {
        first_name: nullable_string,
        last_name: nullable_string,
        email: nullable_string,
        phone: nullable_string,
        selling: nullable_boolean,
        buying: nullable_boolean,
        onward_purchase: { type: "string", enum: InvolvedParty::ONWARD_PURCHASE_OPTIONS.keys },
        house_number: nullable_string,
        street: nullable_string,
        second_line_of_address: nullable_string,
        city: nullable_string,
        post_code: nullable_string
      }
    }
  }.freeze

  # we're asking the LLM to do something, so we need to 'chat' with it even without a chat function for the user
  # Only the llm argument is for the tests. In the app, nobody passes it,
  # so it uses the default RubyLLM.chat and talks to OpenAI.
  def self.call(text, llm: RubyLLM.chat)
    new(text, llm: llm).call # short for ClientDetailsAi.new(text).call
  end

  def initialize(text, llm: RubyLLM.chat)
    @text = text
    @llm = llm
  end

  def call
    response = @llm.with_instructions(INSTRUCTIONS).with_schema(SCHEMA).ask(@text)
    details = response.parsed
    raise Error, "The assistant gave no answer." unless details.is_a?(Hash)

    details.slice(*FIELDS)
  rescue RubyLLM::Error, RubyLLM::ConfigurationError, JSON::ParserError => e
    raise Error, "The assistant couldn't read this document (#{e.class})."
  end
end
