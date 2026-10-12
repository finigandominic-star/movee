class Property < ApplicationRecord
  belongs_to :user
  belongs_to :involved_party
  belongs_to :chain, through: :transactions

  validates :post_code, presence: true
  validates :house_number, presence: true
  validate :street, presence: true
end
