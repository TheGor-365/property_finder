class Post < ApplicationRecord
  mount_uploader :image, PhotoUploader
  validates :title, presence: true, length: { maximum: 160 }
  validates :body, presence: true
  validates :summary, length: { maximum: 500 }, allow_blank: true
  scope :active, -> { where(active: true) }
  scope :latest, -> { order(created_at: :desc, id: :desc) }
end
