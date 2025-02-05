class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.integer :email_id
      t.integer :parent_document_id
      t.integer :shipment_id
      t.string :filename
      t.string :content
      t.string :category
      t.integer :user_id
      t.integer :client_account_id

      t.timestamps
    end
  end
end
