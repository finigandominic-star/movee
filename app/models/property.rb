class Property < ApplicationRecord
  belongs_to :user
  belongs_to :involved_party, optional: true
  belongs_to :chain, optional: true

  has_many :transactions, dependent: :destroy
  has_many :chains, through: :transactions

  validates :post_code, presence: true
  validates :house_number, presence: true
  validates :street, presence: true

  scope :search, ->(query) {
    return all if query.blank?

    where("house_number ILIKE :q OR street ILIKE :q OR second_line_of_address ILIKE :q OR city ILIKE :q OR post_code ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  has_one_attached :photo

  # Sold (sold subject to contract) once a transaction has a buyer or has moved into conveyancing;
  # for sale while it has no transaction, or only one with no buyer still at "Offer accepted".
  def sale_agreed?
    transactions.reload.any? { |tx| tx.involved_party_id.present? || tx.legal_stage != "offer_accepted" }
  end

  # Keeps the stored `sold` flag (used for filtering) in line with the transactions
  def refresh_sold_status!
    agreed = sale_agreed?
    update_column(:sold, agreed) unless sold == agreed
  end

  def full_address
    [short_address, second_line_of_address, city, post_code].compact_blank.join(", ")
  end

  def short_address
    [house_number, street].compact_blank.join(" ")
  end
end
