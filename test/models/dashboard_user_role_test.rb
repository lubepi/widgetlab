require "test_helper"

class DashboardUserRoleTest < ActiveSupport::TestCase
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @alice_dashboard = dashboards(:alice_dashboard)
    @shared_dashboard = dashboards(:shared_dashboard)
  end

  # ==================== Associations ====================

  test "belongs to dashboard" do
    role = dashboard_user_roles(:alice_owns_alice_dashboard)
    assert_respond_to role, :dashboard
    assert_equal @alice_dashboard, role.dashboard
  end

  test "belongs to user" do
    role = dashboard_user_roles(:alice_owns_alice_dashboard)
    assert_respond_to role, :user
    assert_equal @alice, role.user
  end

  # ==================== Enums ====================

  test "role enum includes viewer, editor, and owner" do
    assert DashboardUserRole.roles.keys.include?("viewer")
    assert DashboardUserRole.roles.keys.include?("editor")
    assert DashboardUserRole.roles.keys.include?("owner")
  end

  test "can check role" do
    owner_role = dashboard_user_roles(:alice_owns_alice_dashboard)
    viewer_role = dashboard_user_roles(:alice_views_shared_dashboard)
    editor_role = dashboard_user_roles(:charlie_edits_shared_dashboard)
    
    assert owner_role.owner?
    assert viewer_role.viewer?
    assert editor_role.editor?
  end

  # ==================== Validations ====================

  test "user must be unique per dashboard" do
    existing = dashboard_user_roles(:alice_owns_alice_dashboard)
    duplicate = DashboardUserRole.new(
      user: existing.user,
      dashboard: existing.dashboard,
      role: :viewer
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "ist bereits Mitglied dieses Dashboards"
  end

  test "role is required" do
    role = DashboardUserRole.new(user: @alice, dashboard: Dashboard.create!(name: "Test", columns: 3))
    role.role = nil
    assert_not role.valid?
    assert role.errors[:role].any?, "Expected errors on role"
  end

  # ==================== CRUD ====================

  test "can create dashboard_user_role" do
    dashboard = Dashboard.create!(name: "New Dashboard", columns: 3)
    role = DashboardUserRole.new(
      user: @alice,
      dashboard: dashboard,
      role: :editor
    )
    assert role.save
  end

  test "can update role" do
    role = dashboard_user_roles(:alice_views_shared_dashboard)
    role.role = :editor
    assert role.save
    role.reload
    assert role.editor?
  end

  test "can destroy dashboard_user_role" do
    role = DashboardUserRole.create!(
      user: @bob,
      dashboard: @alice_dashboard,
      role: :viewer
    )
    assert_difference "DashboardUserRole.count", -1 do
      role.destroy
    end
  end
end
