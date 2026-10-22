require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "test_broker",
      email: "broker@example.com",
      password: "Password123",
      company: "Movee Premier",
      phone: "+44 20 7946 0001",
      admin: false
    )
    @other_user = User.create!(
      user_name: "other_broker",
      email: "other@example.com",
      password: "Password123",
      admin: false
    )
    @admin = User.create!(
      user_name: "admin_user",
      email: "admin@example.com",
      password: "Password123",
      admin: true
    )
    @party = InvolvedParty.create!(
      first_name: "Sarah",
      last_name: "Connor",
      email: "sarah.connor@example.com",
      phone: "+44 7700 900666",
      seller: true
    )
    @property = Property.create!(
      user: @user,
      house_number: "221B",
      street: "Baker Street",
      city: "London",
      post_code: "NW1 6XE",
      involved_party: @party
    )
  end

  test "public visitor can view home page without signing in" do
    get root_path
    assert_response :success
    assert_select "a[href='#{new_user_session_path}']"
    assert_select "a[href='#{new_user_registration_path}']"
  end

  test "public home page has SEO meta tags and is indexable" do
    get root_path
    assert_select "title", text: /Moveee/
    assert_select "meta[name='description'][content]"
    assert_select "meta[name='robots'][content='index, follow']"
    assert_select "link[rel='canonical'][href='#{root_url}']"
    assert_select "meta[property='og:title']"
    assert_select "script[type='application/ld+json']"
  end

  test "signed-in app pages are not indexable" do
    sign_in @user
    get properties_path
    assert_select "meta[name='robots'][content='noindex, nofollow']"
  end

  test "signed-in user visiting home is redirected to the dashboard" do
    sign_in @user
    get root_path
    assert_redirected_to dashboard_path
  end

  test "unauthenticated visitor is redirected to login from properties" do
    get properties_url
    assert_redirected_to new_user_session_url
  end

  test "signed in user should get index" do
    sign_in @user
    get properties_url
    assert_response :success
    assert_select "h1", text: /Properties/i
  end

  test "signed in user should get show with agent contact details" do
    sign_in @user
    get property_url(@property)
    assert_response :success
    assert_select "h1", text: /221B Baker Street/
    assert_select "a[href='mailto:#{@user.email}']"
    assert_select "a[href='tel:#{@user.phone}']"
  end

  test "signed in user can create property" do
    sign_in @user
    assert_difference("Property.count") do
      post properties_url, params: {
        property: {
          house_number: "15",
          street: "Piccadilly",
          city: "London",
          post_code: "W1J 0LF"
        }
      }
    end
    created_property = Property.order(created_at: :desc).first
    assert_redirected_to property_url(created_property)
    assert_equal "15", created_property.house_number
  end

  test "owner should get edit" do
    sign_in @user
    get edit_property_url(@property)
    assert_response :success
  end

  test "owner can update property" do
    sign_in @user
    patch property_url(@property), params: {
      property: {
        sold: true,
        second_line_of_address: "Flat 2"
      }
    }
    assert_redirected_to property_url(@property)
    @property.reload
    assert_not @property.sold, "sold can't be set by hand; it follows the property's transactions"
    assert_equal "Flat 2", @property.second_line_of_address
  end

  test "owner can destroy property" do
    sign_in @user
    assert_difference("Property.count", -1) do
      delete property_url(@property)
    end
    assert_redirected_to properties_url
  end

  test "non-owner non-admin CANNOT update other's property" do
    sign_in @other_user
    patch property_url(@property), params: {
      property: { house_number: "999" }
    }
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/not authorized/i, flash[:alert])
    assert_not_equal "999", @property.reload.house_number
  end

  test "non-owner non-admin CANNOT delete other's property" do
    sign_in @other_user
    assert_no_difference("Property.count") do
      delete property_url(@property)
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match(/not authorized/i, flash[:alert])
  end

  test "ADMIN CAN update other user's property" do
    sign_in @admin
    patch property_url(@property), params: {
      property: { house_number: "777" }
    }
    assert_redirected_to property_url(@property)
    assert_equal "777", @property.reload.house_number
  end

  test "ADMIN CAN destroy other user's property" do
    sign_in @admin
    assert_difference("Property.count", -1) do
      delete property_url(@property)
    end
    assert_redirected_to properties_url
  end

  test "owner can remove involved party" do
    sign_in @user
    assert_equal @party, @property.involved_party
    delete remove_involved_party_property_url(@property)
    assert_redirected_to property_url(@property)
    assert_nil @property.reload.involved_party
  end

  test "properties index hides sold/for sale info panels and unauthorized party details" do
    sign_in @other_user
    get properties_url
    assert_response :success

    # No stat cards and no count subtitle under the title
    assert_select ".page-subtitle", count: 0
    assert_select ".card", text: /Total Properties/, count: 0
    assert_select ".card", text: /Available \/ For Sale/, count: 0
    assert_select ".card", text: /Sold/, count: 0

    # Unauthorized party info masked
    assert_select "body", text: /Sarah Connor/, count: 0
    assert_select "body", text: /Protected Client/

    # Managing agent links to their profile (where their contact details are) for coordination
    assert_select "a[href=?]", user_path(@user)

    # No seller/buyer tags on properties index
    assert_select ".badge", text: "Seller", count: 0
    assert_select ".badge", text: "Buyer", count: 0
  end

  test "property show renders conveyancing progress bar and pipeline without seller/buyer tags" do
    sign_in @user
    get property_url(@property)
    assert_response :success

    # Conveyancing Progress Bar & Stepper
    assert_select ".conveyancing-pipeline"
    assert_select ".progress-bar"

    # No seller/buyer tags in client panel
    assert_select ".badge", text: "Seller", count: 0
    assert_select ".badge", text: "Buyer", count: 0
  end

  test "properties index masks involved party of other agent's property even if other user has transaction with party" do
    chain = Chain.create!(user: @other_user, active: true)
    other_prop = Property.create!(user: @other_user, house_number: "10", street: "Downing St", post_code: "SW1A 2AA")
    Transaction.create!(user: @other_user, property: other_prop, chain: chain, involved_party: @party)

    sign_in @other_user
    get properties_url
    assert_response :success

    # On @property (listed by @user), Sarah Connor must NOT be visible to other agents
    assert_select "body", text: /Protected Client/
    assert_select "tr" do |rows|
      baker_row = rows.find { |r| r.text.include?("Baker Street") }
      if baker_row
        assert_includes baker_row.text, "Protected Client"
        refute_includes baker_row.text, "Sarah Connor"
      end
    end
  end

  test "property show masks client details for non-owner non-admin" do
    sign_in @other_user
    get property_url(@property)
    assert_response :success

    assert_select "body", text: /Sarah Connor/, count: 0
    assert_select "p", text: /Confidential client/
  end

   test "new fills in the address from a finished client PDF" do
    sign_in @user
    document = @user.client_documents.create!(
      step: "property", filename: "client.pdf", status: "done",
      extracted_data: { "house_number" => "14", "street" => "Maple Grove", "second_line_of_address" => "Ealing",
                        "city" => "London", "post_code" => nil, "first_name" => "Tunde" }
    )

    get new_property_url(client_document_id: document.id)

    assert_response :success
    assert_select "input[name='property[house_number]'][value=?]", "14"
    assert_select "input[name='property[street]'][value=?]", "Maple Grove"
    assert_select "input[name='property[second_line_of_address]'][value=?]", "Ealing"
    assert_select "input[name='property[city]'][value=?]", "London"
    assert_select ".alert-success", text: /Not found in the PDF: postcode/
  end

  test "new ignores client PDFs from other pages" do
    sign_in @user
    document = @user.client_documents.create!(step: "vendor", filename: "vendor.pdf", status: "done",
                                              extracted_data: { "street" => "Maple Grove" })

    get new_property_url(client_document_id: document.id)

    assert_select "input[name='property[street]'][value=?]", "Maple Grove", count: 0
  end

  test "new shows the Fill from PDF box" do
    sign_in @user

    get new_property_url

    assert_select ".fill-from-pdf input[type=hidden][name=step][value=property]"
  end

   test "the vendor dropdown only lists the agent's own clients" do
    sign_in @user
    own_client = InvolvedParty.create!(user: @user, first_name: "Olivia", last_name: "Own", email: "olivia@example.com",
                                       phone: "+44 7700 900501", seller: true)
    stranger = InvolvedParty.create!(user: @other_user, first_name: "Sam", last_name: "Stranger",
                                     email: "sam@example.com", phone: "+44 7700 900502", seller: true)

    get new_property_url

    assert_select "select[name='property[involved_party_id]'] option[value=?]", own_client.id.to_s
    assert_select "select[name='property[involved_party_id]'] option[value=?]", stranger.id.to_s, count: 0
  end
end
