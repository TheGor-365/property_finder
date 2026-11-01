require "test_helper"

class HomepagePresentationTest < ActionDispatch::IntegrationTest
  test "guest homepage has working catalogue and blog navigation" do
    get root_path

    assert_response :success
    assert_select "main#home-banner"
    assert_select "section#latest_properties"
    assert_select "section#latest_posts"
    assert_select "a[href=?]", properties_path, minimum: 1
    assert_select "a[href=?]", blog_path, minimum: 1
    assert_select "main a[href='#']", 0
    refute_includes response.body, "Lorem ipsum"
  end
end
