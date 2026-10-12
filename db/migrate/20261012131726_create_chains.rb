class CreateChains < ActiveRecord::Migration[8.1]
  def change
    create_table :chains do |t|
      t.boolean :active

      t.timestamps
    end
  end
end
