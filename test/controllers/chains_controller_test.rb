require "test_helper"

class ChainsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "chain_agent",
      email: "chain_agent@example.com",
      password: "Password123",
      phone: "+44 20 7946 0004"
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
    assert_select "h1", text: /Chains/
  end

  test "should get show" do
    get chain_url(@chain)
    assert_response :success
    assert_select "h1", text: /Wallaby Way/
    assert_select ".page-subtitle", text: /Chain ##{@chain.id}/
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

  test "nickname replaces the address-based chain name" do
    patch chain_url(@chain), params: { chain: { name: "  Holmes chain  " } }
    assert_equal "Holmes chain", @chain.reload.name

    get chain_url(@chain)
    assert_select "h1", text: "Holmes chain"

    patch chain_url(@chain), params: { chain: { name: "" } }
    assert_nil @chain.reload.name
  end

  test "index defaults to table view with a transaction flow per chain" do
    get chains_url
    assert_select "#table-view.active .chain-flow a[href='#{transaction_path(@transaction)}']", text: /42 Wallaby Way/
  end

  test "index shows who manages a chain the viewer cannot edit" do
    other = User.create!(user_name: "other_agent", email: "other_agent@example.com", password: "Password123")
    sign_in other
    get chains_url
    assert_select ".chain-locked", text: /Managed by chain_agent/
    assert_select "a[href='#{edit_chain_path(@chain)}']", count: 0
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
    assert_select "a[href='mailto:#{@user.email}']"
    assert_select "a[href='tel:#{@user.phone}']"
    # The client personal data is protected:
    assert_select "span", text: /Client Confidential/
    assert_no_match @party.email, response.body
    assert_no_match @party.phone, response.body
  end

  test "should merge chains inheriting the lowest id" do
    other_chain = Chain.create!(user: @user, active: true)
    other_prop = Property.create!(
      user: @user,
      house_number: "99",
      street: "Merge Street",
      post_code: "M1 1AA"
    )
    other_tx = Transaction.create!(
      chain: other_chain,
      property: other_prop,
      user: @user
    )

    lowest_id = [@chain.id, other_chain.id].min
    highest_id = [@chain.id, other_chain.id].max

    assert_difference("Chain.count", -1) do
      post merge_chain_url(@chain), params: { target_chain_id: other_chain.id }
    end

    assert_redirected_to chain_url(lowest_id)
    assert Chain.exists?(lowest_id)
    assert_not Chain.exists?(highest_id)
    assert_equal 2, Chain.find(lowest_id).transactions.count
    assert_match(/Inherited lowest ID/i, flash[:notice])
  end

  test "show renders UK chain boundary analysis" do
    get chain_url(@chain)
    assert_response :success
    assert_select "h5", text: /Chain Boundary Analysis/
    assert_select "span", text: /Start of Chain/
    assert_select "span", text: /End of Chain/
  end

  test "connect_property action automatically merges chains when property is in another chain" do
    other_chain = Chain.create!(user: @user, active: true)
    target_prop = Property.create!(
      user: @user,
      house_number: "77",
      street: "Connect Street",
      post_code: "M2 2BB"
    )
    Transaction.create!(chain: other_chain, property: target_prop, user: @user)

    lowest_id = [@chain.id, other_chain.id].min

    assert_difference("Chain.count", -1) do
      post connect_property_chain_url(@chain), params: { property_id: target_prop.id, position: "top" }
    end

    assert_redirected_to chain_url(lowest_id)
    assert_match(/Connected #{target_prop.short_address}/i, flash[:notice])
    assert_equal 2, Chain.find(lowest_id).transactions.count
  end

  test "show renders connect property modal and buttons" do
    get chain_url(@chain)
    assert_response :success
    assert_select "#connectPropertyModal"
    assert_select "button[data-bs-target='#connectPropertyModal']"
  end
end
