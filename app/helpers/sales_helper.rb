module SalesHelper
  CLIENT_FIELD_LABELS = { "first_name" => "first name", "last_name" => "last name",
                          "email" => "email", "phone" => "phone number" }.freeze

  # Fields of the new client form that the uploaded PDF didn't provide, e.g. ["phone number"]
  def fields_missing_from(client_document)
    CLIENT_FIELD_LABELS.reject { |field, _| client_document.extracted_data[field].present? }.values
  end
end
