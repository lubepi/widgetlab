require "test_helper"

class DataSourceTest < ActiveSupport::TestCase
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @charlie = users(:charlie)
    @admin = users(:admin)
    @public_api = data_sources(:public_api)
    @private_mqtt = data_sources(:private_mqtt)
    @whitelisted_api = data_sources(:whitelisted_api)
    @error_source = data_sources(:error_source)
    @developers = user_groups(:developers)
  end

  # ==================== Associations ====================

  test "belongs to creator" do
    assert_respond_to @public_api, :creator
    assert_equal @admin, @public_api.creator
  end

  test "has many widget_data_source_transformers" do
    assert_respond_to @public_api, :widget_data_source_transformers
  end

  test "has many widgets through widget_data_source_transformers" do
    assert_respond_to @public_api, :widgets
  end

  test "has many data_source_storages" do
    assert_respond_to @public_api, :data_source_storages
    assert @public_api.data_source_storages.count > 0
  end

  test "has many data_source_whitelists" do
    assert_respond_to @whitelisted_api, :data_source_whitelists
    assert @whitelisted_api.data_source_whitelists.count > 0
  end

  # ==================== Enums ====================

  test "source_type enum includes json_api and mqtt" do
    assert DataSource.source_types.keys.include?("json_api")
    assert DataSource.source_types.keys.include?("mqtt")
  end

  test "status enum includes inactive, ok, and error" do
    assert DataSource.statuses.keys.include?("inactive")
    assert DataSource.statuses.keys.include?("ok")
    assert DataSource.statuses.keys.include?("error")
  end

  test "can check status" do
    assert @public_api.ok?
    assert @whitelisted_api.inactive?
    assert @error_source.error?
  end

  # ==================== Validations ====================

  test "name is required" do
    data_source = DataSource.new(source_type: :json_api, config: { url: "http://test.com" }, creator: @alice)
    assert_not data_source.valid?
    assert data_source.errors[:name].any?, "Expected errors on name"
  end

  test "source_type is required" do
    data_source = DataSource.new(name: "Test", config: { url: "http://test.com" }, creator: @alice)
    assert_not data_source.valid?
    assert data_source.errors[:source_type].any?, "Expected errors on source_type"
  end

  test "config is required" do
    data_source = DataSource.new(name: "Test", source_type: :json_api, creator: @alice)
    assert_not data_source.valid?
    assert data_source.errors[:config].any?, "Expected errors on config"
  end

  # ==================== Accessible For Scope ====================

  test "accessible_for returns public data sources for any user" do
    accessible = DataSource.accessible_for(@charlie)
    assert_includes accessible, @public_api
  end

  test "accessible_for returns public data sources for nil user" do
    accessible = DataSource.accessible_for(nil)
    assert_includes accessible, @public_api
    assert_not_includes accessible, @private_mqtt
  end

  test "accessible_for includes whitelisted data sources for user" do
    accessible = DataSource.accessible_for(@alice)
    assert_includes accessible, @whitelisted_api
  end

  test "accessible_for includes data sources via group whitelist" do
    accessible = DataSource.accessible_for(@alice)
    assert_includes accessible, @private_mqtt
  end

  test "accessible_for excludes private data sources without access" do
    # Charlie is a member of developers group which has access to private_mqtt
    # so we need to test with a user who has no group access
    accessible = DataSource.accessible_for(@charlie)
    # Charlie can access private_mqtt through developers group, so only check whitelisted_api
    # which is only whitelisted for alice directly
    assert_not_includes accessible, @whitelisted_api
  end

  # ==================== Status Methods ====================

  test "mark_attempt! updates last_attempt_at" do
    @public_api.mark_attempt!
    assert_not_nil @public_api.last_attempt_at
    assert_in_delta Time.current.to_i, @public_api.last_attempt_at.to_i, 2
  end

  test "mark_success! sets status to ok and clears error" do
    @error_source.mark_success!
    assert @error_source.ok?
    assert_nil @error_source.last_error
    assert_not_nil @error_source.last_success_at
  end

  test "mark_error! sets status to error and stores message" do
    @public_api.mark_error!("Connection failed")
    assert @public_api.error?
    assert_equal "Connection failed", @public_api.last_error
  end

  # ==================== Store Value ====================

  test "store_value creates data_source_storage record" do
    assert_difference "@public_api.data_source_storages.count", 1 do
      @public_api.store_value({ temperature: 25.5 })
    end
  end

  test "store_value accepts stored_at parameter" do
    time = 2.hours.ago
    @public_api.store_value({ temp: 20 }, stored_at: time)
    
    storage = @public_api.data_source_storages.order(created_at: :desc).first
    assert_in_delta time.to_i, storage.stored_at.to_i, 2
  end

  # ==================== Latest Values ====================

  test "latest_values returns recent storages" do
    values = @public_api.latest_values(limit: 5)
    assert_equal DataSourceStorage, values.first.class
  end

  test "latest_value returns most recent storage" do
    value = @public_api.latest_value
    assert_not_nil value
  end

  # ==================== Typed Config ====================

  test "typed_config returns JsonApi config for json_api type" do
    config = @public_api.typed_config
    assert_instance_of DataSources::Configs::JsonApi, config
  end

  test "typed_config returns Mqtt config for mqtt type" do
    config = @private_mqtt.typed_config
    assert_instance_of DataSources::Configs::Mqtt, config
  end

  # ==================== Dependent Destroy ====================

  test "destroying data_source destroys associated storages" do
    data_source = DataSource.create!(
      name: "Test",
      source_type: :json_api,
      config: { url: "http://test.com", interval: 60 },
      creator: @alice
    )
    data_source.store_value({ test: 1 })
    
    assert_difference "DataSourceStorage.count", -1 do
      data_source.destroy
    end
  end

  test "destroying data_source destroys associated whitelists" do
    data_source = DataSource.create!(
      name: "Test",
      source_type: :json_api,
      config: { url: "http://test.com", interval: 60 },
      creator: @alice
    )
    DataSourceWhitelist.create!(data_source: data_source, whitelistable: @bob)
    
    assert_difference "DataSourceWhitelist.count", -1 do
      data_source.destroy
    end
  end

  # ==================== CRUD ====================

  test "can create data source with valid attributes" do
    data_source = DataSource.new(
      name: "New API",
      source_type: :json_api,
      config: { url: "http://api.test.com", interval: 120 },
      creator: @alice,
      is_public: true
    )
    assert data_source.save
  end

  test "can update data source" do
    @public_api.name = "Updated API Name"
    assert @public_api.save
    @public_api.reload
    assert_equal "Updated API Name", @public_api.name
  end

  test "can destroy data source" do
    data_source = DataSource.create!(
      name: "To Delete",
      source_type: :mqtt,
      config: { broker: "mqtt://test.com", topic: "test" },
      creator: @alice
    )
    assert_difference "DataSource.count", -1 do
      data_source.destroy
    end
  end
end
