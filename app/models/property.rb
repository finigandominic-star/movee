class Property < ApplicationRecord
  belongs_to :user
  belongs_to :involved_party
end
