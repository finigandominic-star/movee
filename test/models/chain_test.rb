require "test_helper"

class ChainTest < ActiveSupport::TestCase
  def setup
    @agent = User.create!(
      user_name: "chain_tester",
      email: "chaintester@example.com",
      password: "Password123"
    )

    # First-time buyer (buyer only, no home to sell)
    @ftb = InvolvedParty.create!(
      first_name: "Fiona",
      last_name: "FirstTime",
      email: "ftb@example.com",
      phone: "+44 7700 900111",
      buyer: true,
      seller: false
    )

    # Middle mover (both seller and buyer)
    @middle_mover = InvolvedParty.create!(
      first_name: "Mick",
      last_name: "Middleton",
      email: "mick@example.com",
      phone: "+44 7700 900222",
      buyer: true,
      seller: true,
      onward_purchase: "buying"
    )

    # Vendor leaving the market (seller only, no onward chain)
    @market_exit = InvolvedParty.create!(
      first_name: "Edward",
      last_name: "Exit",
      email: "exit@example.com",
      phone: "+44 7700 900333",
      buyer: false,
      seller: true,
      onward_purchase: "leaving_market"
    )

    # Properties
    @prop1 = Property.create!(
      user: @agent,
      house_number: "1",
      street: "First Street",
      post_code: "SW1 1AA",
      involved_party: @middle_mover
    )

    @prop2 = Property.create!(
      user: @agent,
      house_number: "2",
      street: "Second Street",
      post_code: "SW1 2BB",
      involved_party: @market_exit
    )
  end

  test "ordered_transactions links transactions along buyer-seller relationships" do
    chain = Chain.create!(user: @agent)

    # Tx 1: FTB Fiona buys Property 1 from Mick Middleton
    tx1 = Transaction.create!(
      chain: chain,
      property: @prop1,
      involved_party: @ftb,
      user: @agent,
      completed: false
    )

    # Tx 2: Mick Middleton buys Property 2 from Edward Exit
    tx2 = Transaction.create!(
      chain: chain,
      property: @prop2,
      involved_party: @middle_mover,
      user: @agent,
      completed: false
    )

    ordered = chain.ordered_transactions
    assert_equal 2, ordered.size
    assert_equal tx1, ordered.first
    assert_equal tx2, ordered.last
    assert_equal tx1, chain.start_transaction
    assert_equal tx2, chain.end_transaction
  end

  test "boundary rules: first_time_buyer_at_start and leaving_market_at_end" do
    chain = Chain.create!(user: @agent)

    tx1 = Transaction.create!(
      chain: chain,
      property: @prop1,
      involved_party: @ftb,
      user: @agent,
      completed: false
    )

    tx2 = Transaction.create!(
      chain: chain,
      property: @prop2,
      involved_party: @middle_mover,
      user: @agent,
      completed: false
    )

    assert chain.first_time_buyer_at_start?
    assert chain.leaving_market_at_end?
    assert chain.both_ends_closed?
  end

  test "chain remains open if bottom buyer is not a first-time buyer" do
    chain = Chain.create!(user: @agent)

    # Buyer has a home to sell (not an FTB)
    tx = Transaction.create!(
      chain: chain,
      property: @prop2,
      involved_party: @middle_mover,
      user: @agent,
      completed: true
    )

    assert_not chain.first_time_buyer_at_start?
    assert chain.leaving_market_at_end?
    assert_not chain.both_ends_closed?
    # Even though all transactions are completed, chain is open because bottom is unclosed
    assert chain.chain_open?
    assert_not chain.chain_completed?
  end

  test "chain remains open if top vendor is not leaving the property market" do
    chain = Chain.create!(user: @agent)

    # Vendor is Mick Middleton (seller & buyer -> buying onward)
    tx = Transaction.create!(
      chain: chain,
      property: @prop1,
      involved_party: @ftb,
      user: @agent,
      completed: true
    )

    assert chain.first_time_buyer_at_start?
    assert_not chain.leaving_market_at_end?
    assert_not chain.both_ends_closed?
    # Even though transaction is completed, chain is open because top vendor has onward chain
    assert chain.chain_open?
    assert_not chain.chain_completed?
  end

  test "chain completes when both ends are closed and all transactions are completed" do
    chain = Chain.create!(user: @agent)

    tx1 = Transaction.create!(
      chain: chain,
      property: @prop1,
      involved_party: @ftb,
      user: @agent,
      completed: true,
      legal_stage: "completion"
    )

    tx2 = Transaction.create!(
      chain: chain,
      property: @prop2,
      involved_party: @middle_mover,
      user: @agent,
      completed: true,
      legal_stage: "completion"
    )

    assert chain.both_ends_closed?
    assert chain.all_transactions_completed?
    assert chain.chain_completed?
    assert_not chain.chain_open?
    assert_equal false, chain.active?
  end

  test "Chain.merge! enforces lowest ID wins regardless of argument order" do
    chain_low = Chain.create!(user: @agent)
    chain_high = Chain.create!(user: @agent)
    assert chain_low.id < chain_high.id

    tx1 = Transaction.create!(chain: chain_low, property: @prop1, user: @agent)
    tx2 = Transaction.create!(chain: chain_high, property: @prop2, user: @agent)

    # Merge with (higher, lower)
    winner = Chain.merge!(chain_high, chain_low)

    assert_equal chain_low.id, winner.id
    assert Chain.exists?(chain_low.id)
    assert_not Chain.exists?(chain_high.id)

    # Both transactions are now in chain_low
    assert_equal 2, winner.transactions.count
    assert_equal winner.id, tx1.reload.chain_id
    assert_equal winner.id, tx2.reload.chain_id
  end

  test "sync_status! updates active boolean based on open vs completed" do
    chain = Chain.create!(user: @agent)

    tx = Transaction.create!(
      chain: chain,
      property: @prop1,
      involved_party: @ftb,
      user: @agent,
      completed: false
    )

    chain.sync_status!
    assert_equal true, chain.reload.active?

    # Now make it a completed closed chain
    prop_exit = Property.create!(
      user: @agent,
      house_number: "99",
      street: "End Lane",
      post_code: "NW1 1AA",
      involved_party: @market_exit
    )
    tx.update!(property: prop_exit, completed: true, legal_stage: "completion")

    assert chain.reload.chain_completed?
    assert_equal false, chain.active?
  end

  test "connect_property! automatically merges chains under lowest ID when property is in another chain" do
    chain_low = Chain.create!(user: @agent)
    chain_high = Chain.create!(user: @agent)
    assert chain_low.id < chain_high.id

    # chain_low has Property 1
    Transaction.create!(chain: chain_low, property: @prop1, user: @agent)

    # chain_high has Property 2
    Transaction.create!(chain: chain_high, property: @prop2, user: @agent)

    # User connects Property 2 to chain_low (searching by property, not chain ID!)
    surviving = chain_low.connect_property!(@prop2, position: :top, current_user: @agent)

    assert_equal chain_low.id, surviving.id
    assert Chain.exists?(chain_low.id)
    assert_not Chain.exists?(chain_high.id)
    assert_equal 2, surviving.transactions.count
  end

  test "connect_property! creates a new linking transaction when property is unchained" do
    chain = Chain.create!(user: @agent)
    Transaction.create!(chain: chain, property: @prop1, involved_party: @ftb, user: @agent)

    unchained_prop = Property.create!(
      user: @agent,
      house_number: "50",
      street: "Unchained Way",
      post_code: "B1 1AA",
      involved_party: @market_exit
    )

    assert_difference("Transaction.count", 1) do
      chain.connect_property!(unchained_prop, position: :top, current_user: @agent)
    end

    assert_equal 2, chain.transactions.count
    assert_equal unchained_prop, chain.end_transaction.property
  end
end
