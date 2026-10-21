# Turns a PDF into plain text. The PDF itself is not kept anywhere.
# Note: The extracted text is stored in the DB in its own table by whoever calls it.
class PdfTextExtractor
  # creates our own error type. The code calling this class only needs to catch PdfTextExtractor::Error,
  # and doesn't need to know about pdf-reader's many error types.
  class Error < StandardError; end

  # safety limit, so nobody uploads a 500-page document
  MAX_PAGES = 15

  def self.call(file)
    new(file).call # shorter version for PdfTextExtractor.new(file).call
  end

  def initialize(file)
    @file = file
  end

  def call
    # accept a file path or an open file; also pass a path for tests, and later the actual uploaded file.
    reader = PDF::Reader.new(@file)
    raise Error, "The PDF has more than #{MAX_PAGES} pages." if reader.page_count > MAX_PAGES

    text = tidy(reader.pages.map(&:text).join("\n\n"))
    # catches scanned PDFs that are empty or contain images, not text, so pdf-reader finds nothing.
    raise Error, "No text found in this PDF. Is it a scan?" if text.blank?

    text

  # catch pdf-reader's errors and turn them into ours
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError
    raise Error, "This file couldn't be read as a PDF."
  end

  private

  # Removes the extra spaces and blank lines PDFs use for layout
  def tidy(text)
    text.gsub(/[ \t]+/, " ")      # many spaces → one space
        .gsub(/ *\n */, "\n")     # no spaces at the start or end of lines
        .gsub(/\n{3,}/, "\n\n")   # at most one empty line in a row
        .strip
  end
end
