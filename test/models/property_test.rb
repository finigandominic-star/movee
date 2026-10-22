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
    assert prop.errors.added?(:house_number, :blank)
    assert prop.errors.added?(:street, :blank)
    assert prop.errors.added?(:post_code, :blank)
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

  test "sold follows the property's transactions" do
    user = User.create!(user_name: "sold_agent", email: "sold_agent@example.com", password: "Password123")
    property = Property.create!(user: user, house_number: "1", street: "Status Street", post_code: "LS7 7GG")
    buyer = InvolvedParty.create!(user: user, first_name: "Sam", last_name: "Buyer", email: "sam@example.com",
                                  phone: "+44 7700 900555", buyer: true)

    sale = Transaction.create!(user: user, property: property, legal_stage: "offer_accepted")
    assert_not property.reload.sold?, "no buyer and not yet in conveyancing: still for sale"

    sale.update!(involved_party: buyer)
    assert property.reload.sold?, "a buyer is attached"

    sale.update!(involved_party: nil, legal_stage: "solicitors_instructed")
    assert property.reload.sold?, "conveyancing has started"

    sale.destroy!
    assert_not property.reload.sold?, "no transactions left"
  end

   test "by_address sorts by street, then house number as a number" do
    ten_b = Property.create!(user: @user, house_number: "10B", street: "Acacia Avenue", post_code: "LS1 1AA")
    ten = Property.create!(user: @user, house_number: "10", street: "Acacia Avenue", post_code: "LS1 1AA")
    two = Property.create!(user: @user, house_number: "2", street: "Acacia Avenue", post_code: "LS1 1AA")
    baker = Property.create!(user: @user, house_number: "1", street: "Baker Street", post_code: "NW1 6XE")

    sorted = Property.where(id: [ten_b, ten, two, baker]).by_address

    assert_equal [two, ten, ten_b, baker], sorted.to_a
  end
end
