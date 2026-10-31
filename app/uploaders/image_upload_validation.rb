module ImageUploadValidation
  def self.included(base)
    base.before :cache, :validate_image_upload!
  end

  MAX_UPLOAD_BYTES = 5 * 1024 * 1024


  def extension_white_list
    %w(jpg jpeg png)
  end

  private

  def validate_image_upload!(file)
    if file.size > MAX_UPLOAD_BYTES
      raise CarrierWave::IntegrityError, "Image exceeds 5 MB"
    end

    header = if file.path && ::File.file?(file.path)
      ::File.open(file.path, "rb") { |f| f.read(8).to_s.b }
    elsif file.file.respond_to?(:read) &&
          file.file.respond_to?(:rewind)
      io = file.file
      position = io.pos if io.respond_to?(:pos)
      io.rewind
      result = io.read(8).to_s.b
      io.seek(position) if !position.nil? && io.respond_to?(:seek)
      result
    else
      "".b
    end

    valid = case file.extension.to_s.downcase
    when "jpg", "jpeg"
      header.start_with?("\xFF\xD8\xFF".b)
    when "png"
      header.start_with?("\x89PNG\r\n\x1A\n".b)
    else
      false
    end

    unless valid
      raise CarrierWave::IntegrityError,
        "File must contain a valid JPEG or PNG signature"
    end
  end

end
