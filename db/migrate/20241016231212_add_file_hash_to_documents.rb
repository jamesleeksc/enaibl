class AddFileHashToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :file_hash, :string
    add_column :documents, :duplicate_of_id, :integer
  end
end
