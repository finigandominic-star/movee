require "test_helper"

class InvolvedPartiesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "party_agent",
      email: "party_agent@example.com",
      password: "Password123"
    )
    @party = InvolvedParty.create!(
      user: @user,
      first_name: "Diana",
      last_name: "Prince",
      email: "diana@themyscira.com",
      phone: "+44 7700 900888",
      buyer: true,
      seller: false
    )
    @property = Property.create!(
      user: @user,
      house_number: "1",
      street: "Gateway",
      post_code: "EC1A 1BB"
    )
    @chain = Chain.create!(active: true)
    @transaction = Transaction.create!(
      property: @property,
      chain: @chain,
      completed: false
    )
    sign_in @user
  end

  test "should get index" do
    get involved_parties_url
    assert_response :success
    assert_select "h1", text: /Involved Parties/i
  end

  test "should get show" do
    get involved_party_url(@party)
    assert_response :success
    assert_select "h1", text: /Diana Prince/
  end

  test "should get new" do
    get new_involved_party_url
    assert_response :success
  end

  test "should create involved party" do
    assert_difference("InvolvedParty.count") do
      post involved_parties_url, params: {
        involved_party: {
          first_name: "Clark",
          last_name: "Kent",
          email: "clark@dailyplanet.com",
          phone: "+44 7700 900999",
          buyer: true,
          seller: true
        }
      }
    end
    created_party = InvolvedParty.order(created_at: :desc).first
    assert_redirected_to involved_party_url(created_party)
    assert_equal "Clark Kent", created_party.full_name
  end

  test "should get edit" do
    get edit_involved_party_url(@party)
    assert_response :success
  end

  test "should update involved party" do
    patch involved_party_url(@party), params: {
      involved_party: {
        contact_info: "Prefers morning calls"
      }
    }
    assert_redirected_to involved_party_url(@party)
    assert_equal "Prefers morning calls", @party.reload.contact_info
  end

  test "should destroy involved party" do
    assert_difference("InvolvedParty.count", -1) do
      delete involved_party_url(@party)
    end
    assert_redirected_to involved_parties_url
  end

  test "should assign and unassign property" do
    # Assign property
    post assign_property_involved_party_url(@party), params: { property_id: @property.id }
    assert_redirected_to involved_party_url(@party)
    assert_equal @party, @property.reload.involved_party

    # Unassign property
    delete unassign_property_involved_party_url(@party, @property)
    assert_redirected_to involved_party_url(@party)
    assert_nil @property.reload.involved_party
  end

  test "should assign and unassign transaction" do
    # Assign transaction
    post assign_transaction_involved_party_url(@party), params: { transaction_id: @transaction.id }
    assert_redirected_to involved_party_url(@party)
    assert_equal @party, @transaction.reload.involved_party

    # Unassign transaction
    delete unassign_transaction_involved_party_url(@party, @transaction)
    assert_redirected_to involved_party_url(@party)
    assert_nil @transaction.reload.involved_party
  end

  test "unassociated user cannot edit or destroy involved party" do
    other_user = User.create!(
      user_name: "other_agent",
      email: "other_agent@example.com",
      password: "Password123"
    )
    sign_in other_user

    get edit_involved_party_url(@party)
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]

    assert_no_difference("InvolvedParty.count") do
      delete involved_party_url(@party)
    end
    assert_redirected_to root_url
  end

  test "admin can edit and destroy any involved party" do
    admin = User.create!(
      user_name: "super_admin",
      email: "admin_ip@example.com",
      password: "Password123",
      admin: true
    )
    sign_in admin

    get edit_involved_party_url(@party)
    assert_response :success

    assert_difference("InvolvedParty.count", -1) do
      delete involved_party_url(@party)
    end
    assert_redirected_to involved_parties_url
  end
end
