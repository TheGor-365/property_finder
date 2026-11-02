require "test_helper"

class HealthEndpointTest < ActionDispatch::IntegrationTest
  test "database-backed health endpoint responds without authentication" do
    get healthz_path
    assert_response :success
    assert_equal "", response.body
  end
end
