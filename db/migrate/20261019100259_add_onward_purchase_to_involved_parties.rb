class AddOnwardPurchaseToInvolvedParties < ActiveRecord::Migration[8.1]
  def up
    add_column :involved_parties, :onward_purchase, :string, null: false, default: "undecided"

    # Keep existing chains' status unchanged: the old rule read "seller but not buyer" as leaving the market.
    execute "UPDATE involved_parties SET onward_purchase = 'buying' WHERE seller = TRUE AND buyer = TRUE"
    execute "UPDATE involved_parties SET onward_purchase = 'leaving_market' WHERE seller = TRUE AND (buyer = FALSE OR buyer IS NULL)"
  end

  def down
    remove_column :involved_parties, :onward_purchase
  end
end
