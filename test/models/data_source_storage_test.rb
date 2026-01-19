require "test_helper"

class DataSourceStorageTest < ActiveSupport::TestCase
  def setup
    @alice = users(:alice)
    @public_api = data_sources(:public_api)
    @storage = data_source_storages(:public_api_storage_1)
  end

  # ==================== Associations ====================

  test "belongs to data_source" do
    assert_respond_to @storage, :data_source
    assert_equal @public_api, @storage.data_source
  end

  # ==================== Validations ====================

  test "value is required" do
    storage = DataSourceStorage.new(data_source: @public_api, stored_at: Time.current)
    storage.value = nil
    assert_not storage.valid?
    assert_includes storage.errors[:value], "can't be blank"
  end

  test "stored_at is required" do
    storage = DataSourceStorage.new(data_source: @public_api, value: { test: 1 })
    storage.stored_at = nil
    assert_not storage.valid?
    assert_includes storage.errors[:stored_at], "can't be blank"
  end

  test "sets stored_at automatically on create if not set" do
    storage = DataSourceStorage.new(data_source: @public_api, value: { test: 1 })
    storage.valid?
    assert_not_nil storage.stored_at
  end

  # ==================== Scopes ====================

  test "recent scope orders by stored_at desc" do
    storages = @public_api.data_source_storages.recent
    assert storages.first.stored_at >= storages.last.stored_at
  end

  test "oldest_first scope orders by stored_at asc" do
    storages = @public_api.data_source_storages.oldest_first
    assert storages.first.stored_at <= storages.last.stored_at
  end

  test "in_time_range scope filters by time range" do
    start_time = 2.hours.ago
    end_time = Time.current
    storages = @public_api.data_source_storages.in_time_range(start_time, end_time)
    
    storages.each do |s|
      assert s.stored_at >= start_time
      assert s.stored_at <= end_time
    end
  end

  test "since scope filters by minimum time" do
    time = 45.minutes.ago
    storages = @public_api.data_source_storages.since(time)
    
    storages.each do |s|
      assert s.stored_at >= time
    end
  end

  # ==================== CRUD ====================

  test "can create data_source_storage" do
    storage = DataSourceStorage.new(
      data_source: @public_api,
      value: { temperature: 25.0, humidity: 70 },
      stored_at: Time.current
    )
    assert storage.save
  end

  test "can update data_source_storage" do
    @storage.value = { temperature: 30.0 }
    assert @storage.save
    @storage.reload
    assert_equal 30.0, @storage.value["temperature"]
  end

  test "can destroy data_source_storage" do
    storage = DataSourceStorage.create!(
      data_source: @public_api,
      value: { test: "delete" },
      stored_at: Time.current
    )
    assert_difference "DataSourceStorage.count", -1 do
      storage.destroy
    end
  end

  # ==================== Value Content ====================

  test "value can store hash data" do
    assert_kind_of Hash, @storage.value
    assert_not_nil @storage.value["temperature"]
  end

  test "value can be accessed with string keys" do
    assert_equal 22.5, @storage.value["temperature"]
  end
end
