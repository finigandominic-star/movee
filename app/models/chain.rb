class Chain < ApplicationRecord
  belongs_to :user, optional: true
  has_many :transactions, dependent: :destroy
  has_many :properties, through: :transactions
  has_many :involved_parties, through: :transactions

  has_many :buyers, through: :transactions, source: :involved_party
  has_many :sellers, through: :properties, source: :involved_party

  def all_parties
    InvolvedParty.where(id: (buyer_ids + seller_ids).uniq)
  end
end
