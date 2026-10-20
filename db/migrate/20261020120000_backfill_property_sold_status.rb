# A property's sold flag now follows its transactions: sold once a transaction has a buyer
# or has moved past "Offer accepted". Recompute it for existing properties.
class BackfillPropertySoldStatus < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE properties
      SET sold = EXISTS (
        SELECT 1 FROM transactions
        WHERE transactions.property_id = properties.id
          AND (transactions.involved_party_id IS NOT NULL OR transactions.legal_stage <> 'offer_accepted')
      )
    SQL
  end

  def down
    # The old flag was set by hand, so there's nothing to restore
  end
end
