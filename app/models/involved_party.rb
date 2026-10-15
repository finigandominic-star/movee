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

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :phone, presence: true, uniqueness: true

  def full_name
    "#{first_name} #{last_name}".strip
  end

  def roles_label
    roles = []
    roles << "Seller" if seller?
    roles << "Buyer" if buyer?
    roles.empty? ? "Contact" : roles.join(" / ")
  end
end
