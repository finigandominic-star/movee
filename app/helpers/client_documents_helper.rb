module ClientDocumentsHelper
  CLIENT_FIELD_LABELS = { "first_name" => "first name", "last_name" => "last name",
                          "email" => "email", "phone" => "phone number" }.freeze

  ADDRESS_FIELD_LABELS = { "house_number" => "house number", "street" => "street",
                           "city" => "city", "post_code" => "postcode" }.freeze

  # Fields of the form that the uploaded PDF didn't provide, e.g. ["phone number"] or ["post code"]
  def fields_missing_from(client_document)
    labels = client_document.step == "property" ? ADDRESS_FIELD_LABELS : CLIENT_FIELD_LABELS
    labels.reject { |field, _| client_document.extracted_data[field].present? }.values
  end
end
