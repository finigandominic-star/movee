class AddNullifyToTransactionShareLinksUserFk < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :transaction_share_links, :users

    # Defensive: user_id is already optional, so nothing should legitimately point
    # at a user that no longer exists - but belt-and-braces before re-adding the FK.
    execute <<~SQL
      UPDATE transaction_share_links
      SET user_id = NULL
      WHERE user_id IS NOT NULL
        AND user_id NOT IN (SELECT id FROM users)
    SQL

    add_foreign_key :transaction_share_links, :users, on_delete: :nullify
  end

  def down
    remove_foreign_key :transaction_share_links, :users
    add_foreign_key :transaction_share_links, :users
  end
end
