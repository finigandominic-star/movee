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
    assert_equal "offer_accepted", tx.legal_stage
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

  test "default legal stage is offer_accepted" do
    tx = Transaction.create!(chain: @chain, property: @property)
    assert_equal "offer_accepted", tx.legal_stage
    assert_equal 1, tx.legal_stage_index
    assert_equal "Offer Accepted & Sales Memo", tx.legal_stage_title
    assert_equal "Offer Accepted", tx.legal_stage_short_title
    assert_equal 13, tx.legal_stage_percentage
    assert_not_nil tx.legal_stage_definition[:tooltip]
    assert_not_nil tx.legal_stage_definition[:agent_action]
  end

  test "validates inclusion of legal_stage" do
    tx = Transaction.new(chain: @chain, property: @property, legal_stage: "invalid_stage")
    assert_not tx.valid?
    assert_includes tx.errors[:legal_stage], "is not included in the list"
  end

  test "advancing and rolling back legal stages" do
    tx = Transaction.create!(chain: @chain, property: @property, legal_stage: "offer_accepted")
    assert_equal "solicitors_instructed", tx.next_legal_stage
    assert_nil tx.previous_legal_stage

    tx.advance_stage!
    assert_equal "solicitors_instructed", tx.legal_stage
    assert_equal "draft_contract_pack", tx.next_legal_stage
    assert_equal "offer_accepted", tx.previous_legal_stage

    tx.rollback_stage!
    assert_equal "offer_accepted", tx.legal_stage
  end

  test "marking completion automatically sets completed boolean to true" do
    tx = Transaction.create!(chain: @chain, property: @property, legal_stage: "exchange_of_contracts")
    assert_not tx.completed?

    tx.update!(legal_stage: "completion")
    assert tx.completed?
    assert_equal 100, tx.legal_stage_percentage
  end

  test "marking completed true synchronizes legal stage to completion" do
    tx = Transaction.create!(chain: @chain, property: @property, completed: false)
    assert_equal "offer_accepted", tx.legal_stage

    tx.update!(completed: true)
    assert_equal "completion", tx.legal_stage
  end

  test "rolling back from completion sets completed to false" do
    tx = Transaction.create!(chain: @chain, property: @property, completed: true)
    assert_equal "completion", tx.legal_stage

    tx.update!(legal_stage: "exchange_of_contracts")
    assert_not tx.completed?
  end

  test "legal stage helper predicates" do
    tx = Transaction.create!(chain: @chain, property: @property, legal_stage: "searches_and_enquiries")
    assert tx.legal_stage_completed?("offer_accepted")
    assert tx.legal_stage_completed?("solicitors_instructed")
    assert tx.legal_stage_completed?("draft_contract_pack")
    assert tx.legal_stage_completed?("searches_and_enquiries")
    assert_not tx.legal_stage_completed?("exchange_of_contracts")
    assert_not tx.legal_stage_completed?("completion")

    assert tx.legal_stage_current?("searches_and_enquiries")
    assert_not tx.legal_stage_current?("offer_accepted")
  end

  test "stage estimation based on creation and target completion date" do
    start_date = Date.current - 20.days
    target_comp = start_date + 84.days
    tx = Transaction.create!(
      chain: @chain,
      property: @property,
      created_at: start_date.beginning_of_day,
      estimated_completion_date: target_comp
    )

    assert_equal start_date + 3.days, tx.stage_estimated_date("offer_accepted")
    assert_equal start_date + 14.days, tx.stage_estimated_date("solicitors_instructed")
    assert_equal start_date + 42.days, tx.stage_estimated_date("searches_and_enquiries")
    assert_equal target_comp, tx.stage_estimated_date("completion")
  end

  test "timing status for ahead, on-target, and behind stages" do
    start_date = Date.current - 30.days
    tx = Transaction.create!(
      chain: @chain,
      property: @property,
      created_at: start_date.beginning_of_day,
      legal_stage: "draft_contract_pack",
      stage_dates: {
        "offer_accepted" => {
          "estimated_date" => (start_date + 3.days).to_s,
          "actual_date" => (start_date + 1.day).to_s
        },
        "solicitors_instructed" => {
          "estimated_date" => (start_date + 14.days).to_s,
          "actual_date" => (start_date + 14.days).to_s
        },
        "draft_contract_pack" => {
          "estimated_date" => (start_date + 21.days).to_s,
          "actual_date" => nil
        }
      }
    )

    timing_s1 = tx.stage_timing("offer_accepted")
    assert_equal :ahead, timing_s1[:status]
    assert_match(/2d ahead/i, timing_s1[:label])
    assert_equal 2, timing_s1[:days]

    timing_s2 = tx.stage_timing("solicitors_instructed")
    assert_equal :on_target, timing_s2[:status]
    assert_equal "On target", timing_s2[:label]

    timing_s3 = tx.stage_timing("draft_contract_pack")
    assert_equal :overdue, timing_s3[:status]
    assert_match(/behind target/i, timing_s3[:full_label])
    assert timing_s3[:days] > 0
    assert_equal timing_s3[:days], timing_s3[:days_over]

    overall = tx.overall_timing_status
    assert_equal :behind, overall[:status]
    assert overall[:days] > 0
    assert_equal overall[:days], overall[:days_over]
  end

  test "set_legal_stage_with_timing! records actual approval date" do
    tx = Transaction.create!(chain: @chain, property: @property, legal_stage: "offer_accepted")
    approval_d = Date.current - 1.day
    tx.set_legal_stage_with_timing!("solicitors_instructed", approval_d)

    assert_equal "solicitors_instructed", tx.legal_stage
    assert_equal approval_d, tx.stage_actual_date("offer_accepted")
  end
end
