require "test_helper"
require "rack/test"
require "tempfile"
require "zlib"

class ValidPropertyUploadTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    account = Account.create!(
      email: "valid-upload-#{SecureRandom.hex(6)}@example.test",
      password: "test_password_123"
    )
    sign_in account
  end

  test "valid PNG is saved and thumbnail is generated" do
    property = nil

    Tempfile.create(["valid-property-", ".png"]) do |file|
      file.binmode
      file.write(valid_png)
      file.flush

      upload = Rack::Test::UploadedFile.new(
        file.path, "image/png", true
      )

      begin
        assert_difference "Property.count", 1 do
          post properties_path, params: {
            property: {
              name: "Valid image listing",
              address: "Test Street 20",
              price: 125000,
              rooms: 2,
              bathrooms: 1,
              photo: upload
            }
          }
        end

        property = Property.order(:id).last

        assert_redirected_to property_path(property)
        assert property.photo.present?
        assert File.file?(property.photo.path),
          "Original PNG was not stored"
        assert File.file?(property.photo.thumb.path),
          "Thumbnail was not generated"
      ensure
        property.photo.remove! if property
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

  def valid_png
    width = 16
    height = 16

    header = [width, height, 8, 2, 0, 0, 0].
      pack("NNCCCCC")

    row = "\x00".b + ("\x55\xAA\xCC".b * width)
    pixels = Zlib::Deflate.deflate(row * height)

    "\x89PNG\r\n\x1A\n".b +
      png_chunk("IHDR", header) +
      png_chunk("IDAT", pixels) +
      png_chunk("IEND", "".b)
  end
end
