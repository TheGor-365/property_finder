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

  test "password reset link changes credentials" do
    require "nokogiri"
    require "uri"

    account = create_account
    ActionMailer::Base.deliveries.clear

    post account_password_path, params: {
      account: { email: account.email }
    }

    assert_response :redirect

    mail = ActionMailer::Base.deliveries.last
    assert mail, "Password reset email missing"
    assert_includes mail.to, account.email

    html = mail.html_part ? mail.html_part.body.decoded : mail.body.decoded
    link = Nokogiri::HTML(html).at_css("a[href]")

    assert link, "Password reset link missing"

    uri = URI.parse(link["href"])

    assert_equal "example.test", uri.host
    assert_equal edit_account_password_path, uri.path

    token = URI.decode_www_form(uri.query.to_s)
      .to_h.fetch("reset_password_token")

    assert token.present?

    get edit_account_password_path,
      params: { reset_password_token: token }

    assert_response :success

    new_password = "new_test_password_456"

    patch account_password_path, params: {
      account: {
        reset_password_token: token,
        password: new_password,
        password_confirmation: new_password
      }
    }

    assert_response :redirect

    account.reload

    assert account.valid_password?(new_password)
    refute account.valid_password?(PASSWORD)
    assert_nil account.reset_password_token

    delete destroy_account_session_path

    post account_session_path, params: {
      account: {
        email: account.email,
        password: PASSWORD
      }
    }

    get dashboard_path
    assert_redirected_to new_account_session_path

    post account_session_path, params: {
      account: {
        email: account.email,
        password: new_password
      }
    }

    get dashboard_path
    assert_response :success
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
