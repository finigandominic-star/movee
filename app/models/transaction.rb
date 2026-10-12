class Transaction < ApplicationRecord
  belongs_to :involved_party
  belongs_to :chain
  belongs_to :property
end
