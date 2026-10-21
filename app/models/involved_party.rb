class InvolvedParty < ApplicationRecord
  belongs_to :user, optional: true
  has_many :transactions, dependent: :nullify
  has_many :properties, dependent: :nullify
  has_many :chains, through: :transactions

  def user_associated?(target_user)
    return false if target_user.nil?
    return true if target_user.admin?
    return true if user_id == target_user.id
    return true if properties.where(user_id: target_user.id).exists?
    return true if transactions.where(user_id: target_user.id).exists?
    return true if transactions.joins(:property).where(properties: { user_id: target_user.id }).exists?

    false
  end

  # A vendor's plans after selling decide whether they close the top of a chain.
  ONWARD_PURCHASE_OPTIONS = {
    "undecided" => "Not decided yet",
    "buying" => "Buying onward",
    "leaving_market" => "Not buying (leaving the market)"
  }.freeze

  validates :onward_purchase, inclusion: { in: ONWARD_PURCHASE_OPTIONS.keys }
  before_validation { self.buyer = true if onward_purchase == "buying" }

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :phone, presence: true, uniqueness: true

  scope :search, ->(query) {
    return all if query.blank?

    where("first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q OR phone ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def leaving_market?
    seller? && onward_purchase == "leaving_market"
  end

  def onward_purchase_label
    ONWARD_PURCHASE_OPTIONS[onward_purchase]
  end

  def roles_label
    roles = []
    roles << "Seller" if seller?
    roles << "Buyer" if buyer?
    roles.empty? ? "Contact" : roles.join(" / ")
  end
end
