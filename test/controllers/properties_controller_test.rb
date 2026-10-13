require "test_helper"

class PropertiesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "test_broker",
      email: "broker@example.com",
      password: "Password123",
      company: "Movee Premier"
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

  test "should get index" do
    get properties_url
    assert_response :success
    assert_select "h1", text: /Properties/i
  end

  test "should get show" do
    get property_url(@property)
    assert_response :success
    assert_select "h1", text: /221B Baker Street/
  end

  test "should get new" do
    get new_property_url
    assert_response :success
  end

  test "should create property" do
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

  test "should get edit" do
    get edit_property_url(@property)
    assert_response :success
  end

  test "should update property" do
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

  test "should destroy property" do
    assert_difference("Property.count", -1) do
      delete property_url(@property)
    end
    assert_redirected_to properties_url
  end

  test "should remove involved party" do
    assert_equal @party, @property.involved_party
    delete remove_involved_party_property_url(@property)
    assert_redirected_to property_url(@property)
    assert_nil @property.reload.involved_party
  end
end
