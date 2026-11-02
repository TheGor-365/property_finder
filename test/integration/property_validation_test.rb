require "test_helper"

class PropertyValidationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    account = Account.create!(
      email: "validation-#{SecureRandom.hex(6)}@example.test",
      password: "test_password_123"
    )

    sign_in account

    @attributes = {
      name: "Valid property",
      address: "Test Street 1",
      price: 100000,
      rooms: 2,
      bathrooms: 1,
      parking_spaces: 0
    }
  end

  test "blank property name is rejected" do
    assert_no_difference "Property.count" do
      post properties_path,
        params: { property: @attributes.merge(name: "") },
        as: :json
    end

    assert_response :unprocessable_entity
  end

  test "negative price is rejected" do
    assert_no_difference "Property.count" do
      post properties_path,
        params: { property: @attributes.merge(price: -100) },
        as: :json
    end

    assert_response :unprocessable_entity
  end

  test "negative room count is rejected" do
    assert_no_difference "Property.count" do
      post properties_path,
        params: { property: @attributes.merge(rooms: -1) },
        as: :json
    end

    assert_response :unprocessable_entity
  end
  test "html form keeps values after validation failure" do
    assert_no_difference "Property.count" do
      post properties_path,
        params: { property: @attributes.merge(name: "") }
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
    assert_select '#error_explanation[role="alert"]', count: 1
    assert_includes CGI.unescapeHTML(response.body), "Name can't be blank"
    assert_select 'input[name="property[address]"][value="Test Street 1"]'
  end

  test "html form rejects negative price" do
    assert_no_difference "Property.count" do
      post properties_path,
        params: { property: @attributes.merge(price: -100) }
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
    assert_select '#error_explanation[role="alert"]', count: 1
  end

end
