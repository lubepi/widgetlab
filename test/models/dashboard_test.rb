require "test_helper"

class DashboardTest < ActiveSupport::TestCase
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @alice_dashboard = dashboards(:alice_dashboard)
    @public_dashboard = dashboards(:public_dashboard)
    @bob_dashboard = dashboards(:bob_dashboard)
    @shared_dashboard = dashboards(:shared_dashboard)
  end

  # ==================== Associations ====================
  
  test "has many dashboard_user_roles" do
    assert_respond_to @alice_dashboard, :dashboard_user_roles
  end

  test "has many members through dashboard_user_roles" do
    assert_respond_to @alice_dashboard, :members
    assert @alice_dashboard.members.include?(@alice)
  end

  test "has many dashboard_group_roles" do
    assert_respond_to @alice_dashboard, :dashboard_group_roles
  end

  test "has many member_groups through dashboard_group_roles" do
    assert_respond_to @alice_dashboard, :member_groups
  end

  test "has many dashboard_widgets" do
    assert_respond_to @alice_dashboard, :dashboard_widgets
    assert @alice_dashboard.dashboard_widgets.count > 0
  end

  test "has many widgets through dashboard_widgets" do
    assert_respond_to @alice_dashboard, :widgets
    assert @alice_dashboard.widgets.include?(widgets(:alice_widget))
  end

  # ==================== Scopes ====================

  test "owned_by returns dashboards owned by user" do
    owned = Dashboard.owned_by(@alice)
    assert_includes owned, @alice_dashboard
    assert_includes owned, @public_dashboard
    assert_not_includes owned, @bob_dashboard
  end

  test "shared_with returns dashboards shared with user but not owned" do
    shared = Dashboard.shared_with(@alice)
    assert_includes shared, @shared_dashboard
    assert_not_includes shared, @alice_dashboard
    assert_not_includes shared, @bob_dashboard
  end

  test "accessible_by returns all dashboards user can access" do
    accessible = Dashboard.accessible_by(@alice)
    assert_includes accessible, @alice_dashboard
    assert_includes accessible, @public_dashboard
    assert_includes accessible, @shared_dashboard
  end

  test "accessible_by includes public dashboards" do
    accessible = Dashboard.accessible_by(@charlie)
    assert_includes accessible, @public_dashboard
  end

  # ==================== Role Methods ====================

  test "role_for returns owner for dashboard owner" do
    assert_equal "owner", @alice_dashboard.role_for(@alice)
  end

  test "role_for returns viewer for dashboard viewer" do
    assert_equal "viewer", @shared_dashboard.role_for(@alice)
  end

  test "role_for returns editor for dashboard editor" do
    assert_equal "editor", @shared_dashboard.role_for(@charlie)
  end

  test "role_for returns nil for user without access" do
    assert_nil @alice_dashboard.role_for(@charlie)
  end

  test "owner? returns true for owner" do
    assert @alice_dashboard.owner?(@alice)
  end

  test "owner? returns false for non-owner" do
    assert_not @alice_dashboard.owner?(@bob)
  end

  test "can_edit? returns true for owner" do
    assert @alice_dashboard.can_edit?(@alice)
  end

  test "can_edit? returns true for editor" do
    assert @shared_dashboard.can_edit?(@charlie)
  end

  test "can_edit? returns false for viewer" do
    assert_not @shared_dashboard.can_edit?(@alice)
  end

  test "can_view? returns true for public dashboard" do
    assert @public_dashboard.can_view?(nil)
  end

  test "can_view? returns true for members" do
    assert @alice_dashboard.can_view?(@alice)
  end

  test "can_view? returns false for non-members on private dashboard" do
    assert_not @alice_dashboard.can_view?(@charlie)
  end

  # ==================== Dependent Destroy ====================

  test "destroying dashboard destroys associated dashboard_user_roles" do
    dashboard = Dashboard.create!(name: "Test Dashboard", columns: 3)
    DashboardUserRole.create!(user: @alice, dashboard: dashboard, role: :owner)
    
    assert_difference "DashboardUserRole.count", -1 do
      dashboard.destroy
    end
  end

  test "destroying dashboard destroys associated dashboard_widgets" do
    dashboard = Dashboard.create!(name: "Test Dashboard", columns: 3)
    widget = Widget.create!(name: "Test Widget", widget_type: :value)
    DashboardWidget.create!(dashboard: dashboard, widget: widget)
    
    assert_difference "DashboardWidget.count", -1 do
      dashboard.destroy
    end
  end

  # ==================== CRUD ====================

  test "can create a dashboard" do
    dashboard = Dashboard.new(name: "New Dashboard", columns: 4, is_public: false)
    assert dashboard.save
  end

  test "can update a dashboard" do
    @alice_dashboard.name = "Updated Dashboard"
    assert @alice_dashboard.save
    @alice_dashboard.reload
    assert_equal "Updated Dashboard", @alice_dashboard.name
  end

  test "can destroy a dashboard" do
    dashboard = Dashboard.create!(name: "To Delete", columns: 2)
    assert_difference "Dashboard.count", -1 do
      dashboard.destroy
    end
  end
end
