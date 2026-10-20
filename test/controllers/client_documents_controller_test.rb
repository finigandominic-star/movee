require "test_helper"

# send real requests to your app, like a browser.
class ClientDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "agent@example.com", user_name: "Agent", password: "Password123")
    # use Devise helper
    sign_in @user
  end

  def upload(file, **params)
    post client_documents_path, params: { file: file, step: "vendor" }.merge(params)
  end

  test "saves the PDF's text, queues the job and goes back to the step" do
    # check exactly one ExtractClientDetailsJob was queued.
    #   This works thanks to the previously created test setting.
    #   The job doesn't run, so no OpenAI call.
    assert_enqueued_jobs 1, only: ExtractClientDetailsJob do
      # every fixture_file_upload: uploads the sample file from test/fixtures/files/.
      # The second argument is the file type the "browser" claims.
      # The third test claims text/plain to test the PDF check.
      upload fixture_file_upload("client_sample.pdf", "application/pdf")
    end

    document = @user.client_documents.last
    assert_equal "client_sample.pdf", document.filename
    assert_includes document.content, "tunde.adebayo@example.com"
    assert_redirected_to new_sale_path(step: "vendor", client_document_id: document.id)
  end

  test "keeps the earlier choices when going back to the buyer step" do
    upload fixture_file_upload("client_sample.pdf", "application/pdf"), step: "buyer", vendor_id: "5", property_id: "7"

    document = @user.client_documents.last
    assert_redirected_to new_sale_path(step: "buyer", vendor_id: "5", property_id: "7", client_document_id: document.id)
  end

  test "refuses files that are not PDFs" do
    # check nothing was saved
    assert_no_difference "ClientDocument.count" do
      upload fixture_file_upload("client_sample.pdf", "text/plain")
    end

    assert_redirected_to new_sale_path(step: "vendor")
    assert_equal "Please choose a PDF file.", flash[:alert]
  end

  test "asks for a file when none was chosen" do
    upload nil

    assert_equal "Choose a PDF file first.", flash[:alert]
  end

  test "needs a signed-in user" do
    # use Devise helper
    sign_out @user
    upload fixture_file_upload("client_sample.pdf", "application/pdf")

    assert_redirected_to new_user_session_path
  end
end
