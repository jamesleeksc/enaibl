class AddClientAccountToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :client_account, null: true, foreign_key: true
  end
end
