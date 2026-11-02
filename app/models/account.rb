class Account < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :validatable
  # :trackable, :confirmable

  mount_uploader :image, ProfilePictureUploader
  mount_uploader :cover_image, ProfilePictureUploader

  has_many :properties, dependent: :restrict_with_error
  has_many :agent_messages, dependent: :restrict_with_error

  def full_name
    "#{first_name} #{last_name}"
  end
end
