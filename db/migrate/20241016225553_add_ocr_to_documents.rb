class AddOcrToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :ocr, :boolean, default: false
  end
end
