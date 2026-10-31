# Keep automated-test uploads separate from real development files.
if Rails.env.test?
  CarrierWave.configure do |config|
    config.root = Rails.root.join("tmp", "property_finder_test_uploads").to_s
  end
end
