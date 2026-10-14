class Property < ApplicationRecord
  belongs_to :user
  belongs_to :involved_party, optional: true
  belongs_to :chain, optional: true

  has_many :transactions, dependent: :destroy
  has_many :chains, through: :transactions

  validates :post_code, presence: true
  validates :house_number, presence: true
  validates :street, presence: true

  def full_address
    [short_address, second_line_of_address, city, post_code].compact_blank.join(", ")
  end

  def short_address
    [house_number, street].compact_blank.join(" ")
  end
end
