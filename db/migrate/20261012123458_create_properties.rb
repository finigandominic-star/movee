class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.references :user, null: false, foreign_key: true
      t.string :photos
      t.references :seller, null: false, foreign_key: true
      t.string :house_number
      t.string :street
      t.string :second_line_of_address
      t.string :city
      t.string :post_code
      t.string :sold
      t.string :boolean

      t.timestamps
    end
  end
end
