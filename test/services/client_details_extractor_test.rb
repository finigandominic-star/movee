require "test_helper"

class ClientDetailsExtractorTest < ActiveSupport::TestCase
  setup do
    @text = PdfTextExtractor.call(file_fixture("client_sample.pdf"))
  end

  def extract(answer)
    ClientDetailsExtractor.call(@text, llm: FakeChat.new(answer))
  end

  test "keeps contact details that are in the PDF" do
    details = extract({ "email" => "tunde.adebayo@example.com", "phone" => "07700 900123", "post_code" => "W5 3PL" })

    assert_equal "tunde.adebayo@example.com", details["email"]
    assert_equal "07700 900123", details["phone"]
    assert_equal "W5 3PL", details["post_code"]
  end

  test "throws away contact details that are not in the PDF" do
    details = extract({ "email" => "made.up@example.com", "phone" => "07700 111222", "post_code" => "SW1A 2AA" })

    assert_nil details["email"]
    assert_nil details["phone"]
    assert_nil details["post_code"]
  end

  test "accepts the same details written differently and uses the PDF's version" do
    details = extract({ "email" => "Tunde.Adebayo@Example.com", "phone" => "+44 7700 900123", "post_code" => "w53pl" })

    assert_equal "tunde.adebayo@example.com", details["email"]
    assert_equal "07700 900123", details["phone"]
    assert_equal "W5 3PL", details["post_code"]
  end

  test "tidies text answers" do
    details = extract({ "first_name" => "  Tunde ", "city" => "" })

    assert_equal "Tunde", details["first_name"]
    assert_nil details["city"]
  end

  test "uses undecided when onward purchase is not an allowed value" do
    assert_equal "undecided", extract({ "onward_purchase" => "maybe" })["onward_purchase"]
  end

  test "keeps an allowed onward purchase value" do
    assert_equal "buying", extract({ "onward_purchase" => "buying" })["onward_purchase"]
  end
end
