require "test_helper"
require "rack/test"
require "tempfile"
require "zlib"

class AccountValidUploadTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @password = "test_password_123"

    @account = Account.create!(
      email: "valid-profile-#{SecureRandom.hex(6)}@example.test",
      password: @password
    )

    sign_in @account
  end

  test "valid avatar and cover are saved with thumbnails" do
    Tempfile.create(["pf-avatar-", ".png"]) do |avatar|
      Tempfile.create(["pf-cover-", ".png"]) do |cover|
        [[avatar, [255, 0, 0]], [cover, [0, 0, 255]]].each do |file, color|
          file.binmode
          file.write(make_png(color))
          file.flush
        end

        begin
          put account_registration_path, params: {
            account: {
              current_password: @password,
              first_name: "Upload Verified",
              image: Rack::Test::UploadedFile.new(
                avatar.path, "image/png", true
              ),
              cover_image: Rack::Test::UploadedFile.new(
                cover.path, "image/png", true
              )
            }
          }

          assert_response :redirect

          @account.reload
          assert_equal "Upload Verified", @account.first_name

          [:image, :cover_image].each do |attribute|
            uploader = @account.public_send(attribute)

            assert uploader.present?, "#{attribute} not saved"
            assert File.file?(uploader.path), "#{attribute} original missing"
            assert File.file?(uploader.thumb.path), "#{attribute} thumbnail missing"

            thumbnail = MiniMagick::Image.open(uploader.thumb.path)

            assert_equal 200, thumbnail.width
            assert_equal 200, thumbnail.height
          end
        ensure
          @account.image.remove! if @account.image.present?
          @account.cover_image.remove! if @account.cover_image.present?
        end
      end
    end
  end

  private

  def png_chunk(type, data)
    type = type.b
    [data.bytesize].pack("N") +
      type + data +
      [Zlib.crc32(type + data)].pack("N")
  end

  def make_png(rgb)
    width = 16
    height = 16

    header = [width, height, 8, 2, 0, 0, 0].pack("NNCCCCC")
    row = "\x00".b + (rgb.pack("C3") * width)

    "\x89PNG\r\n\x1A\n".b +
      png_chunk("IHDR", header) +
      png_chunk("IDAT", Zlib::Deflate.deflate(row * height)) +
      png_chunk("IEND", "".b)
  end
end
