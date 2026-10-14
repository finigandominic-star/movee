require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      user_name: "property_agent",
      email: "property_agent@example.com",
      password: "Password123"
    )
    @party = InvolvedParty.create!(
      first_name: "Jane",
      last_name: "Doe",
      email: "jane.doe@example.com",
      phone: "+44 7700 900111",
      seller: true
    )
  end

  test "valid property with required attributes" do
    prop = Property.new(
      user: @user,
      house_number: "42",
      street: "Baker Street",
      city: "London",
      post_code: "NW1 6XE"
    )
    assert prop.valid?, prop.errors.full_messages.to_sentence
  end

  test "requires house_number, street, and post_code" do
    prop = Property.new(user: @user)
    assert_not prop.valid?
    assert_includes prop.errors[:house_number], "can't be blank"
    assert_includes prop.errors[:street], "can't be blank"
    assert_includes prop.errors[:post_code], "can't be blank"
  end

  test "full_address and short_address methods" do
    prop = Property.new(
      user: @user,
      house_number: "10",
      street: "Downing Street",
      second_line_of_address: "Westminster",
      city: "London",
      post_code: "SW1A 2AA"
    )
    assert_equal "10 Downing Street, Westminster, London, SW1A 2AA", prop.full_address
    assert_equal "10 Downing Street", prop.short_address
  end

  test "optional involved_party association" do
    prop = Property.create!(
      user: @user,
      house_number: "12",
      street: "Rose Lane",
      post_code: "E1 6AN",
      involved_party: @party
    )
    assert_equal @party, prop.involved_party

    prop.update!(involved_party: nil)
    assert_nil prop.reload.involved_party
  end
end
