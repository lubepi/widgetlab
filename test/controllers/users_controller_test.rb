require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @admin = users(:admin)
  end

  # ==================== Authentication ====================

  test "index redirects to login when not authenticated" do
    get users_url
    assert_redirected_to login_path
  end

  test "show redirects to login when not authenticated" do
    get user_url(@alice)
    assert_redirected_to login_path
  end

  # ==================== Index ====================

  test "index returns success when authenticated" do
    get users_url, headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  test "index lists all users" do
    get users_url, headers: { "Cookie" => login_as(@admin) }
    assert_response :success
  end

  # ==================== Show ====================

  test "show returns success" do
    get user_url(@alice), headers: { "Cookie" => login_as(@admin) }
    assert_response :success
  end

  test "show displays user information" do
    get user_url(@alice), headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  # ==================== JSON Format ====================

  test "index returns json" do
    get users_url, 
      headers: { "Cookie" => login_as(@alice), "Accept" => "application/json" }
    assert_response :success
  end

  test "show returns json" do
    get user_url(@alice),
      headers: { "Cookie" => login_as(@alice), "Accept" => "application/json" }
    assert_response :success
  end
end
