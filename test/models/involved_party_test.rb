require "test_helper"

class InvolvedPartyTest < ActiveSupport::TestCase
  test "valid involved party with required attributes" do
    party = InvolvedParty.new(
      first_name: "Alice",
      last_name: "Smith",
      email: "alice@example.com",
      phone: "+44 7700 900222",
      buyer: true,
      seller: false
    )
    assert party.valid?, party.errors.full_messages.to_sentence
    assert_equal "Alice Smith", party.full_name
    assert_equal "Buyer", party.roles_label
  end

  test "requires first_name, last_name, email, and phone" do
    party = InvolvedParty.new
    assert_not party.valid?
    assert_includes party.errors[:first_name], "can't be blank"
    assert_includes party.errors[:last_name], "can't be blank"
    assert_includes party.errors[:email], "can't be blank"
    assert_includes party.errors[:phone], "can't be blank"
  end

  test "enforces unique email and phone" do
    InvolvedParty.create!(
      first_name: "Bob",
      last_name: "Jones",
      email: "bob@example.com",
      phone: "+44 7700 900333"
    )

    duplicate_email = InvolvedParty.new(
      first_name: "Robert",
      last_name: "Jones",
      email: "bob@example.com",
      phone: "+44 7700 900444"
    )
    assert_not duplicate_email.valid?
    assert_includes duplicate_email.errors[:email], "has already been taken"

    duplicate_phone = InvolvedParty.new(
      first_name: "Robert",
      last_name: "Jones",
      email: "robert@example.com",
      phone: "+44 7700 900333"
    )
    assert_not duplicate_phone.valid?
    assert_includes duplicate_phone.errors[:phone], "has already been taken"
  end

  test "roles_label shows Buyer / Seller when both are true" do
    party = InvolvedParty.new(buyer: true, seller: true)
    assert_equal "Seller / Buyer", party.roles_label

    contact = InvolvedParty.new(buyer: false, seller: false)
    assert_equal "Contact", contact.roles_label
  end

  test "a new seller's onward plans default to undecided and do not close a chain" do
    party = InvolvedParty.new(seller: true)
    assert_equal "undecided", party.onward_purchase
    assert_not party.leaving_market?
  end

  test "only an explicit leaving_market seller is leaving the market" do
    assert InvolvedParty.new(seller: true, onward_purchase: "leaving_market").leaving_market?
    assert_not InvolvedParty.new(seller: false, onward_purchase: "leaving_market").leaving_market?
  end

  test "buying onward marks the client as a buyer" do
    party = InvolvedParty.new(first_name: "A", last_name: "B", email: "ab@example.com", phone: "+44 7700 900999", seller: true, onward_purchase: "buying")
    party.valid?
    assert party.buyer?
  end

  test "rejects unknown onward plans" do
    party = InvolvedParty.new(onward_purchase: "maybe")
    party.valid?
    assert party.errors[:onward_purchase].any?
  end
end
