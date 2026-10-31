class Property < ApplicationRecord
  mount_uploader :photo, PhotoUploader
  belongs_to :account

  validates :name, presence: true, length: { maximum: 150 }
  validates :address, presence: true, length: { maximum: 255 }

  validates :price,
    numericality: { greater_than_or_equal_to: 0 }

  validates :rooms, :bathrooms, :parking_spaces,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
    },
    allow_nil: true

  scope :latest, -> { order created_at: :desc }

  scope :sold,      -> { where(for_sale: true ,status: "sold")       }
  scope :for_sale,  -> { where(for_sale: true ,status: "available")  }
  scope :leased,    -> { where(for_sale: false ,status: "leased")     }
  scope :for_rent,  -> { where(for_sale: false ,status: "available")  }
end
