class AddLegalStageToTransactions < ActiveRecord::Migration[8.1]
  def up
    add_column :transactions, :legal_stage, :string, default: "offer_accepted", null: false
    add_index :transactions, :legal_stage

    # Backfill any transactions marked completed
    execute <<-SQL.squish
      UPDATE transactions
      SET legal_stage = 'completion'
      WHERE completed = true
    SQL
  end

  def down
    remove_index :transactions, :legal_stage if index_exists?(:transactions, :legal_stage)
    remove_column :transactions, :legal_stage
  end
end
