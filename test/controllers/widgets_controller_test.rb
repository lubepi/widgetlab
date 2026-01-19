require "test_helper"

class WidgetsControllerTest < ActionDispatch::IntegrationTest
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

  # ==================== Authentication ====================

  test "index redirects to login when not authenticated" do
    get widgets_url
    assert_redirected_to login_path
  end

  # ==================== Index ====================

  test "index returns success when authenticated" do
    get widgets_url, headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  # ==================== New ====================

  test "new returns success" do
    get new_widget_url, headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  # ==================== Create ====================

  test "create creates widget" do
    assert_difference "Widget.count", 1 do
      post widgets_url,
        params: { widget: { 
          name: "New Widget", 
          widget_type: "line",
          time_range_value: 24,
          time_range_unit: "hours",
          group_by: "hour",
          aggregate_function: "avg"
        } },
        headers: { "Cookie" => login_as(@alice) }
    end
  end

  test "create assigns current user as owner" do
    post widgets_url,
      params: { widget: { name: "New Widget", widget_type: "value" } },
      headers: { "Cookie" => login_as(@alice) }
    
    widget = Widget.last
    assert widget.owner?(@alice)
  end

  test "create with data_source creates transformer" do
    assert_difference "WidgetDataSourceTransformer.count", 1 do
      post widgets_url,
        params: { widget: { 
          name: "New Widget", 
          widget_type: "line",
          data_source_id: @public_api.id
        } },
        headers: { "Cookie" => login_as(@alice) }
    end
  end

  # ==================== Edit ====================

  test "edit returns success for owned widget" do
    get edit_widget_url(@alice_widget), headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  test "edit returns forbidden for non-owner" do
    get edit_widget_url(@alice_widget), headers: { "Cookie" => login_as(@bob) }
    # Should redirect or return forbidden
    assert_response :redirect
  end

  # ==================== Update ====================

  test "update updates widget" do
    patch widget_url(@alice_widget),
      params: { widget: { name: "Updated Widget" }, access: { user_roles: { @alice.id.to_s => "owner" } } },
      headers: { "Cookie" => login_as(@alice) }
    
    @alice_widget.reload
    assert_equal "Updated Widget", @alice_widget.name
  end

  test "update forbidden for non-owner" do
    patch widget_url(@alice_widget),
      params: { widget: { name: "Hacked" } },
      headers: { "Cookie" => login_as(@bob) }
    
    @alice_widget.reload
    assert_not_equal "Hacked", @alice_widget.name
  end

  # ==================== Destroy ====================

  test "destroy deletes widget" do
    widget = Widget.create!(name: "To Delete", widget_type: :value)
    UserWidgetRole.create!(user: @alice, widget: widget, role: :owner)
    
    assert_difference "Widget.count", -1 do
      delete widget_url(widget), headers: { "Cookie" => login_as(@alice) }
    end
  end

  test "destroy forbidden for non-owner" do
    assert_no_difference "Widget.count" do
      delete widget_url(@alice_widget), headers: { "Cookie" => login_as(@bob) }
    end
  end
end
