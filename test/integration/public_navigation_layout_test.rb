require "test_helper"

class PublicNavigationLayoutTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    @agent = Account.create!(
      email: "nav-layout-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!"
    )
    @property = Property.create!(account: @agent,
      name: "Navigation Test Home", address: "Example Street", price: 100_000)
  end

  test "public routes use one in-flow sticky navbar without fixed positioning" do
    [
      root_path,
      properties_path,
      property_path(@property),
      blog_path,
      new_account_session_path
    ].each do |path|
      get path
      assert_response :success, "Failed public page: #{path}"
      assert_select "header.pf-public-header.sticky-top", count: 1
      assert_select "header.pf-public-header nav.pf-site-nav:not(.fixed-top)", count: 1
      assert_select "nav.fixed-top", count: 0
      assert_select "#flash-messages", count: 0, message: "An empty flash container must not create a blank bar below the navbar"
    end
  end

  test "successful login renders a visible notice without a permanent spacer" do
    post account_session_path, params: {
      account: { email: @agent.email, password: "samplePassword2026!" }
    }
    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_select "#flash-messages .alert-success", text: /Signed in successfully/
  end

  test "dashboard retains its separate sidebar layout" do
    sign_in @agent
    get dashboard_path
    assert_response :success
    assert_select "body.show_sidebar", count: 1
    assert_select "header.pf-public-header", count: 0
    assert_select "nav.sticky-top", minimum: 1
  end
end
