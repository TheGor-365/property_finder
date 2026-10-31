require "test_helper"
require "tempfile"

class ProfilePictureUploaderTest < ActiveSupport::TestCase
  test "rejects GIF" do
    check_rejected(".gif", "GIF89a")
  end

  test "rejects fake PNG" do
    check_rejected(".png", "not a PNG")
  end

  test "rejects files larger than 5 MB" do
    check_rejected(".png", "\0" * (5 * 1024 * 1024 + 1))
  end

  private

  def check_rejected(extension, content)
    Tempfile.create(["profile-test-", extension]) do |temp|
      temp.binmode
      temp.write(content)
      temp.flush

      File.open(temp.path, "rb") do |file|
        assert_raises(CarrierWave::IntegrityError) do
          ProfilePictureUploader.new.cache!(file)
        end
      end
    end
  end
end
