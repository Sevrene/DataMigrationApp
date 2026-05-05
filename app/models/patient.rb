class Patient < ApplicationRecord
  validates :health_id, presence: true
  validates :health_id_provincial, presence: true
  validates :name, presence: true
  # Assumption: Contact details (email, phone) are optional, but must be valid formats if provided
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, format: { with: /\A(?:\+?\d{1,3}\s*-?)?\(?(?:\d{3})?\)?[- ]?\d{3}[- ]?\d{4}\z/ }, allow_blank: true
  # Assumption: Sex may be very system dependant. Certain implementations may want to restrict this to specific inclusive values
  # Presumably healthcare systems would have a defined set of values for this field, but for this implementation any string value is allowed
end
