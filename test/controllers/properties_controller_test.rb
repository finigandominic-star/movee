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
          post_code: "W1J 0LF",
          sold: false
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
    assert_equal true, @property.sold
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

    # Info panel only shows Total Properties (no sold or available cards)
    assert_select ".card", text: /Total Properties/
    assert_select ".card", text: /Available \/ For Sale/, count: 0
    assert_select ".card", text: /Sold/, count: 0

    # Unauthorized party info masked
    assert_select "body", text: /Sarah Connor/, count: 0
    assert_select "body", text: /Protected Client/

    # Managing agent contact info is visible for coordination
    assert_select "a[href='mailto:#{@user.email}']"
    assert_select "a[href='tel:#{@user.phone}']"

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
end
