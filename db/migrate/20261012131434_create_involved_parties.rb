class CreateInvolvedParties < ActiveRecord::Migration[8.1]
  def change
    create_table :involved_parties do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :contact_info
      t.string :phone
      t.boolean :seller
      t.boolean :buyer

      t.timestamps
    end
  end
end
