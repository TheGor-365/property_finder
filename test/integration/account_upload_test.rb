require "test_helper"
require "rack/test"
require "tempfile"

class AccountUploadTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @password = "test_password_123"

    @account = Account.create!(
      email: "account-upload-#{SecureRandom.hex(6)}@example.test",
      password: @password
    )

    sign_in @account
  end

  test "rejects invalid avatar through HTTP" do
    assert_invalid_upload(:image)
  end

  test "rejects invalid cover image through HTTP" do
    assert_invalid_upload(:cover_image)
  end

  private

  def assert_invalid_upload(attribute)
    Tempfile.create(["invalid-account-image-", ".png"]) do |file|
      file.binmode
      file.write("This is not a valid PNG image")
      file.flush

      upload = Rack::Test::UploadedFile.new(
        file.path, "image/png", true
      )

      put account_registration_path, params: {
        account: {
          current_password: @password,
          attribute => upload
        }
      }

      assert_response :unprocessable_entity
      assert_select "#error_explanation"

      @account.reload

      assert_nil @account.public_send("#{attribute}_identifier"),
        "Invalid image was persisted"
    end
  end
end
