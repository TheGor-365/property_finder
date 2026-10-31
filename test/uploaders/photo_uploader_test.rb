require "test_helper"
require "tempfile"

class PhotoUploaderTest < ActiveSupport::TestCase
  test "rejects unsupported GIF extension" do
    with_upload(".gif", "GIF89a") do |file|
      assert_raises(CarrierWave::IntegrityError) do
        PhotoUploader.new.cache!(file)
      end
    end
  end

  test "rejects fake PNG content" do
    with_upload(".png", "not an image") do |file|
      assert_raises(CarrierWave::IntegrityError) do
        PhotoUploader.new.cache!(file)
      end
    end
  end

  test "rejects files larger than 5 MB" do
    with_upload(".png", "\0" * (5 * 1024 * 1024 + 1)) do |file|
      assert_raises(CarrierWave::IntegrityError) do
        PhotoUploader.new.cache!(file)
      end
    end
  end

  private

  def with_upload(extension, content)
    Tempfile.create(["photo-upload-", extension]) do |temp|
      temp.binmode
      temp.write(content)
      temp.flush

      File.open(temp.path, "rb") do |file|
        yield file
      end
    end
  end
end
