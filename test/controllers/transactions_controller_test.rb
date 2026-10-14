require "test_helper"

class TransactionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "tx_tester",
      email: "txtester@example.com",
      password: "Password123"
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
  end

  test "should get show" do
    get transaction_url(@transaction)
    assert_response :success
    assert_select "h1", text: /Transaction ##{@transaction.id}/
  end

  test "should get new with prefilled query parameters" do
    get new_transaction_url(property_id: @property.id, chain_id: @chain.id)
    assert_response :success
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
end
