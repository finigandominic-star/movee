require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      user_name: "dash_tester",
      email: "dashtester@example.com",
      password: "Password123"
    )
    @property = Property.create!(
      user: @user,
      house_number: "221B",
      street: "Baker Street",
      post_code: "NW1 6XE"
    )
    @chain = Chain.create!(active: true)
    @overdue = Transaction.create!(
      user: @user,
      property: @property,
      chain: @chain,
      completed: false,
      estimated_completion_date: 10.days.ago.to_date
    )
  end

  test "redirects to sign in when signed out" do
    get dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "shows greeting and new sale call to action" do
    sign_in @user
    get dashboard_url
    assert_response :success
    assert_select "h1", text: /dash_tester/
    assert_select "a.btn-accent[href='#{new_sale_path}']", text: /Start a new sale/
  end

  test "lists an overdue transaction under needs attention" do
    sign_in @user
    get dashboard_url
    assert_response :success
    assert_select "#needs-attention a[href='#{transaction_path(@overdue)}']", text: /#{Regexp.escape(@property.short_address)}/
    assert_select "#needs-attention", text: /Update stage/
  end
end
