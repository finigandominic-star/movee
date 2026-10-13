class AddUserToTransactionsChainsAndInvolvedParties < ActiveRecord::Migration[8.1]
  def change
    add_reference :transactions, :user, foreign_key: true
    add_reference :chains, :user, foreign_key: true
    add_reference :involved_parties, :user, foreign_key: true
  end
end
