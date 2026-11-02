class Enquiry < ApplicationRecord
  STATUSES = %w[new contacted closed].freeze

  belongs_to :property

  before_validation :normalize_fields
  validates :name, presence: true, length: { maximum: 120 }
  validates :email, presence: true, length: { maximum: 254 },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :status, inclusion: { in: STATUSES }
  validate :property_must_be_available, on: :create

  private

  def normalize_fields
    self.name = name.to_s.strip
    self.email = email.to_s.strip.downcase
    self.message = message.to_s.strip
  end

  def property_must_be_available
    errors.add(:property, "is not accepting enquiries") if property && property.status != "available"
  end
end
