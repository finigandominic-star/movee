class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.references :involved_party, null: false, foreign_key: true
      t.references :chain, null: false, foreign_key: true
      t.references :property, null: false, foreign_key: true
      t.boolean :completed

      t.timestamps
    end
  end
end
