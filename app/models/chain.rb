class Chain < ApplicationRecord
  has_many :transactions, dependent: :destroy
  has_many :properties, through: :transactions
  has_many :involved_parties, through: :transactions
end
