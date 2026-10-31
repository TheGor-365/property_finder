require "tempfile"
require "zlib"

abort "STOP: test environment required" unless Rails.env.test?

expected_root = Rails.root.join("tmp", "property_finder_test_uploads").to_s

unless PhotoUploader.root.to_s == expected_root
  abort "STOP: unexpected upload storage root"
end

def png_chunk(type, data)
  type = type.b
  [data.bytesize].pack("N") +
    type + data +
    [Zlib.crc32(type + data)].pack("N")
end

width = 16
height = 16
header = [width, height, 8, 2, 0, 0, 0].pack("NNCCCCC")
row = "\x00".b + ("\x55\xAA\xCC".b * width)

png = "\x89PNG\r\n\x1A\n".b +
  png_chunk("IHDR", header) +
  png_chunk("IDAT", Zlib::Deflate.deflate(row * height)) +
  png_chunk("IEND", "".b)

account = nil
property = nil

begin
  Tempfile.create(["lifecycle-", ".png"]) do |file|
    file.binmode
    file.write(png)
    file.flush

    account = Account.create!(
      email: "lifecycle-#{SecureRandom.hex(8)}@example.test",
      password: "test_password_123"
    )

    File.open(file.path, "rb") do |image|
      property = Property.create!(
        account: account,
        name: "Image lifecycle test",
        address: "Test Street 30",
        price: 100000,
        rooms: 2,
        bathrooms: 1,
        photo: image
      )
    end

    original = property.photo.path
    thumbnail = property.photo.thumb.path

    raise "Original missing" unless File.file?(original)
    raise "Thumbnail missing" unless File.file?(thumbnail)

    puts "BEFORE_DESTROY=ORIGINAL_AND_THUMB_PRESENT"

    id = property.id
    property.destroy!

    raise "DB record remains" if Property.exists?(id)
    raise "Original remains" if File.exist?(original)
    raise "Thumbnail remains" if File.exist?(thumbnail)

    puts "AFTER_DESTROY=DB_AND_FILES_REMOVED"
    puts "PHOTO_LIFECYCLE=PASS"
  end
ensure
  property.destroy! if property && property.persisted?
  property.photo.remove! if property && property.photo.present?
  account.destroy! if account && account.persisted?
end
