class AddIndexToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_index :documents, :filename
    add_index :documents, :user_id
    add_index :documents, :client_account_id
  end
end
