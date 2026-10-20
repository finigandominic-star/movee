require "test_helper"

class ClientDocumentTest < ActiveSupport::TestCase
 setup do
    # create a test user in code.
    # Check that these fields match your User validations;
    # if user_name or the password rules differ, the error message tells so
    @user = User.create!(email: "agent@example.com", user_name: "Agent", password: "Password123")
  end

  def build_document(**attributes) #  each test allowed to change only what it's testing, with defaults for the rest.
    ClientDocument.new({ user: @user, step: "vendor", filename: "client.pdf" }.merge(attributes))
  end

  test "is valid with the defaults" do
    document = build_document

    assert document.valid?
    assert document.processing?
    assert_equal({}, document.extracted_data)
  end

  test "only allows known statuses" do
    assert_not build_document(status: "finished").valid?
  end

  test "only allows the vendor and buyer steps" do
    assert_not build_document(step: "chain").valid?
  end

  test "needs a filename" do
    assert_not build_document(filename: "").valid?
  end

  test "stores the extracted details as a Hash" do
    document = build_document(extracted_data: { "first_name" => "Tunde" })
    document.save!

    # read the row back from the database proving the Hash was really stored in the jsonb column
    assert_equal "Tunde", document.reload.extracted_data["first_name"]
  end

  test "is stuck when still processing after a while" do
    document = build_document
    document.save!

    travel 3.minutes do
      assert document.stuck?
    end
  end

  test "is not stuck when new or finished" do
    document = build_document
    document.save!

    assert_not document.stuck?
    document.update!(status: "done")
    travel 3.minutes do
      assert_not document.stuck?
    end
  end
end
