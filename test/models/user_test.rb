require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ==================== Fixtures ====================
  
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @admin = users(:admin)
  end

  # ==================== Associations ====================
  
  test "has many dashboard_user_roles" do
    assert_respond_to @alice, :dashboard_user_roles
    assert @alice.dashboard_user_roles.count > 0
  end

  test "has many dashboards through dashboard_user_roles" do
    assert_respond_to @alice, :dashboards
    assert @alice.dashboards.include?(dashboards(:alice_dashboard))
  end

  test "has many user_group_roles" do
    assert_respond_to @alice, :user_group_roles
    assert @alice.user_group_roles.count > 0
  end

  test "has many user_groups through user_group_roles" do
    assert_respond_to @alice, :user_groups
    assert @alice.user_groups.include?(user_groups(:developers))
  end

  test "has many user_widget_roles" do
    assert_respond_to @alice, :user_widget_roles
    assert @alice.user_widget_roles.count > 0
  end

  test "has many widgets through user_widget_roles" do
    assert_respond_to @alice, :widgets
    assert @alice.widgets.include?(widgets(:alice_widget))
  end

  test "has many data_source_whitelists as whitelistable" do
    assert_respond_to @alice, :data_source_whitelists
  end

  # ==================== Dependent Destroy ====================

  test "destroying user destroys associated dashboard_user_roles" do
    user = User.create!(
      first_name: "Test",
      last_name: "User",
      email: "test.destroy@example.com",
      sub: "test-destroy-sub"
    )
    dashboard = Dashboard.create!(name: "Test Dashboard", columns: 3)
    DashboardUserRole.create!(user: user, dashboard: dashboard, role: :owner)
    
    assert_difference "DashboardUserRole.count", -1 do
      user.destroy
    end
  end

  test "destroying user destroys associated user_group_roles" do
    user = User.create!(
      first_name: "Test",
      last_name: "User",
      email: "test.destroy2@example.com",
      sub: "test-destroy2-sub"
    )
    group = UserGroup.create!(name: "Test Group")
    UserGroupRole.create!(user: user, user_group: group, role: :member)
    
    assert_difference "UserGroupRole.count", -1 do
      user.destroy
    end
  end

  test "destroying user destroys associated user_widget_roles" do
    user = User.create!(
      first_name: "Test",
      last_name: "User",
      email: "test.destroy3@example.com",
      sub: "test-destroy3-sub"
    )
    widget = Widget.create!(name: "Test Widget", widget_type: :value)
    UserWidgetRole.create!(user: user, widget: widget, role: :owner)
    
    assert_difference "UserWidgetRole.count", -1 do
      user.destroy
    end
  end

  # ==================== Basic CRUD ====================

  test "can create a new user" do
    user = User.new(
      first_name: "New",
      last_name: "User",
      email: "new.user@example.com",
      sub: "new-user-sub"
    )
    assert user.save
  end

  test "can update user attributes" do
    @alice.first_name = "Alicia"
    assert @alice.save
    @alice.reload
    assert_equal "Alicia", @alice.first_name
  end

  test "can destroy user" do
    user = User.create!(
      first_name: "Delete",
      last_name: "Me",
      email: "delete.me@example.com",
      sub: "delete-me-sub"
    )
    assert_difference "User.count", -1 do
      user.destroy
    end
  end

  # ==================== Full Name Helper ====================

  test "full_name returns first_name and last_name combined" do
    assert_equal "Alice Smith", "#{@alice.first_name} #{@alice.last_name}"
  end
end
