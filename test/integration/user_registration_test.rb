require "test_helper"

class UserRegistrationTest < ActionDispatch::IntegrationTest
  test "user can sign up with username, company, phone, email, and password" do
    get new_user_registration_path
    assert_response :success
    assert_select "form#new_user"
    assert_select "input[name='user[phone]']"

    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          user_name: "alex_miller",
          company: "Nexus Real Estate",
          phone: "+44 20 7946 0999",
          email: "alex@nexus.com",
          password: "SecurePassword1",
          password_confirmation: "SecurePassword1"
        }
      }
    end

    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success

    user = User.find_by(email: "alex@nexus.com")
    assert_not_nil user
    assert_equal "alex_miller", user.user_name
    assert_equal "Nexus Real Estate", user.company
    assert_equal "+44 20 7946 0999", user.phone

    # Verify navbar avatar shows user name and company
    assert_select ".navbar-movee__user[title=?]", "alex_miller · Nexus Real Estate"
  end

  test "user can update profile, company name, and phone" do
    user = User.create!(
      user_name: "jordan_lee",
      company: "Jordan Realty",
      phone: "+44 20 7946 0111",
      email: "jordan@example.com",
      password: "Password123"
    )

    sign_in user

    get edit_user_registration_path
    assert_response :success
    assert_select "input[name='user[company]'][value='Jordan Realty']"
    assert_select "input[name='user[phone]'][value='+44 20 7946 0111']"

    put user_registration_path, params: {
      user: {
        company: "Jordan & Partners Realty",
        user_name: "jordan_partners",
        phone: "+44 20 7946 0222",
        current_password: "Password123"
      }
    }

    assert_redirected_to root_path
    user.reload
    assert_equal "Jordan & Partners Realty", user.company
    assert_equal "jordan_partners", user.user_name
    assert_equal "+44 20 7946 0222", user.phone
  end
end
