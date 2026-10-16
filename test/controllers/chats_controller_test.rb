require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "chat_user",
      email: "chat_user@example.com",
      password: "Password123"
    )
    @chat = Chat.create!(user: @user, title: "Test Chat")
  end

  test "should redirect show when not signed in" do
    get chat_url(@chat)
    assert_redirected_to new_user_session_path
  end

  test "should get show when signed in" do
    sign_in @user
    get chat_url(@chat)
    assert_response :success
  end
end
