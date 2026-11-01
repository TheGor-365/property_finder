require "test_helper"

class JavascriptAssetDeliveryTest < ActionDispatch::IntegrationTest
  test "root page includes esbuild asset instead of webpacker pack" do
    get root_path

    assert_response :success
    assert_select 'script[src^="/assets/application"]', 1
    assert_select 'script[src*="/packs/"]', 0
  end
end
