require "test_helper"

class PropertyAuthorizationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = create_account("owner")
    @other = create_account("other")
    @admin = create_account("admin", admin: true)

    @property = Property.create!(
      account: @owner,
      name: "Original property",
      address: "Test address",
      price: 125000
    )
  end

  test "guest cannot manage a property" do
    get edit_property_path(@property)
    assert_redirected_to new_account_session_path

    patch property_path(@property),
      params: { property: { name: "Unauthorized change" } }
    assert_redirected_to new_account_session_path

    delete property_path(@property)
    assert_redirected_to new_account_session_path

    assert_equal "Original property", @property.reload.name
  end

  test "another account cannot manage a property" do
    sign_in @other

    get edit_property_path(@property)
    assert_response :forbidden

    patch property_path(@property),
      params: { property: { name: "Unauthorized change" } }
    assert_response :forbidden

    delete property_path(@property)
    assert_response :forbidden

    assert_equal "Original property", @property.reload.name
  end

  test "owner can update and delete own property" do
    sign_in @owner

    patch property_path(@property),
      params: { property: { name: "Updated property" } }

    assert_redirected_to property_path(@property)
    assert_equal "Updated property", @property.reload.name

    assert_difference "Property.count", -1 do
      delete property_path(@property)
    end

    assert_redirected_to properties_path
  end

  test "admin cannot modify property owned by another account" do
    sign_in @admin

    patch property_path(@property),
      params: { property: { name: "Admin change" } }
    assert_response :forbidden

    delete property_path(@property)
    assert_response :forbidden

    assert_equal "Original property", @property.reload.name
  end

  private

  def create_account(role, admin: false)
    password = "test_password_123"

    Account.create!(
      email: "#{role}-#{SecureRandom.hex(6)}@example.test",
      password: password,
      password_confirmation: password,
      admin: admin
    )
  end
end
