require "test_helper"

class GuestNavigationTest < ActionDispatch::IntegrationTest
  test "guest can access public pages" do
    [root_path, properties_path, blog_path].each do |path|
      get path
      assert_response :success, "Expected HTTP 200 for #{path}"
    end
  end

  test "guest cannot access administrative pages" do
    [posts_path, accounts_path].each do |path|
      get path
      assert_redirected_to root_path
    end
  end

  test "guest is redirected before property management" do
    get edit_property_path(999999)
    assert_redirected_to new_account_session_path

    patch property_path(999999),
      params: { property: { name: "Unauthorized" } }
    assert_redirected_to new_account_session_path

    delete property_path(999999)
    assert_redirected_to new_account_session_path
  end
end
