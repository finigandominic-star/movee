class InvolvedParty < ApplicationRecord
  has_many :transactions
  has_many :properties
  has_many :chains, through: :transactions
  
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :phone, presence: true, uniqueness: true
end
