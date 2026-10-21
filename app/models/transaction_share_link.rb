class TransactionShareLink < ApplicationRecord
  # Named "deal", not "transaction" - the latter would clash with ActiveRecord's own #transaction method.
  belongs_to :deal, class_name: "Transaction", foreign_key: :transaction_id, inverse_of: :share_links
  belongs_to :user, optional: true

  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create

  # How long the agent can choose the link to stay valid for.
  DURATIONS = {
    "30m" => 30.minutes,
    "1h" => 1.hour,
    "5h" => 5.hours,
    "1d" => 1.day
  }.freeze

  def self.create_for!(transaction, user:, duration:)
    create!(deal: transaction, user: user, expires_at: Time.current + DURATIONS.fetch(duration))
  end

  def expired?
    expires_at <= Time.current
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(24)
  end
end
