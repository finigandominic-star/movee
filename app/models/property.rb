class Property < ApplicationRecord
  belongs_to :user
  belongs_to :involved_party
  belongs_to :chain

  validates :post_code, presence: true
  validates :house_number, presence: true
  validates :street, presence: true
end
