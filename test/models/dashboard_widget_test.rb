require "test_helper"

class DashboardWidgetTest < ActiveSupport::TestCase
  def setup
    @alice_dashboard = dashboards(:alice_dashboard)
    @alice_widget = widgets(:alice_widget)
    @bob_widget = widgets(:bob_widget)
  end

  # ==================== Associations ====================

  test "belongs to dashboard" do
    dw = dashboard_widgets(:alice_widget_on_alice_dashboard)
    assert_respond_to dw, :dashboard
    assert_equal @alice_dashboard, dw.dashboard
  end

  test "belongs to widget" do
    dw = dashboard_widgets(:alice_widget_on_alice_dashboard)
    assert_respond_to dw, :widget
    assert_equal @alice_widget, dw.widget
  end

  # ==================== Attributes ====================

  test "has position_x and position_y" do
    dw = dashboard_widgets(:alice_widget_on_alice_dashboard)
    assert_respond_to dw, :position_x
    assert_respond_to dw, :position_y
    assert_equal 0, dw.position_x
    assert_equal 0, dw.position_y
  end

  test "has width and height" do
    dw = dashboard_widgets(:alice_widget_on_alice_dashboard)
    assert_respond_to dw, :width
    assert_respond_to dw, :height
    assert_equal 2, dw.width
    assert_equal 2, dw.height
  end

  test "has color" do
    dw = dashboard_widgets(:alice_widget_on_alice_dashboard)
    assert_respond_to dw, :color
    assert_not_nil dw.color
  end

  # ==================== CRUD ====================

  test "can create dashboard_widget" do
    dw = DashboardWidget.new(
      dashboard: @alice_dashboard,
      widget: @bob_widget,
      position_x: 2,
      position_y: 0,
      width: 1,
      height: 1
    )
    assert dw.save
  end

  test "can update dashboard_widget" do
    dw = dashboard_widgets(:alice_widget_on_alice_dashboard)
    dw.position_x = 5
    dw.width = 3
    assert dw.save
    dw.reload
    assert_equal 5, dw.position_x
    assert_equal 3, dw.width
  end

  test "can destroy dashboard_widget" do
    dw = DashboardWidget.create!(
      dashboard: @alice_dashboard,
      widget: @bob_widget
    )
    assert_difference "DashboardWidget.count", -1 do
      dw.destroy
    end
  end
end
