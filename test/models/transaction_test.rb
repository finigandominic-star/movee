require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      user_name: "tx_agent",
      email: "tx_agent@example.com",
      password: "Password123"
    )
    @property = Property.create!(
      user: @user,
      house_number: "7",
      street: "Green Way",
      post_code: "SW1A 1AA"
    )
    @chain = Chain.create!(active: true)
    @party = InvolvedParty.create!(
      first_name: "Tom",
      last_name: "Clark",
      email: "tom.clark@example.com",
      phone: "+44 7700 900555",
      buyer: true
    )
  end

  test "valid transaction with chain and property" do
    tx = Transaction.new(
      chain: @chain,
      property: @property,
      involved_party: @party,
      completed: false
    )
    assert tx.valid?, tx.errors.full_messages.to_sentence
    assert_equal "In Progress", tx.status_label
    assert_equal "bg-warning text-dark", tx.status_badge_class
  end

  test "completed status formatting" do
    tx = Transaction.new(
      chain: @chain,
      property: @property,
      completed: true
    )
    assert_equal "Completed", tx.status_label
    assert_equal "bg-success", tx.status_badge_class
  end

  test "scopes completed and pending" do
    tx1 = Transaction.create!(chain: @chain, property: @property, completed: true)
    tx2 = Transaction.create!(chain: @chain, property: @property, completed: false)

    assert_includes Transaction.completed, tx1
    assert_not_includes Transaction.completed, tx2

    assert_includes Transaction.pending, tx2
    assert_not_includes Transaction.pending, tx1
  end

  test "optional involved_party" do
    tx = Transaction.create!(chain: @chain, property: @property, involved_party: nil)
    assert tx.valid?
    assert_nil tx.involved_party
  end
end
