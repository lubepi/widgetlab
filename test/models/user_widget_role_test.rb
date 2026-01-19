require "test_helper"

class UserWidgetRoleTest < ActiveSupport::TestCase
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @alice_widget = widgets(:alice_widget)
    @shared_widget = widgets(:shared_widget)
  end

  # ==================== Associations ====================

  test "belongs to widget" do
    role = user_widget_roles(:alice_owns_alice_widget)
    assert_respond_to role, :widget
    assert_equal @alice_widget, role.widget
  end

  test "belongs to user" do
    role = user_widget_roles(:alice_owns_alice_widget)
    assert_respond_to role, :user
    assert_equal @alice, role.user
  end

  # ==================== Enums ====================

  test "role enum includes viewer and owner" do
    assert UserWidgetRole.roles.keys.include?("viewer")
    assert UserWidgetRole.roles.keys.include?("owner")
  end

  test "can check role" do
    owner_role = user_widget_roles(:alice_owns_alice_widget)
    viewer_role = user_widget_roles(:alice_views_shared_widget)
    
    assert owner_role.owner?
    assert viewer_role.viewer?
  end

  # ==================== CRUD ====================

  test "can create user_widget_role" do
    widget = Widget.create!(name: "New Widget", widget_type: :value)
    role = UserWidgetRole.new(user: @bob, widget: widget, role: :owner)
    assert role.save
  end

  test "can update role" do
    role = user_widget_roles(:alice_views_shared_widget)
    role.role = :owner
    assert role.save
    role.reload
    assert role.owner?
  end

  test "can destroy user_widget_role" do
    role = UserWidgetRole.create!(user: @bob, widget: @alice_widget, role: :viewer)
    assert_difference "UserWidgetRole.count", -1 do
      role.destroy
    end
  end
end
