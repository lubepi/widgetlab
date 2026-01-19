require "test_helper"

class UserGroupTest < ActiveSupport::TestCase
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @developers = user_groups(:developers)
    @managers = user_groups(:managers)
  end

  # ==================== Associations ====================

  test "has many user_group_roles" do
    assert_respond_to @developers, :user_group_roles
    assert @developers.user_group_roles.count > 0
  end

  test "has many members through user_group_roles" do
    assert_respond_to @developers, :members
    assert @developers.members.include?(@alice)
    assert @developers.members.include?(@bob)
  end

  test "has many data_source_whitelists as whitelistable" do
    assert_respond_to @developers, :data_source_whitelists
  end

  test "has many dashboard_group_roles" do
    assert_respond_to @developers, :dashboard_group_roles
  end

  test "has many dashboards through dashboard_group_roles" do
    assert_respond_to @developers, :dashboards
  end

  # ==================== Dependent Destroy ====================

  test "destroying user_group destroys associated user_group_roles" do
    group = UserGroup.create!(name: "Test Group")
    UserGroupRole.create!(user_group: group, user: @alice, role: :member)
    
    assert_difference "UserGroupRole.count", -1 do
      group.destroy
    end
  end

  test "destroying user_group destroys associated data_source_whitelists" do
    group = UserGroup.create!(name: "Test Group")
    data_source = DataSource.create!(
      name: "Test",
      source_type: :json_api,
      config: { url: "http://test.com" },
      creator: @alice
    )
    DataSourceWhitelist.create!(data_source: data_source, whitelistable: group)
    
    assert_difference "DataSourceWhitelist.count", -1 do
      group.destroy
    end
  end

  # ==================== CRUD ====================

  test "can create user_group" do
    group = UserGroup.new(name: "New Group")
    assert group.save
  end

  test "can update user_group" do
    @developers.name = "Senior Developers"
    assert @developers.save
    @developers.reload
    assert_equal "Senior Developers", @developers.name
  end

  test "can destroy user_group" do
    group = UserGroup.create!(name: "To Delete")
    assert_difference "UserGroup.count", -1 do
      group.destroy
    end
  end
end
