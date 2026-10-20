class CreateClientDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :client_documents do |t|
      t.references :user, null: false, foreign_key: true
      t.string :step
      t.string :filename
      t.integer :byte_size
      t.text :content
      t.string :status, null: false, default: "processing"
      t.jsonb :extracted_data, null: false, default: {}
      t.string :error_message

      t.timestamps
    end
  end
end
