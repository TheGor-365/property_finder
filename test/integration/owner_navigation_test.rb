require "test_helper"

class OwnerNavigationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = create_account("owner")
    @other = create_account("other")

    @own_property = Property.create!(
      account: @owner,
      name: "Owned property",
      address: "Owner street",
      price: 150000
    )

    @other_property = Property.create!(
      account: @other,
      name: "Private other property",
      address: "Other street",
      price: 200000
    )
  end

  test "guest cannot access private pages" do
    get dashboard_path
    assert_redirected_to new_account_session_path

    get my_properties_path
    assert_redirected_to new_account_session_path
  end

  test "owner dashboard shows only own properties" do
    sign_in @owner

    get dashboard_path

    assert_response :success
    assert_includes response.body, @own_property.name
    refute_includes response.body, @other_property.name
  end

  test "my properties contains only current owner listings" do
    sign_in @owner

    get my_properties_path

    assert_response :success
    assert_includes response.body, @own_property.name
    refute_includes response.body, @other_property.name
  end

  test "public catalog displays both properties" do
    get properties_path

    assert_response :success
    assert_includes response.body, @own_property.name
    assert_includes response.body, @other_property.name
    refute_includes response.body, "Destroy"
  end

  private

  def create_account(role)
    Account.create!(
      email: "#{role}-#{SecureRandom.hex(6)}@example.test",
      password: "test_password_123",
      password_confirmation: "test_password_123"
    )
  end
end
