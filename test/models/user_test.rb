require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with required fields, company, and phone" do
    user = User.new(
      user_name: "test_agent",
      email: "agent@example.com",
      password: "Password1",
      company: "Prime Agency",
      phone: "+44 20 7946 0555"
    )
    assert user.valid?, user.errors.full_messages.to_sentence
    assert_equal "Prime Agency", user.company
    assert_equal "+44 20 7946 0555", user.phone
  end

  test "user without user_name is invalid" do
    user = User.new(
      email: "agent@example.com",
      password: "Password1",
      company: "Prime Agency"
    )
    assert_not user.valid?
    assert_includes user.errors[:user_name], "can't be blank"
  end

  test "password requires at least 8 characters with both letters and numbers" do
    user = User.new(
      user_name: "test_user",
      email: "user@example.com",
      password: "12345"
    )
    assert_not user.valid?

    user.password = "123456" # under 8 chars, no letters
    assert_not user.valid?

    user.password = "password" # no digits
    assert_not user.valid?

    user.password = "12345678" # no letters
    assert_not user.valid?

    user.password = "Password123" # valid: 8+ chars, letters and digits
    assert user.valid?
  end

  test "admin attribute defaults to false and can be set to true" do
    user = User.new(user_name: "standard", email: "std@example.com", password: "Password123")
    assert_equal false, user.admin?

    user.admin = true
    assert_equal true, user.admin?
  end

  test "destroying user destroys their properties" do
    user = User.create!(
      user_name: "owner",
      email: "owner@example.com",
      password: "Password1"
    )
    property = Property.create!(
      user: user,
      house_number: "10",
      street: "High Street",
      post_code: "SW1A 1AA"
    )

    assert_difference("Property.count", -1) do
      user.destroy
    end
  end
end
