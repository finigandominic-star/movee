require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "msg_user",
      email: "msg_user@example.com",
      password: "Password123"
    )
    @chat = Chat.create!(user: @user, title: "Test Chat")
  end

  test "should redirect create when not signed in" do
    post chat_messages_url(@chat), params: { message: { content: "Hello" } }
    assert_redirected_to new_user_session_path
  end
end
