require "test_helper"

class PersistentUploadStorageTest < ActiveSupport::TestCase
  test "development and test uploads remain unaffected" do
    %w[test development].each do |environment|
      assert PersistentUploadStorage.verify!(
        environment: environment, public_root: "/app/public", mount_path: nil)
    end
  end

  test "production requires exact absolute uploads volume path" do
    [nil, "", "/app", "/app/public", "/app/uploads", "/app/public/uploads-other",
      "public/uploads"].each do |mount|
      assert_raises(CarrierWave::IntegrityError) do
        PersistentUploadStorage.verify!(environment: "production",
          public_root: "/app/public", mount_path: mount, writable: true)
      end
    end
  end

  test "production refuses unwritable uploads volume" do
    assert_raises(CarrierWave::IntegrityError) do
      PersistentUploadStorage.verify!(environment: "production",
        public_root: "/app/public", mount_path: "/app/public/uploads", writable: false)
    end
  end

  test "production permits verified writable mount path" do
    assert PersistentUploadStorage.verify!(environment: "production",
      public_root: "/app/public", mount_path: "/app/public/uploads", writable: true)
  end
end
