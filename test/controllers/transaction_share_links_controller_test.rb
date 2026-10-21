require "test_helper"

class TransactionShareLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @agent = User.create!(email: "agent@example.com", user_name: "Agent", password: "Password123")
    @other_agent = User.create!(email: "other@example.com", user_name: "Other Agent", password: "Password123")

    property = Property.create!(house_number: "12", street: "Elm Rd", city: "Bristol", post_code: "BS1 1AA", user: @agent)
    @transaction = Transaction.create!(property: property, user: @agent)
  end

  test "the listing agent can generate a share link for a chosen duration" do
    sign_in @agent

    assert_difference "TransactionShareLink.count", 1 do
      post transaction_share_links_path(@transaction), params: { duration: "1h" }
    end

    link = TransactionShareLink.last
    assert_equal @transaction, link.deal
    assert_equal @agent, link.user
    assert_in_delta 1.hour.from_now, link.expires_at, 5.seconds
    assert_redirected_to transaction_path(@transaction)
  end

  test "an unrelated agent cannot generate a share link" do
    sign_in @other_agent

    assert_no_difference "TransactionShareLink.count" do
      post transaction_share_links_path(@transaction), params: { duration: "1h" }
    end

    assert_redirected_to root_path
  end

  test "an invalid duration is rejected without creating a link" do
    sign_in @agent

    assert_no_difference "TransactionShareLink.count" do
      post transaction_share_links_path(@transaction), params: { duration: "3 weeks" }
    end
  end
end
