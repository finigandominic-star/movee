require "test_helper"

class ChainsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "chain_agent",
      email: "chain_agent@example.com",
      password: "Password123"
    )
    @chain = Chain.create!(
      user: @user,
      active: true
    )
    @property = Property.create!(
      user: @user,
      house_number: "42",
      street: "Wallaby Way",
      post_code: "SY1 1AA"
    )
    @party = InvolvedParty.create!(
      user: @user,
      first_name: "Sherlock",
      last_name: "Holmes",
      email: "sherlock@bakerst.com",
      phone: "+44 7700 900555",
      buyer: true
    )
    @transaction = Transaction.create!(
      user: @user,
      chain: @chain,
      property: @property,
      involved_party: @party,
      completed: false
    )
    sign_in @user
  end

  test "should get index" do
    get chains_url
    assert_response :success
    assert_select "h1", text: /Transaction Chains/i
  end

  test "should get show" do
    get chain_url(@chain)
    assert_response :success
    assert_select "h1", text: /Chain ##{@chain.id}/
  end

  test "should get new" do
    get new_chain_url
    assert_response :success
  end

  test "should create chain" do
    assert_difference("Chain.count") do
      post chains_url, params: {
        chain: { active: true }
      }
    end
    created_chain = Chain.order(created_at: :desc).first
    assert_redirected_to chain_url(created_chain)
    assert_equal @user, created_chain.user
  end

  test "should get edit for creator" do
    get edit_chain_url(@chain)
    assert_response :success
  end

  test "should update chain for creator" do
    patch chain_url(@chain), params: {
      chain: { active: false }
    }
    assert_redirected_to chain_url(@chain)
    assert_equal false, @chain.reload.active?
  end

  test "should destroy chain for creator" do
    assert_difference("Chain.count", -1) do
      delete chain_url(@chain)
    end
    assert_redirected_to chains_url
  end

  test "other user cannot edit, update or destroy chain" do
    other_user = User.create!(
      user_name: "other_chain_agent",
      email: "otherchain@example.com",
      password: "Password123"
    )
    sign_in other_user

    get edit_chain_url(@chain)
    assert_redirected_to root_url
    assert_equal "You are not authorized to perform this action.", flash[:alert]

    patch chain_url(@chain), params: { chain: { active: false } }
    assert_redirected_to root_url

    assert_no_difference("Chain.count") do
      delete chain_url(@chain)
    end
    assert_redirected_to root_url
  end

  test "admin can edit, update and destroy any chain" do
    admin = User.create!(
      user_name: "chain_admin",
      email: "chainadmin@example.com",
      password: "Password123",
      admin: true
    )
    sign_in admin

    get edit_chain_url(@chain)
    assert_response :success

    patch chain_url(@chain), params: { chain: { active: false } }
    assert_redirected_to chain_url(@chain)
    assert_equal false, @chain.reload.active?

    assert_difference("Chain.count", -1) do
      delete chain_url(@chain)
    end
    assert_redirected_to chains_url
  end

  test "in chain show view, agents are visible while non-associated client data is protected" do
    # When viewing as another user not associated with the party
    other_user = User.create!(
      user_name: "external_agent",
      email: "external@example.com",
      password: "Password123"
    )
    sign_in other_user

    get chain_url(@chain)
    assert_response :success
    # The managing agent is visible:
    assert_select "h6", text: @user.user_name
    # The client personal data is protected:
    assert_select "span", text: /Client Confidential/
    assert_no_match @party.email, response.body
    assert_no_match @party.phone, response.body
  end
end
