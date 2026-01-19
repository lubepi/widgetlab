require "test_helper"

class UserGroupRoleTest < ActiveSupport::TestCase
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @developers = user_groups(:developers)
    @managers = user_groups(:managers)
  end

  # ==================== Associations ====================

  test "belongs to user_group" do
    role = user_group_roles(:alice_owns_developers)
    assert_respond_to role, :user_group
    assert_equal @developers, role.user_group
  end

  test "belongs to user" do
    role = user_group_roles(:alice_owns_developers)
    assert_respond_to role, :user
    assert_equal @alice, role.user
  end

  # ==================== Enums ====================

  test "role enum includes member, editor, and owner" do
    assert UserGroupRole.roles.keys.include?("member")
    assert UserGroupRole.roles.keys.include?("editor")
    assert UserGroupRole.roles.keys.include?("owner")
  end

  test "can check role" do
    owner_role = user_group_roles(:alice_owns_developers)
    member_role = user_group_roles(:bob_member_developers)
    editor_role = user_group_roles(:charlie_editor_developers)
    
    assert owner_role.owner?
    assert member_role.member?
    assert editor_role.editor?
  end

  # ==================== Validations ====================

  test "user must be unique per user_group" do
    existing = user_group_roles(:alice_owns_developers)
    duplicate = UserGroupRole.new(
      user: existing.user,
      user_group: existing.user_group,
      role: :member
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "ist bereits Mitglied dieser Nutzergruppe"
  end

  # ==================== CRUD ====================

  test "can create user_group_role" do
    group = UserGroup.create!(name: "New Group")
    role = UserGroupRole.new(user: @alice, user_group: group, role: :owner)
    assert role.save
  end

  test "can update role" do
    role = user_group_roles(:bob_member_developers)
    role.role = :editor
    assert role.save
    role.reload
    assert role.editor?
  end

  test "can destroy user_group_role" do
    group = UserGroup.create!(name: "Test Group")
    role = UserGroupRole.create!(user: @alice, user_group: group, role: :member)
    assert_difference "UserGroupRole.count", -1 do
      role.destroy
    end
  end
end
