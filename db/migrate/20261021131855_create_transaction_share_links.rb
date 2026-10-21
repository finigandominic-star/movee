class CreateTransactionShareLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :transaction_share_links do |t|
      t.string :token, null: false
      t.bigint :transaction_id, null: false
      t.references :user, null: true, foreign_key: true
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :transaction_share_links, :token, unique: true
    add_foreign_key :transaction_share_links, :transactions
    add_index :transaction_share_links, :transaction_id
  end
end
