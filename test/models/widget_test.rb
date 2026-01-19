require "test_helper"

class WidgetTest < ActiveSupport::TestCase
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @alice_widget = widgets(:alice_widget)
    @public_widget = widgets(:public_widget)
    @bob_widget = widgets(:bob_widget)
    @shared_widget = widgets(:shared_widget)
    @public_api = data_sources(:public_api)
  end

  # ==================== Associations ====================

  test "has many user_widget_roles" do
    assert_respond_to @alice_widget, :user_widget_roles
    assert @alice_widget.user_widget_roles.count > 0
  end

  test "has many members through user_widget_roles" do
    assert_respond_to @alice_widget, :members
    assert @alice_widget.members.include?(@alice)
  end

  test "has many dashboard_widgets" do
    assert_respond_to @alice_widget, :dashboard_widgets
  end

  test "has many dashboards through dashboard_widgets" do
    assert_respond_to @alice_widget, :dashboards
    assert @alice_widget.dashboards.include?(dashboards(:alice_dashboard))
  end

  test "has one widget_data_source_transformer" do
    assert_respond_to @alice_widget, :widget_data_source_transformer
    assert_not_nil @alice_widget.widget_data_source_transformer
  end

  test "has one data_source through widget_data_source_transformer" do
    assert_respond_to @alice_widget, :data_source
    assert_equal @public_api, @alice_widget.data_source
  end

  # ==================== Enums ====================

  test "widget_type enum includes value, line, bar, column" do
    assert Widget.widget_types.keys.include?("value")
    assert Widget.widget_types.keys.include?("line")
    assert Widget.widget_types.keys.include?("bar")
    assert Widget.widget_types.keys.include?("column")
  end

  test "can check widget_type" do
    assert @alice_widget.line?
    assert @public_widget.bar?
    assert @bob_widget.value?
    assert @shared_widget.column?
  end

  # ==================== Validations ====================

  test "name is required" do
    widget = Widget.new(widget_type: :value)
    assert_not widget.valid?
    assert_includes widget.errors[:name], "can't be blank"
  end

  test "widget_type is required" do
    widget = Widget.new(name: "Test")
    assert_not widget.valid?
    assert_includes widget.errors[:widget_type], "can't be blank"
  end

  test "time_range_unit validates inclusion" do
    widget = Widget.new(name: "Test", widget_type: :value, time_range_unit: "invalid")
    assert_not widget.valid?
    assert_includes widget.errors[:time_range_unit], "is not included in the list"
  end

  test "group_by validates inclusion" do
    widget = Widget.new(name: "Test", widget_type: :value, group_by: "invalid")
    assert_not widget.valid?
  end

  test "aggregate_function validates inclusion" do
    widget = Widget.new(name: "Test", widget_type: :value, aggregate_function: "invalid")
    assert_not widget.valid?
  end

  # ==================== Scopes ====================

  test "owned_by returns widgets owned by user" do
    owned = Widget.owned_by(@alice)
    assert_includes owned, @alice_widget
    assert_includes owned, @public_widget
    assert_not_includes owned, @bob_widget
  end

  test "shared_with returns widgets shared with user" do
    shared = Widget.shared_with(@alice)
    assert_includes shared, @shared_widget
    assert_not_includes shared, @alice_widget
  end

  test "accessible_by returns all widgets user can access" do
    accessible = Widget.accessible_by(@alice)
    assert_includes accessible, @alice_widget
    assert_includes accessible, @public_widget
    assert_includes accessible, @shared_widget
  end

  test "accessible_by includes public widgets" do
    accessible = Widget.accessible_by(@charlie)
    assert_includes accessible, @public_widget
  end

  # ==================== Permission Methods ====================

  test "owner? returns true for owner" do
    assert @alice_widget.owner?(@alice)
  end

  test "owner? returns false for non-owner" do
    assert_not @alice_widget.owner?(@bob)
  end

  test "owner? returns false for nil user" do
    assert_not @alice_widget.owner?(nil)
  end

  test "viewer? returns true for viewer" do
    assert @shared_widget.viewer?(@alice)
  end

  test "viewer? returns false for non-viewer" do
    assert_not @alice_widget.viewer?(@bob)
  end

  test "can_view? returns true for owner" do
    assert @alice_widget.can_view?(@alice)
  end

  test "can_view? returns true for viewer" do
    assert @shared_widget.can_view?(@alice)
  end

  test "can_view? returns true for public widget" do
    assert @public_widget.can_view?(@charlie)
    assert @public_widget.can_view?(nil)
  end

  test "can_view? returns false for private widget without access" do
    assert_not @alice_widget.can_view?(@charlie)
  end

  test "can_edit? returns true for owner" do
    assert @alice_widget.can_edit?(@alice)
  end

  test "can_edit? returns false for viewer" do
    assert_not @shared_widget.can_edit?(@alice)
  end

  test "can_edit? returns false for nil user" do
    assert_not @alice_widget.can_edit?(nil)
  end

  # ==================== Owner Management ====================

  test "add_owner creates owner role" do
    widget = Widget.create!(name: "New Widget", widget_type: :value)
    widget.add_owner(@alice)
    assert widget.owner?(@alice)
  end

  test "add_owner does not duplicate role" do
    widget = Widget.create!(name: "New Widget", widget_type: :value)
    widget.add_owner(@alice)
    widget.add_owner(@alice)
    assert_equal 1, widget.user_widget_roles.where(user: @alice).count
  end

  test "add_viewer creates viewer role" do
    widget = Widget.create!(name: "New Widget", widget_type: :value)
    widget.add_viewer(@bob)
    assert widget.viewer?(@bob)
  end

  test "owner returns the widget owner" do
    assert_equal @alice, @alice_widget.owner
  end

  # ==================== Time Range ====================

  test "time_range_start returns calculated time" do
    widget = Widget.new(time_range_value: 24, time_range_unit: "hours")
    start_time = widget.time_range_start
    assert_in_delta 24.hours.ago.to_i, start_time.to_i, 5
  end

  test "time_range_start defaults to 24 hours ago" do
    widget = Widget.new
    start_time = widget.time_range_start
    assert_in_delta 24.hours.ago.to_i, start_time.to_i, 5
  end

  # ==================== Dependent Destroy ====================

  test "destroying widget destroys user_widget_roles" do
    widget = Widget.create!(name: "Test Widget", widget_type: :value)
    UserWidgetRole.create!(widget: widget, user: @alice, role: :owner)
    
    assert_difference "UserWidgetRole.count", -1 do
      widget.destroy
    end
  end

  test "destroying widget destroys dashboard_widgets" do
    widget = Widget.create!(name: "Test Widget", widget_type: :value)
    dashboard = Dashboard.create!(name: "Test Dashboard", columns: 3)
    DashboardWidget.create!(widget: widget, dashboard: dashboard)
    
    assert_difference "DashboardWidget.count", -1 do
      widget.destroy
    end
  end

  test "destroying widget destroys widget_data_source_transformer" do
    widget = Widget.create!(name: "Test Widget", widget_type: :value)
    WidgetDataSourceTransformer.create!(widget: widget, data_source: @public_api)
    
    assert_difference "WidgetDataSourceTransformer.count", -1 do
      widget.destroy
    end
  end

  # ==================== CRUD ====================

  test "can create widget with valid attributes" do
    widget = Widget.new(
      name: "New Widget",
      widget_type: :line,
      description: "A test widget",
      time_range_value: 48,
      time_range_unit: "hours",
      group_by: "hour",
      aggregate_function: "avg"
    )
    assert widget.save
  end

  test "can update widget" do
    @alice_widget.name = "Updated Widget"
    assert @alice_widget.save
    @alice_widget.reload
    assert_equal "Updated Widget", @alice_widget.name
  end

  test "can destroy widget" do
    widget = Widget.create!(name: "To Delete", widget_type: :value)
    assert_difference "Widget.count", -1 do
      widget.destroy
    end
  end
end
