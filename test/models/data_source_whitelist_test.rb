require "test_helper"

class DataSourceWhitelistTest < ActiveSupport::TestCase
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @developers = user_groups(:developers)
    @whitelisted_api = data_sources(:whitelisted_api)
    @private_mqtt = data_sources(:private_mqtt)
    @public_api = data_sources(:public_api)
  end

  # ==================== Associations ====================

  test "belongs to data_source" do
    whitelist = data_source_whitelists(:alice_whitelist_api)
    assert_respond_to whitelist, :data_source
    assert_equal @whitelisted_api, whitelist.data_source
  end

  test "belongs to whitelistable polymorphic" do
    user_whitelist = data_source_whitelists(:alice_whitelist_api)
    group_whitelist = data_source_whitelists(:developers_whitelist_mqtt)
    
    assert_respond_to user_whitelist, :whitelistable
    assert_respond_to group_whitelist, :whitelistable
    
    assert_equal @alice, user_whitelist.whitelistable
    assert_equal @developers, group_whitelist.whitelistable
  end

  # ==================== Polymorphic Types ====================

  test "can whitelist a user" do
    whitelist = DataSourceWhitelist.new(
      data_source: @public_api,
      whitelistable: @bob
    )
    assert whitelist.save
    assert_equal "User", whitelist.whitelistable_type
  end

  test "can whitelist a user_group" do
    whitelist = DataSourceWhitelist.new(
      data_source: @public_api,
      whitelistable: @developers
    )
    assert whitelist.save
    assert_equal "UserGroup", whitelist.whitelistable_type
  end

  # ==================== CRUD ====================

  test "can create data_source_whitelist for user" do
    whitelist = DataSourceWhitelist.new(
      data_source: @public_api,
      whitelistable: @bob
    )
    assert whitelist.save
  end

  test "can create data_source_whitelist for group" do
    group = UserGroup.create!(name: "New Group")
    whitelist = DataSourceWhitelist.new(
      data_source: @public_api,
      whitelistable: group
    )
    assert whitelist.save
  end

  test "can destroy data_source_whitelist" do
    whitelist = DataSourceWhitelist.create!(
      data_source: @public_api,
      whitelistable: @bob
    )
    assert_difference "DataSourceWhitelist.count", -1 do
      whitelist.destroy
    end
  end

  # ==================== Data Source Access ====================

  test "user with whitelist has access to data source" do
    accessible = DataSource.accessible_for(@alice)
    assert_includes accessible, @whitelisted_api
  end

  test "group member has access to data source via group whitelist" do
    accessible = DataSource.accessible_for(@alice)
    assert_includes accessible, @private_mqtt
  end

  test "user without whitelist does not have access" do
    accessible = DataSource.accessible_for(@bob)
    assert_not_includes accessible, @whitelisted_api
  end
end
