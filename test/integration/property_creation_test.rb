require "test_helper"

class PropertyCreationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = create_account("owner")
    @other = create_account("other")

    @attributes = {
      name: "New test listing",
      address: "Example Street 10",
      price: 125000,
      rooms: 3,
      bathrooms: 2
    }
  end

  test "guest cannot create property" do
    assert_no_difference "Property.count" do
      post properties_path, params: {
        property: @attributes
      }
    end

    assert_redirected_to new_account_session_path
  end

  test "new property belongs to authenticated account" do
    sign_in @owner

    assert_difference "Property.count", 1 do
      post properties_path, params: {
        property: @attributes.merge(account_id: @other.id)
      }
    end

    property = Property.order(:id).last

    assert_redirected_to property_path(property)
    assert_equal @owner.id, property.account_id
    assert_equal "New test listing", property.name
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
