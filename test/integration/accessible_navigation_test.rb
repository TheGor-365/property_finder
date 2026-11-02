require "test_helper"

class AccessibleNavigationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @agent = Account.create!(
      email: "accessible-nav-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!",
      password_confirmation: "samplePassword2026!"
    )
    @property = Property.create!(
      account: @agent, name: "Accessible Test Home",
      address: "Example location", price: 100_000
    )
  end

  test "mobile public navigation has a real collapse target" do
    get root_path
    assert_response :success
    assert_select 'button.navbar-toggler[aria-controls="navbarsExampleDefault"][aria-expanded="false"]', count: 1
    assert_select '#navbarsExampleDefault.collapse', count: 1
    assert_select 'a[aria-current="page"][href=?]', root_path, count: 1
  end

  test "sidebar identifies its purpose and only the current link" do
    sign_in @agent
    get dashboard_path
    assert_response :success
    assert_select 'nav#sidebarMenu[aria-label="Agent workspace navigation"]', count: 1
    assert_select 'nav#sidebarMenu a[aria-current="page"][href=?]', dashboard_path, count: 1
    assert_select 'nav#sidebarMenu a[aria-current="page"][href=?]', enquiries_path, count: 0

    get enquiries_path
    assert_response :success
    assert_select 'nav#sidebarMenu a[aria-current="page"][href=?]', enquiries_path, count: 1
    assert_select 'nav#sidebarMenu a[aria-current="page"][href=?]', dashboard_path, count: 0

    get edit_property_path(@property)
    assert_response :success
    assert_select 'nav#sidebarMenu a[aria-current="page"][href=?]', my_properties_path, count: 1
  end

  test "invalid public enquiry retains form values and an accessible modal alert" do
    post enquiries_path, params: { enquiry: {
      property_id: @property.id, name: "Visitor",
      email: "not-an-email", message: "short"
    } }
    assert_response :unprocessable_entity
    assert_select '#contact-modal[aria-labelledby="detail-contact-title"]', count: 1
    assert_select '#contact-modal .alert-danger[role="alert"]', minimum: 1
    assert_select '#contact-modal script', count: 0
    assert_select 'input[name="enquiry[name]"][value="Visitor"]', count: 1
  end
end
