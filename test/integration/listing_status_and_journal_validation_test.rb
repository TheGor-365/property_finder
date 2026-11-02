require "test_helper"

class ListingStatusAndJournalValidationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @agent = Account.create!(
      email: "status-owner-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!"
    )
    sign_in @agent
  end

  test "rental cannot be marked sold and preserves form selection on failure" do
    assert_no_difference "Property.count" do
      post properties_path, params: {
        property: { name: "Example rental", address: "Sample lane", price: 1250,
          for_sale: false, status: "sold" }
      }
    end
    assert_response :unprocessable_entity
    assert_select "#error_explanation", text: /Status is not valid/
    assert_select "select[name='property[status]']"
  end

  test "sale cannot be marked leased" do
    property = Property.create!(account: @agent, name: "Example home", address: "Sample road", price: 100000)
    patch property_path(property), params: { property: { status: "leased" } }
    assert_response :unprocessable_entity
    assert_equal "available", property.reload.status
  end

  test "post without title or body cannot be published" do
    admin = Account.create!(email: "editor-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!", admin: true)
    sign_out @agent
    sign_in admin
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { title: "", body: "", active: true } }
    end
    assert_response :unprocessable_entity
  end
end
