module PropertiesHelper
  def property_thumbnail property
    img = property.photo.present? ? property.photo.thumb.url : "unnamed.jpg"
    image_tag img, class: 'property-thumb'
  end

  def property_photo_url property
    property.photo.present? ? property.photo.url : asset_url("unnamed.jpg")
  end
end