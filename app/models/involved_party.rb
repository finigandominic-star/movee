class InvolvedParty < ApplicationRecord
  has_many :transactions, dependent: :nullify
  has_many :properties, dependent: :nullify
  has_many :chains, through: :transactions

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
