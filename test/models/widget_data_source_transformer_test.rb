require "test_helper"

class WidgetDataSourceTransformerTest < ActiveSupport::TestCase
  def setup
    @alice_widget = widgets(:alice_widget)
    @public_api = data_sources(:public_api)
    @transformer = widget_data_source_transformers(:alice_widget_transformer)
  end

  # ==================== Associations ====================

  test "belongs to widget" do
    assert_respond_to @transformer, :widget
    assert_equal @alice_widget, @transformer.widget
  end

  test "belongs to data_source" do
    assert_respond_to @transformer, :data_source
    assert_equal @public_api, @transformer.data_source
  end

  # ==================== Transform Method ====================

  test "transform returns original value when config is blank" do
    transformer = WidgetDataSourceTransformer.new(config: nil)
    assert_equal 42, transformer.transform(42)
  end

  test "transform extracts json_path from hash" do
    transformer = WidgetDataSourceTransformer.new(config: { json_path: "temperature" })
    result = transformer.transform({ "temperature" => 25.5, "humidity" => 60 })
    assert_equal 25.5, result
  end

  test "transform extracts nested json_path" do
    transformer = WidgetDataSourceTransformer.new(config: { json_path: "data.value" })
    result = transformer.transform({ "data" => { "value" => 100 } })
    assert_equal 100, result
  end

  test "transform applies multiply" do
    transformer = WidgetDataSourceTransformer.new(config: { multiply: 2 })
    result = transformer.transform(10)
    assert_equal 20.0, result
  end

  test "transform applies add" do
    transformer = WidgetDataSourceTransformer.new(config: { add: 5 })
    result = transformer.transform(10)
    assert_equal 15.0, result
  end

  test "transform applies round" do
    transformer = WidgetDataSourceTransformer.new(config: { round: 2 })
    result = transformer.transform(3.14159)
    assert_equal 3.14, result
  end

  test "transform applies multiple transformations in order" do
    transformer = WidgetDataSourceTransformer.new(config: { 
      json_path: "value",
      multiply: 2,
      add: 10,
      round: 1
    })
    result = transformer.transform({ "value" => 5.555 })
    assert_equal 21.1, result
  end

  test "transform with format number converts to number" do
    transformer = WidgetDataSourceTransformer.new(config: { format: "number" })
    result = transformer.transform("42")
    assert_equal 42.0, result
  end

  test "transform with format string converts to string" do
    transformer = WidgetDataSourceTransformer.new(config: { format: "string" })
    result = transformer.transform(42)
    assert_equal "42", result
  end

  test "transform with format boolean converts to boolean" do
    transformer = WidgetDataSourceTransformer.new(config: { format: "boolean" })
    assert_equal true, transformer.transform(1)
    assert_equal false, transformer.transform(0)
  end

  # ==================== CRUD ====================

  test "can create widget_data_source_transformer" do
    widget = Widget.create!(name: "New Widget", widget_type: :value)
    transformer = WidgetDataSourceTransformer.new(
      widget: widget,
      data_source: @public_api,
      config: { json_path: "temperature" }
    )
    assert transformer.save
  end

  test "can update widget_data_source_transformer" do
    @transformer.config = { json_path: "humidity", multiply: 0.01 }
    assert @transformer.save
    @transformer.reload
    assert_equal "humidity", @transformer.config["json_path"]
  end

  test "can destroy widget_data_source_transformer" do
    widget = Widget.create!(name: "Test Widget", widget_type: :value)
    transformer = WidgetDataSourceTransformer.create!(
      widget: widget,
      data_source: @public_api
    )
    assert_difference "WidgetDataSourceTransformer.count", -1 do
      transformer.destroy
    end
  end
end
