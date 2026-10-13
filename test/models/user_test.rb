require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user with required fields and company" do
    user = User.new(
      user_name: "test_agent",
      email: "agent@example.com",
      password: "Password1",
      company: "Prime Agency"
    )
    assert user.valid?, user.errors.full_messages.to_sentence
    assert_equal "Prime Agency", user.company
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

  test "password requires letters and numbers and at least 8 chars" do
    user = User.new(
      user_name: "test_user",
      email: "user@example.com",
      password: "short1"
    )
    assert_not user.valid?

    user.password = "onlyletters"
    assert_not user.valid?

    user.password = "ValidPass123"
    assert user.valid?
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
