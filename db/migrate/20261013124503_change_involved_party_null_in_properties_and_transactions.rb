class ChangeInvolvedPartyNullInPropertiesAndTransactions < ActiveRecord::Migration[8.1]
  def change
    change_column_null :properties, :involved_party_id, true
    change_column_null :transactions, :involved_party_id, true
  end
end
