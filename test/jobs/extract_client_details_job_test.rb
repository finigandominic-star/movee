require "test_helper"

class ExtractClientDetailsJobTest < ActiveJob::TestCase
  setup do
    user = User.create!(email: "agent@example.com", user_name: "Agent", password: "Password123")
    @document = user.client_documents.create!(
      step: "vendor",
      filename: "client_sample.pdf",
      content: PdfTextExtractor.call(file_fixture("client_sample.pdf"))
    )
  end

  test "saves the details and marks the document as done" do
    llm = FakeChat.new({ "first_name" => "Tunde", "email" => "tunde.adebayo@example.com" })

    ExtractClientDetailsJob.perform_now(@document, llm: llm)

    @document.reload
    assert @document.done?
    assert_equal "Tunde", @document.extracted_data["first_name"]
    assert_equal "tunde.adebayo@example.com", @document.extracted_data["email"]
  end

  test "marks the document as failed when the assistant gives no answer" do
    ExtractClientDetailsJob.perform_now(@document, llm: FakeChat.new(nil))

    @document.reload
    assert @document.failed?
    assert_equal "The assistant gave no answer.", @document.error_message
  end

  test "does nothing for a document that is already done" do
    @document.update!(status: "done", extracted_data: { "first_name" => "Kept" })

    ExtractClientDetailsJob.perform_now(@document, llm: FakeChat.new({ "first_name" => "Changed" }))

    assert_equal "Kept", @document.reload.extracted_data["first_name"]
  end

  test "can be put in the queue" do
    assert_enqueued_with(job: ExtractClientDetailsJob, args: [@document]) do
      ExtractClientDetailsJob.perform_later(@document)
    end
  end
end
