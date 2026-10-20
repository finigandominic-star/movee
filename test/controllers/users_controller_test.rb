require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @agent = User.create!(user_name: "profile_agent", email: "profile_agent@example.com", password: "Password123",
                          phone: "+44 20 7946 0199", company: "Profile Estates")
    @property = Property.create!(user: @agent, house_number: "4", street: "Profile Road", post_code: "LS5 5EE")
    @viewer = User.create!(user_name: "viewer", email: "viewer@example.com", password: "Password123")
  end

  test "any signed-in agent can view an agent's profile" do
    sign_in @viewer
    get user_url(@agent)
    assert_response :success
    assert_select "h1", text: "profile_agent"
    assert_select "a[href='mailto:#{@agent.email}']"
    assert_select "a[href='tel:#{@agent.phone}']"
    assert_select "a[href=?]", property_path(@property), text: /Profile Road/
  end

  test "signed out users are redirected to sign in" do
    get user_url(@agent)
    assert_redirected_to new_user_session_url
  end

  test "devise routes still work alongside profiles" do
    get new_user_session_url
    assert_response :success
  end
end
