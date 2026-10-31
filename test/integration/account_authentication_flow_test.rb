require "test_helper"
require "securerandom"

class AccountAuthenticationFlowTest < ActionDispatch::IntegrationTest
  PASSWORD = "test_password_123"

  test "visitor can register and access dashboard" do
    email = unique_email

    assert_difference "Account.count", 1 do
      post account_registration_path, params: {
        account: {
          email: email,
          password: PASSWORD,
          password_confirmation: PASSWORD,
          first_name: "Test",
          last_name: "User"
        }
      }
    end

    assert_response :redirect
    assert_equal "Test", Account.find_by!(email: email).first_name

    get dashboard_path
    assert_response :success
  end

  test "wrong password does not grant access" do
    account = create_account

    post account_session_path, params: {
      account: {
        email: account.email,
        password: "incorrect_password"
      }
    }

    get dashboard_path
    assert_redirected_to new_account_session_path
  end

  test "login and logout control the session" do
    account = create_account

    get dashboard_path
    assert_redirected_to new_account_session_path

    post account_session_path, params: {
      account: {
        email: account.email,
        password: PASSWORD
      }
    }

    assert_response :redirect

    get dashboard_path
    assert_response :success

    delete destroy_account_session_path
    assert_response :redirect

    get dashboard_path
    assert_redirected_to new_account_session_path
  end

  test "password recovery generates token and test email" do
    account = create_account

    get new_account_password_path
    assert_response :success

    ActionMailer::Base.deliveries.clear

    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      post account_password_path, params: {
        account: { email: account.email }
      }
    end

    assert_response :redirect
    assert_predicate account.reload.reset_password_token, :present?
    assert_equal [account.email], ActionMailer::Base.deliveries.last.to
  end

  private

  def unique_email
    "auth-#{SecureRandom.hex(8)}@example.test"
  end

  def create_account
    Account.create!(
      email: unique_email,
      password: PASSWORD,
      password_confirmation: PASSWORD
    )
  end
end
