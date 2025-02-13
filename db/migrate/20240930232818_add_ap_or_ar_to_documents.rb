class AddApOrArToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :ap_or_ar, :string
  end
end
