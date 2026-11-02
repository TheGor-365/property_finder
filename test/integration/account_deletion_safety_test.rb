require "test_helper"

class AccountDeletionSafetyTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "an account with listings cannot be deleted and orphan records" do
    agent = Account.create!(
      email: "delete-guard-#{SecureRandom.hex(5)}@example.test",
      password: "samplePassword2026!", password_confirmation: "samplePassword2026!"
    )
    property = Property.create!(account: agent, name: "Protected listing",
      address: "Sample address", price: 1000)

    sign_in agent
    assert_no_difference ["Account.count", "Property.count"] do
      delete account_registration_path
    end

    assert_redirected_to edit_account_registration_path
    assert_match(/before deleting your account/i, flash[:alert])
    assert_equal agent.id, property.reload.account_id
  end
end
