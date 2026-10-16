class AddCompletionDatesAndStageDatesToTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :transactions, :estimated_completion_date, :date
    add_column :transactions, :actual_completion_date, :date
    add_column :transactions, :stage_dates, :jsonb, default: {}, null: false
  end
end
