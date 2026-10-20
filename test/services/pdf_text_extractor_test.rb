require "test_helper"

class PdfTextExtractorTest < ActiveSupport::TestCase
  test "returns the text of a PDF" do
    text = PdfTextExtractor.call(file_fixture("client_sample.pdf")) # Rails helper finds files in test/fixtures/files/ -> sample pdf needs to be there

    assert_includes text, "ADEBAYO, Tunde"
    assert_includes text, "14 Maple Grove, Ealing, London, W5 3PL"
    assert_includes text, "tunde.adebayo@example.com"
  end

  test "removes extra spaces used for layout" do
    text = PdfTextExtractor.call(file_fixture("client_sample.pdf"))

    # check there are no double spaces left
    assert_no_match(/  /, text)
  end

  test "raises a clear error when the file is not a PDF" do
    error = assert_raises(PdfTextExtractor::Error) do
      PdfTextExtractor.call(StringIO.new("this is not a pdf")) # pretends to be a file, without needing a real one on disk
    end

    assert_equal "This file couldn't be read as a PDF.", error.message
  end
end

# test in rails console: puts PdfTextExtractor.call(Rails.root.join("test/fixtures/files/client_sample.pdf"))
# runs the class on the sample file, then returns the extracted, cleaned up text from the sample pdf file, and prints it
