require "test_helper"
require "tempfile"
require "rack/test"

class PropertyUploadTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    account = Account.create!(
      email: "upload-#{SecureRandom.hex(6)}@example.test",
      password: "test_password_123"
    )

    sign_in account

    @attributes = {
      name: "Upload test property",
      address: "Test street 10",
      price: 100000,
      rooms: 2,
      bathrooms: 1
    }
  end

  test "rejects fake PNG through HTTP" do
    with_file(".png", "not a real image") do |upload|
      assert_rejected_upload(upload)
    end
  end

  test "rejects GIF through HTTP" do
    with_file(".gif", "GIF89a") do |upload|
      assert_rejected_upload(upload)
    end
  end

  test "rejects oversized upload through HTTP" do
    content = "\0" * (5 * 1024 * 1024 + 1)

    with_file(".png", content) do |upload|
      assert_rejected_upload(upload)
    end
  end

  private

  def with_file(extension, content)
    Tempfile.create(["property-upload-", extension]) do |file|
      file.binmode
      file.write(content)
      file.flush
      file.rewind

      upload = Rack::Test::UploadedFile.new(
        file.path,
        extension == ".gif" ? "image/gif" : "image/png",
        true
      )

      yield upload
    end
  end

  def assert_rejected_upload(upload)
    assert_no_difference "Property.count" do
      post properties_path,
        params: { property: @attributes.merge(photo: upload) }
    end

    assert_response :unprocessable_entity
    assert_select "#error_explanation"
  end
end
