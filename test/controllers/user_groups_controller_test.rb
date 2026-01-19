require "test_helper"

class UserGroupsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @developers = user_groups(:developers)
    @managers = user_groups(:managers)
  end

  # ==================== Authentication ====================

  test "index redirects to login when not authenticated" do
    get user_groups_url
    assert_redirected_to login_path
  end

  # ==================== Index ====================

  test "index returns success when authenticated" do
    get user_groups_url, headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  # ==================== New ====================

  test "new returns success" do
    get new_user_group_url, headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  # ==================== Create ====================

  test "create creates user group" do
    assert_difference "UserGroup.count", 1 do
      post user_groups_url,
        params: { user_group: { name: "New Group", member_ids: [@alice.id] } },
        headers: { "Cookie" => login_as(@alice) }
    end
  end

  test "create with members adds user_group_roles" do
    assert_difference "UserGroupRole.count", 2 do
      post user_groups_url,
        params: { user_group: { name: "New Group", member_ids: [@alice.id, @bob.id] } },
        headers: { "Cookie" => login_as(@alice) }
    end
  end

  # ==================== Edit ====================

  test "edit returns success" do
    get edit_user_group_url(@developers), headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  # ==================== Update ====================

  test "update updates user group" do
    patch user_group_url(@developers),
      params: { user_group: { name: "Senior Developers" } },
      headers: { "Cookie" => login_as(@alice) }
    
    @developers.reload
    assert_equal "Senior Developers", @developers.name
  end

  test "update syncs members" do
    new_group = UserGroup.create!(name: "Test Group")
    
    patch user_group_url(new_group),
      params: { user_group: { member_ids: [@alice.id, @bob.id] } },
      headers: { "Cookie" => login_as(@alice) }
    
    new_group.reload
    assert_equal 2, new_group.members.count
  end

  # ==================== Destroy ====================

  test "destroy deletes user group" do
    group = UserGroup.create!(name: "To Delete")
    
    assert_difference "UserGroup.count", -1 do
      delete user_group_url(group), headers: { "Cookie" => login_as(@alice) }
    end
  end

  # ==================== JSON Format ====================

  test "index returns json" do
    get user_groups_url,
      headers: { "Cookie" => login_as(@alice), "Accept" => "application/json" }
    assert_response :success
  end

  test "create returns json on success" do
    post user_groups_url,
      params: { user_group: { name: "JSON Group" } },
      headers: { "Cookie" => login_as(@alice), "Accept" => "application/json" }
    assert_response :created
  end

  private

  def login_as(user)
    post "/session", params: { sub: user.sub, email: user.email, first_name: user.first_name, last_name: user.last_name }
    response.headers["Set-Cookie"]
  end
end
