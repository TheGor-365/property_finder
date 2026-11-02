# CarrierWave's file storage lives under public/uploads. In an ephemeral
# production container those files disappear on redeploy unless uploads is an
# actual persistent volume. Fail safely on store rather than silently losing
# customer media. These checks do not alter test/development storage.
module PersistentUploadStorage
  def self.verify!(environment:, public_root:, mount_path:, writable: nil)
    return true unless environment.to_s == "production"

    uploads = File.expand_path("uploads", public_root.to_s)
    mount = mount_path.to_s.strip

    unless mount.start_with?("/") && File.expand_path(mount) == uploads
      raise CarrierWave::IntegrityError,
        "Media upload unavailable: configure a persistent volume mounted exactly at #{uploads}"
    end

    writable = File.directory?(uploads) && File.writable?(uploads) if writable.nil?
    unless writable
      raise CarrierWave::IntegrityError,
        "Media upload unavailable: persistent uploads directory is not writable"
    end

    true
  end

  def verify_persistent_upload_storage!(_file = nil)
    return unless Rails.env.production?

    mount = ENV["RAILWAY_VOLUME_MOUNT_PATH"] ||
      ENV["PROPERTY_FINDER_UPLOADS_VOLUME_MOUNT"]

    PersistentUploadStorage.verify!(
      environment: Rails.env,
      public_root: Rails.root.join("public"),
      mount_path: mount
    )
  end
end
