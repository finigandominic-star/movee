class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.references :user, null: false, foreign_key: true
      t.string :photos
      t.references :involved_party, null: false, foreign_key: true
      t.string :house_number
      t.string :street
      t.string :second_line_of_address
      t.string :city
      t.string :post_code
      t.boolean :sold

      t.timestamps
    end
  end
end
