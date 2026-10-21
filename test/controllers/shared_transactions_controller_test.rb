require "test_helper"

class SharedTransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = User.create!(email: "agent@example.com", user_name: "Agent", password: "Password123", company: "Elm Estates")
    property = Property.create!(house_number: "12", street: "Elm Rd", city: "Bristol", post_code: "BS1 1AA", user: @agent)
    @transaction = Transaction.create!(property: property, user: @agent)
    @buyer = InvolvedParty.create!(first_name: "Jamie", last_name: "Secretname", email: "jamie@example.com", phone: "07700900000", buyer: true, onward_purchase: "undecided")
    @transaction.update!(involved_party: @buyer)
  end

  test "a valid, unexpired link shows only the stage and agent, never the buyer's name" do
    link = TransactionShareLink.create_for!(@transaction, user: @agent, duration: "1h")

    get shared_transaction_path(link.token)

    assert_response :success
    assert_select "body", text: /#{@transaction.legal_stage_short_title}/
    assert_match @agent.email, response.body
    assert_no_match(/Secretname/, response.body)
    assert_no_match(/Advance to stage/, response.body)
    assert_no_match(/Change stage/, response.body)
    assert_no_match(/Share status with client/, response.body)
  end

  test "the stage controls stay hidden even when the browser has an admin's own session" do
    admin = User.create!(email: "admin@example.com", user_name: "Admin", password: "Password123", admin: true)
    link = TransactionShareLink.create_for!(@transaction, user: @agent, duration: "1h")

    sign_in admin
    get shared_transaction_path(link.token)

    assert_response :success
    assert_no_match(/Advance to stage/, response.body)
    assert_no_match(/Change stage/, response.body)
    assert_no_match(/Share status with client/, response.body)
  end

  test "an expired link renders the expired page with 404" do
    link = TransactionShareLink.create_for!(@transaction, user: @agent, duration: "30m")
    link.update!(expires_at: 1.minute.ago)

    get shared_transaction_path(link.token)

    assert_response :not_found
    assert_select "h1", text: /expired/i
  end

  test "an unknown token renders the expired page with 404" do
    get shared_transaction_path("not-a-real-token")

    assert_response :not_found
  end
end
