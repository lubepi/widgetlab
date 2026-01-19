require "test_helper"

class DataSourcesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @alice = users(:alice)
    @bob = users(:bob)
    @admin = users(:admin)
    @public_api = data_sources(:public_api)
    @private_mqtt = data_sources(:private_mqtt)
    @whitelisted_api = data_sources(:whitelisted_api)
  end

  # ==================== Authentication ====================

  test "index redirects to login when not authenticated" do
    get data_sources_url
    assert_redirected_to login_path
  end

  # ==================== Index ====================

  test "index returns success when authenticated" do
    get data_sources_url, headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  test "index lists all data sources" do
    get data_sources_url, headers: { "Cookie" => login_as(@admin) }
    assert_response :success
  end

  # ==================== New ====================

  test "new returns success" do
    get new_data_source_url, headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  # ==================== Create ====================

  test "create creates data source" do
    assert_difference "DataSource.count", 1 do
      post data_sources_url,
        params: { data_source: { 
          name: "New API",
          source_type: "json_api",
          config: { url: "https://api.test.com", interval: 60 },
          is_public: true
        } },
        headers: { "Cookie" => login_as(@alice) }
    end
  end

  test "create assigns creator to current user" do
    post data_sources_url,
      params: { data_source: { 
        name: "New API",
        source_type: "json_api",
        config: { url: "https://api.test.com", interval: 60 }
      } },
      headers: { "Cookie" => login_as(@alice) }
    
    assert_equal @alice, DataSource.last.creator
  end

  test "create with invalid params renders new" do
    post data_sources_url,
      params: { data_source: { name: "", source_type: "json_api" } },
      headers: { "Cookie" => login_as(@alice) }
    assert_response :unprocessable_entity
  end

  # ==================== Edit ====================

  test "edit returns success" do
    get edit_data_source_url(@public_api), headers: { "Cookie" => login_as(@admin) }
    assert_response :success
  end

  # ==================== Update ====================

  test "update updates data source" do
    patch data_source_url(@public_api),
      params: { data_source: { name: "Updated API" } },
      headers: { "Cookie" => login_as(@admin) }
    
    @public_api.reload
    assert_equal "Updated API", @public_api.name
  end

  # ==================== Destroy ====================

  test "destroy deletes data source" do
    data_source = DataSource.create!(
      name: "To Delete",
      source_type: :json_api,
      config: { url: "https://test.com", interval: 60 },
      creator: @alice
    )
    
    assert_difference "DataSource.count", -1 do
      delete data_source_url(data_source), headers: { "Cookie" => login_as(@alice) }
    end
  end

  # ==================== Config Fields ====================

  test "config_fields returns json_api fields" do
    get config_fields_data_sources_url(type: "json_api"), headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  test "config_fields returns mqtt fields" do
    get config_fields_data_sources_url(type: "mqtt"), headers: { "Cookie" => login_as(@alice) }
    assert_response :success
  end

  private

  def login_as(user)
    post "/session", params: { sub: user.sub, email: user.email, first_name: user.first_name, last_name: user.last_name }
    response.headers["Set-Cookie"]
  end
end
