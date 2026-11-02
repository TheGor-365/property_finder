require "test_helper"

class AgentProfilePresentationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @agent = Account.create!(first_name: "Editorial", last_name: "Agent",
      email: "profile-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!")
    @active = Property.create!(account: @agent, name: "Visible demo home",
      address: "Sample Street", price: 2500, status: "available")
    @closed = Property.create!(account: @agent, name: "Not available home",
      address: "Sample Avenue", price: 1800, status: "sold")
  end

  test "public profile shows only available listing and no nonfunctional phone button" do
    get profile_path(@agent)
    assert_response :success
    assert_select "main.pf-agent-profile"
    assert_select "a[href=?]", property_path(@active), minimum: 1
    assert_select "a[href=?]", property_path(@closed), count: 0
    assert_select "#show-tel", count: 0
    assert_select "#contact-modal", count: 1
    assert_select "#toggleDetails", count: 0
  end

  test "property with enquiries cannot be destroyed or misreported as deleted" do
    Enquiry.create!(property: @active, name: "Visitor", email: "visitor@example.test",
      message: "I would like to see the layout.")
    sign_in @agent
    assert_no_difference "Property.count" do
      delete property_path(@active)
    end
    assert_redirected_to my_properties_path
    assert_match(/cannot be deleted/i, flash[:alert])
    assert @active.reload.persisted?
  end
end
