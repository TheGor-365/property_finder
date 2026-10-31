require "tempfile"
require "zlib"
require "securerandom"

abort "STOP: test environment required" unless Rails.env.test?

expected_root = Rails.root.join("tmp", "property_finder_test_uploads").to_s
abort "STOP: unexpected storage root" unless PhotoUploader.root.to_s == expected_root

def make_png(rgb)
  width = 16
  height = 16
  header = [width, height, 8, 2, 0, 0, 0].pack("NNCCCCC")
  row = "\x00".b + rgb.pack("C3") * width

  chunk = lambda do |type, data|
    type = type.b
    [data.bytesize].pack("N") + type + data +
      [Zlib.crc32(type + data)].pack("N")
  end

  "\x89PNG\r\n\x1A\n".b +
    chunk.call("IHDR", header) +
    chunk.call("IDAT", Zlib::Deflate.deflate(row * height)) +
    chunk.call("IEND", "".b)
end

account = nil
property = nil

begin
  Tempfile.create(["pf-old-", ".png"]) do |old_file|
    Tempfile.create(["pf-new-", ".png"]) do |new_file|
      [[old_file, [255, 0, 0]], [new_file, [0, 0, 255]]].each do |file, color|
        file.binmode
        file.write(make_png(color))
        file.flush
      end

      account = Account.create!(
        email: "photo-update-#{SecureRandom.hex(8)}@example.test",
        password: "test_password_123"
      )

      File.open(old_file.path, "rb") do |image|
        property = Property.create!(
          account: account,
          name: "Photo update test",
          address: "Test Street 40",
          price: 100000,
          rooms: 2,
          bathrooms: 1,
          photo: image
        )
      end

      old_original = property.photo.path
      old_thumb = property.photo.thumb.path

      raise "Initial original missing" unless File.file?(old_original)
      raise "Initial thumbnail missing" unless File.file?(old_thumb)

      File.open(new_file.path, "rb") do |image|
        property.update!(photo: image)
      end

      property.reload
      new_original = property.photo.path
      new_thumb = property.photo.thumb.path

      raise "Photo path did not change" if old_original == new_original

      raise "New original missing" unless File.file?(new_original)
      raise "New thumbnail missing" unless File.file?(new_thumb)
      puts "NEW_PHOTO_AND_THUMB=PASS"

      raise "Old original remains" if File.exist?(old_original)
      raise "Old thumbnail remains" if File.exist?(old_thumb)
      puts "OLD_PHOTO_AND_THUMB_REMOVED=PASS"

      property.destroy!
      puts "PHOTO_UPDATE_LIFECYCLE=PASS"
    end
  end
ensure
  property.destroy! if property && property.persisted?
  account.destroy! if account && account.persisted?
end
