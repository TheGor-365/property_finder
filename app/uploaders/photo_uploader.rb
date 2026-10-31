class PhotoUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  version :thumb do
    process resize_to_fill: [300,200]
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process resize_to_fit: [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  MAX_UPLOAD_BYTES = 5 * 1024 * 1024

  before :cache, :validate_image_upload!

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

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
