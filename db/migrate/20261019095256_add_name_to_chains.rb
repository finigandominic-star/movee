class AddNameToChains < ActiveRecord::Migration[8.1]
  def change
    add_column :chains, :name, :string
  end
end
