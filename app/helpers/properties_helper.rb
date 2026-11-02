module PropertiesHelper
  DEMO_ILLUSTRATIONS = %w[
    editorial/architecture.svg
    editorial/terrace.svg
    editorial/living-room.svg
    editorial/courtyard.svg
    editorial/apartment.svg
    editorial/townhouse.svg
    editorial/lakehouse.svg
    editorial/studio.svg
    editorial/garden.svg
    editorial/penthouse.svg
    editorial/brickhome.svg
    editorial/modernhouse.svg
  ].freeze

  def property_thumbnail(property)
    image_tag property_thumbnail_url(property), class: 'property-thumb'
  end

  def property_thumbnail_url(property)
    property.photo.present? ? property.photo.thumb.url : illustrative_property_asset(property)
  end

  def property_photo_url(property)
    property.photo.present? ? property.photo.url : illustrative_property_asset(property)
  end

  def illustrative_property_asset(property)
    asset_path(DEMO_ILLUSTRATIONS[property.id.to_i % DEMO_ILLUSTRATIONS.size])
  end
end
