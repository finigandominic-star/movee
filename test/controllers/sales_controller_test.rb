require "test_helper"

class SalesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "sale_agent",
      email: "sale_agent@example.com",
      password: "Password123",
      phone: "+44 20 7946 0101"
    )
    @vendor = InvolvedParty.create!(
      user: @user,
      first_name: "Vera",
      last_name: "Vendor",
      email: "vera@example.com",
      phone: "+44 7700 900101",
      seller: true
    )
    @buyer = InvolvedParty.create!(
      user: @user,
      first_name: "Bob",
      last_name: "Buyer",
      email: "bob@example.com",
      phone: "+44 7700 900102",
      buyer: true,
      seller: true
    )
    sign_in @user
  end

  test "new renders the vendor step" do
    get new_sale_url
    assert_response :success
    assert_select "h1", text: "New sale"
    assert_select ".stepper li[aria-current=step]", text: /Vendor/
    assert_select "input[name=existing_id][value=?]", @vendor.id.to_s
  end

  test "creating a new vendor redirects to the property step" do
    assert_difference("InvolvedParty.count") do
      post sale_url, params: {
        step: "vendor",
        involved_party: {
          first_name: "Nina", last_name: "New", email: "nina@example.com", phone: "+44 7700 900103",
          onward_purchase: "leaving_market"
        }
      }
    end
    party = InvolvedParty.order(:id).last
    assert party.seller?
    assert_equal "leaving_market", party.onward_purchase
    assert_equal @user, party.user
    assert_redirected_to new_sale_url(step: "property", vendor_id: party.id)
  end

  test "invalid new vendor re-renders with errors" do
    assert_no_difference("InvolvedParty.count") do
      post sale_url, params: { step: "vendor", involved_party: { first_name: "", last_name: "", email: "", phone: "" } }
    end
    assert_response :unprocessable_entity
    assert_select ".invalid-feedback"
  end

  test "choosing an existing vendor saves their onward plans" do
    post sale_url, params: { step: "vendor", existing_id: @vendor.id, onward_purchase: "buying" }
    assert_redirected_to new_sale_url(step: "property", vendor_id: @vendor.id)
    @vendor.reload
    assert_equal "buying", @vendor.onward_purchase
    assert @vendor.buyer?
  end

  test "happy path creates the transaction and a named chain" do
    post sale_url, params: { step: "vendor", existing_id: @vendor.id }
    assert_redirected_to new_sale_url(step: "property", vendor_id: @vendor.id)
    follow_redirect!
    assert_response :success
    assert_select ".stepper li[aria-current=step]", text: /Property/

    assert_difference("Property.count") do
      post sale_url, params: {
        step: "property", vendor_id: @vendor.id,
        property: { house_number: "7", street: "Acacia Avenue", city: "Leeds", post_code: "LS1 1AA" }
      }
    end
    property = Property.order(:id).last
    assert_equal @vendor, property.involved_party
    assert_redirected_to new_sale_url(step: "buyer", vendor_id: @vendor.id, property_id: property.id)
    follow_redirect!
    assert_response :success
    assert_select "input[name=existing_id][value=?]", @buyer.id.to_s
    assert_select "a", text: /Skip/

    # Skip the buyer
    get new_sale_url(step: "chain", vendor_id: @vendor.id, property_id: property.id)
    assert_response :success
    assert_select ".sale-summary", text: /No buyer yet/

    assert_difference(["Transaction.count", "Chain.count"], 1) do
      post sale_url, params: {
        step: "chain", vendor_id: @vendor.id, property_id: property.id,
        chain_id: "new", chain_name: "Vendor move"
      }
    end
    sale = Transaction.order(:id).last
    assert_equal property, sale.property
    assert_nil sale.involved_party
    assert_equal @user, sale.user
    assert_equal "offer_accepted", sale.legal_stage
    assert_equal "Vendor move", sale.chain.name
    assert_redirected_to chain_url(sale.chain)
    assert_equal "Sale created — 7 Acacia Avenue added to Vendor move", flash[:notice]
  end

  test "suggests a chain where the buyer is selling" do
    buyers_home = Property.create!(user: @user, house_number: "3", street: "Elm Road", post_code: "LS2 2BB",
                                   involved_party: @buyer)
    chain = Chain.create!(user: @user, active: true)
    Transaction.create!(user: @user, chain: chain, property: buyers_home)
    property = Property.create!(user: @user, house_number: "9", street: "Oak Lane", post_code: "LS3 3CC",
                                involved_party: @vendor)

    get new_sale_url(step: "chain", vendor_id: @vendor.id, property_id: property.id, buyer_id: @buyer.id)
    assert_response :success
    assert_select "#suggested-chains input[name=chain_id][value=?]", chain.id.to_s
    assert_select "#suggested-chains", text: /Bob Buyer \(your buyer\) is selling/
  end

  test "unknown ids send the agent back to the first step" do
    get new_sale_url(step: "property", vendor_id: 0)
    assert_redirected_to new_sale_url
  end

  test "signed out users are redirected to sign in" do
    sign_out @user
    get new_sale_url
    assert_redirected_to new_user_session_url
  end
end
