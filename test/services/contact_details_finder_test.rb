require "test_helper"

class ContactDetailsFinderTest < ActiveSupport::TestCase
  # before each test: read sample PDF once per test, so no need to repeat those lines everywhere.
  setup do
    text = PdfTextExtractor.call(file_fixture("client_sample.pdf"))
    @finder = ContactDetailsFinder.new(text)
  end

  # tests check for clients' details and also for real estate agency's
  test "finds every email in the sample PDF" do
    assert_equal ["enquiries@harbourandheath.co.uk", "tunde.adebayo@example.com"], @finder.emails
  end

  test "finds every phone number in the sample PDF" do
    assert_equal ["+44 20 7946 0312", "07700 900123"], @finder.phone_numbers
  end

  test "finds every post code in the sample PDF" do
    assert_equal ["E1W 3ST", "EC3V 9AN", "W5 3PL"], @finder.post_codes
  end

  # testing edge cases of numbers that look phone numbers but aren't
  test "understands different ways of writing phone numbers" do
    finder = ContactDetailsFinder.new("Call 0117 496 0456, +44 (0)7700 900123 or 020-7946-0789")

    assert_equal ["0117 496 0456", "+44 (0)7700 900123", "020-7946-0789"], finder.phone_numbers
  end

  test "ignores long numbers that are not phone numbers" do
    assert_empty ContactDetailsFinder.new("Reference 1234567890123").phone_numbers
  end

  test "formats post codes the UK way" do
    assert_equal "SW1A 2AA", ContactDetailsFinder.format_post_code("sw1a2aa")
  end

  test "returns empty lists for empty text" do
    finder = ContactDetailsFinder.new(nil)

    assert_empty finder.emails
    assert_empty finder.phone_numbers
    assert_empty finder.post_codes
  end
end
