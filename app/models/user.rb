class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :interview_requests, dependent: :destroy

  normalizes :email, with: ->(e) { e.strip.downcase }

  before_validation :normalize_phone_number

  validates :email, presence: true, uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 7 }, allow_nil: true
  validates :phone_number, phone: { allow_blank: true }

  private

  def normalize_phone_number
    return if phone_number.blank?

    parsed = Phonelib.parse(phone_number)
    self.phone_number = parsed.e164 if parsed.valid?
  end
end
