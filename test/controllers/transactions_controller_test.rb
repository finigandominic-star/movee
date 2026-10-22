require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "tx_tester",
      email: "txtester@example.com",
      password: "Password123",
      phone: "+44 20 7946 0002"
    )
    @party = InvolvedParty.create!(
      first_name: "Bruce",
      last_name: "Wayne",
      email: "bruce@wayne.com",
      phone: "+44 7700 900777",
      buyer: true
    )
    @property = Property.create!(
      user: @user,
      house_number: "1007",
      street: "Mountain Drive",
      post_code: "NW1 1AA"
    )
    @chain = Chain.create!(active: true)
    @transaction = Transaction.create!(
      user: @user,
      property: @property,
      chain: @chain,
      involved_party: @party,
      completed: false
    )
    sign_in @user
  end

  test "should get index" do
    get transactions_url
    assert_response :success
    assert_select "h1", text: /Transactions/i
    assert_select "a[href=?]", user_path(@user)
    assert_select "a[href='mailto:#{@user.email}']", count: 0
  end

  test "should get show" do
    get transaction_url(@transaction)
    assert_response :success
    assert_select "h1", text: /#{Regexp.escape(@property.short_address)}/
    assert_select ".page-subtitle", text: /Chain:|Transaction #/, count: 0
    # Managing agent card shows name and company only; contact details live on the agent's profile
    assert_select "a[href=?]", user_path(@user)
    assert_select "a[href='mailto:#{@user.email}']", count: 0
    assert_select "a[href='tel:#{@user.phone}']", count: 0
  end

  test "should get new with prefilled query parameters" do
    get new_transaction_url(property_id: @property.id, chain_id: @chain.id)
    assert_response :success
  end

  test "creating a transaction for a property that has one updates it instead" do
    @transaction.update!(involved_party: nil)
    assert_no_difference "Transaction.count" do
      post transactions_url, params: { transaction: { property_id: @property.id, chain_id: @chain.id,
                                                      involved_party_id: @party.id, legal_stage: "offer_accepted" } }
    end
    assert_redirected_to transaction_url(@transaction)
    assert_equal @party, @transaction.reload.involved_party
  end

  test "should create transaction" do
    new_prop = Property.create!(
      user: @user,
      house_number: "50",
      street: "Fleet Street",
      post_code: "EC4A 2BE"
    )
    assert_difference("Transaction.count") do
      post transactions_url, params: {
        transaction: {
          property_id: new_prop.id,
          chain_id: @chain.id,
          involved_party_id: @party.id,
          completed: false
        }
      }
    end
    created_tx = Transaction.order(created_at: :desc).first
    assert_redirected_to transaction_url(created_tx)
  end

  test "should get edit" do
    get edit_transaction_url(@transaction)
    assert_response :success
  end

  test "should update transaction status" do
    patch transaction_url(@transaction), params: {
      transaction: {
        completed: true
      }
    }
    assert_redirected_to transaction_url(@transaction)
    assert_equal true, @transaction.reload.completed
  end

  test "should destroy transaction" do
    assert_difference("Transaction.count", -1) do
      delete transaction_url(@transaction)
    end
    assert_redirected_to transactions_url
  end

  test "should remove involved party from transaction" do
    assert_equal @party, @transaction.involved_party
    delete remove_involved_party_transaction_url(@transaction)
    assert_redirected_to transaction_url(@transaction)
    assert_nil @transaction.reload.involved_party
  end

  test "unassociated user cannot destroy transaction" do
    other_user = User.create!(
      user_name: "other_tx_agent",
      email: "othertx@example.com",
      password: "Password123"
    )
    sign_in other_user

    assert_no_difference("Transaction.count") do
      delete transaction_url(@transaction)
    end
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
  end

  test "should update transaction legal stage via update_stage" do
    patch update_stage_transaction_url(@transaction), params: {
      legal_stage: "searches_and_enquiries"
    }
    assert_redirected_to transaction_url(@transaction)
    assert_equal "searches_and_enquiries", @transaction.reload.legal_stage
    assert_match(/Legal conveyancing stage updated to/i, flash[:notice])
  end

  test "should update legal stage via standard update" do
    patch transaction_url(@transaction), params: {
      transaction: {
        legal_stage: "exchange_of_contracts"
      }
    }
    assert_redirected_to transaction_url(@transaction)
    assert_equal "exchange_of_contracts", @transaction.reload.legal_stage
  end

  test "should reject invalid legal stage in update_stage" do
    patch update_stage_transaction_url(@transaction), params: {
      legal_stage: "invalid_mystery_stage"
    }
    assert_redirected_to transaction_url(@transaction)
    assert_equal "offer_accepted", @transaction.reload.legal_stage
    assert_equal "Invalid legal stage selected.", flash[:alert]
  end

  test "unassociated user cannot update legal stage" do
    other_user = User.create!(
      user_name: "unauth_agent",
      email: "unauth_agent@example.com",
      password: "Password123"
    )
    sign_in other_user

    patch update_stage_transaction_url(@transaction), params: {
      legal_stage: "draft_contract_pack"
    }
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]
    assert_equal "offer_accepted", @transaction.reload.legal_stage
  end

  test "show page renders conveyancing stages and tooltips" do
    get transaction_url(@transaction)
    assert_response :success
    assert_select ".conveyancing-pipeline"
    assert_select "[data-bs-toggle='tooltip']"
    assert_select ".active-stage-card"
    assert_select "h5", text: /UK Conveyancing Legal Stages/i
  end

  test "transaction index does not include completed or in progress status tags and shows visual stage schedule" do
    get transactions_url
    assert_response :success

    # Column header is Stage & Schedule
    assert_select "th", text: /Stage & Schedule/

    # No seller/buyer tags
    assert_select ".badge", text: "Seller", count: 0
    assert_select ".badge", text: "Buyer", count: 0

    # Stage short title and timing indicators present
    assert_select ".badge", text: /Offer Agreed|Offer Accepted/
  end

  test "transaction show removes duplicate transaction summary and in-progress status badge and houses legal details in modal" do
    get transaction_url(@transaction)
    assert_response :success

    # Duplicate summary card removed
    assert_select ".card-title", text: /Transaction Summary/, count: 0

    # No redundant status badge in header
    assert_select ".h2 + .badge", text: /In Progress/, count: 0

    # Modal popup exists for legal details
    assert_select "#legalExplainerModal"
    assert_select "#legalExplainerModal .modal-title", text: /UK Conveyancing Guide/

    # No seller/buyer tags
    assert_select ".badge", text: "Seller", count: 0
    assert_select ".badge", text: "Buyer", count: 0
  end

  test "overdue transaction displays red pill with exact number of days over in index and show" do
    start_date = Date.current - 10.days
    overdue_tx = @transaction
    overdue_tx.update!(
      legal_stage: "offer_accepted",
      created_at: start_date.beginning_of_day,
      estimated_completion_date: start_date + 84.days,
      stage_dates: {
        "offer_accepted" => {
          "estimated_date" => (start_date + 3.days).to_s,
          "actual_date" => nil
        }
      }
    )
    # Target was 7 days ago. Overdue by 7 days.
    timing = overdue_tx.overall_timing_status
    assert_equal :behind, timing[:status]
    assert_equal 7, timing[:days_over]

    # Check transactions index
    get transactions_url
    assert_response :success
    assert_select ".badge.bg-danger", text: /\+7d Over/

    # Check transaction show
    get transaction_url(overdue_tx)
    assert_response :success
    assert_select ".badge.bg-danger", text: /\+7d Over/
  end
end
