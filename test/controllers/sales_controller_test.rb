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

  test "linking to a property with no buyer joins its chain and makes the vendor its buyer" do
    other_agent = User.create!(user_name: "other_agent", email: "other_agent@example.com", password: "Password123")
    onward_home = Property.create!(user: other_agent, house_number: "12", street: "Birch Close", post_code: "LS4 4DD")
    chain = Chain.create!(user: other_agent, active: true)
    onward_sale = Transaction.create!(user: other_agent, chain: chain, property: onward_home)
    property = Property.create!(user: @user, house_number: "9", street: "Oak Lane", post_code: "LS3 3CC",
                                involved_party: @vendor)

    get new_sale_url(step: "chain", vendor_id: @vendor.id, property_id: property.id, buyer_id: @buyer.id)
    assert_response :success
    assert_select "#chainChoices input[name=chain_id][value=?]", "link-#{onward_sale.id}"

    assert_difference("Transaction.count", 1) do
      assert_no_difference("Chain.count") do
        post sale_url, params: { step: "chain", vendor_id: @vendor.id, property_id: property.id,
                                 buyer_id: @buyer.id, chain_id: "link-#{onward_sale.id}" }
      end
    end
    assert_equal @vendor, onward_sale.reload.involved_party
    assert_equal chain, Transaction.order(:id).last.chain
    assert_equal "buying", @vendor.reload.onward_purchase
    assert_redirected_to chain_url(chain)
  end

  test "properties that already have a buyer can't be linked to" do
    onward_home = Property.create!(user: @user, house_number: "12", street: "Birch Close", post_code: "LS4 4DD")
    taken = Transaction.create!(user: @user, chain: Chain.create!(user: @user, active: true), property: onward_home,
                                involved_party: @buyer)
    property = Property.create!(user: @user, house_number: "9", street: "Oak Lane", post_code: "LS3 3CC",
                                involved_party: @vendor)

    get new_sale_url(step: "chain", vendor_id: @vendor.id, property_id: property.id)
    assert_select "input[value=?]", "link-#{taken.id}", count: 0

    assert_no_difference("Transaction.count") do
      post sale_url, params: { step: "chain", vendor_id: @vendor.id, property_id: property.id,
                               chain_id: "link-#{taken.id}" }
    end
    assert_response :unprocessable_entity
    assert_equal @buyer, taken.reload.involved_party
  end

  test "a new property can be added with a photo" do
    photo = Rack::Test::UploadedFile.new(StringIO.new("fake image"), "image/png", original_filename: "house.png")
    assert_difference("Property.count", 1) do
      post sale_url, params: {
        step: "property", vendor_id: @vendor.id,
        property: { house_number: "5", street: "Photo Lane", post_code: "LS6 6FF", photo: photo }
      }
    end
    assert Property.order(:id).last.photo.attached?
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

  test "the vendor step fills in the new client form from a finished client PDF" do
    document = @user.client_documents.create!(
      step: "vendor", filename: "client.pdf", status: "done",
      extracted_data: { "first_name" => "Tunde", "last_name" => "Adebayo", "email" => "tunde.adebayo@example.com",
                        "phone" => nil, "onward_purchase" => "buying" }
    )

    get new_sale_url(client_document_id: document.id)

    assert_select "input[name='involved_party[first_name]'][value=?]", "Tunde"
    assert_select "input[name='involved_party[email]'][value=?]", "tunde.adebayo@example.com"
    assert_select "input[name='involved_party[onward_purchase]'][value=buying][checked]"
    assert_select ".alert-success", text: /Not found in the PDF: phone number/
  end

  test "the vendor step says when a client PDF is still being read" do
    document = @user.client_documents.create!(step: "vendor", filename: "client.pdf")

    get new_sale_url(client_document_id: document.id)

    assert_select ".fill-from-pdf", text: /Reading client.pdf/
    assert_select "input[name='involved_party[first_name]'][value]", count: 0
  end

  test "the vendor step shows why a client PDF could not be read" do
    document = @user.client_documents.create!(step: "vendor", filename: "client.pdf", status: "failed",
                                              error_message: "The assistant gave no answer.")

    get new_sale_url(client_document_id: document.id)

    assert_select ".alert-danger", text: /The assistant gave no answer/
  end

  test "the vendor step ignores another agent's client PDF" do
    other = User.create!(user_name: "other_agent", email: "other@example.com", password: "Password123",
                         phone: "+44 20 7946 0199")
    document = other.client_documents.create!(step: "vendor", filename: "secret.pdf", status: "done",
                                              extracted_data: { "first_name" => "Secret" })

    get new_sale_url(client_document_id: document.id)

    assert_response :success
    assert_select "input[name='involved_party[first_name]'][value=?]", "Secret", count: 0
  end

  test "the vendor step keeps checking while a client PDF is being read" do
    document = @user.client_documents.create!(step: "vendor", filename: "client.pdf")

    get new_sale_url(client_document_id: document.id)

    assert_select "[data-controller=auto-reload]", text: /Reading client.pdf/
  end

  test "the vendor step stops checking when reading a client PDF takes too long" do
    document = @user.client_documents.create!(step: "vendor", filename: "client.pdf")

    travel 3.minutes do
      get new_sale_url(client_document_id: document.id)
    end

    assert_select ".alert-warning", text: /taking longer than expected/
    assert_select "[data-controller=auto-reload]", count: 0
  end

  test "the buyer step fills in the new client form from a finished client PDF" do
    property = Property.create!(user: @user, involved_party: @vendor, house_number: "7", street: "Acacia Avenue",
                                city: "Leeds", post_code: "LS1 1AA")
    document = @user.client_documents.create!(
      step: "buyer", filename: "buyer.pdf", status: "done",
      extracted_data: { "first_name" => "Grace", "last_name" => "O'Neill", "email" => "grace@example.com" }
    )

    get new_sale_url(step: "buyer", vendor_id: @vendor.id, property_id: property.id, client_document_id: document.id)

    assert_select "input[name='involved_party[first_name]'][value=?]", "Grace"
    assert_select "input[name='involved_party[last_name]'][value=?]", "O'Neill"
    assert_select ".alert-success", text: /Filled in from buyer.pdf/
  end

  test "a client PDF from the vendor step does not fill in the buyer step" do
    property = Property.create!(user: @user, involved_party: @vendor, house_number: "7", street: "Acacia Avenue",
                                city: "Leeds", post_code: "LS1 1AA")
    document = @user.client_documents.create!(step: "vendor", filename: "vendor.pdf", status: "done",
                                              extracted_data: { "first_name" => "Tunde" })

    get new_sale_url(step: "buyer", vendor_id: @vendor.id, property_id: property.id, client_document_id: document.id)

    assert_select "input[name='involved_party[first_name]'][value=?]", "Tunde", count: 0
    assert_select ".alert-success", count: 0
  end
end
