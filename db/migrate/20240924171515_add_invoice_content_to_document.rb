class AddInvoiceContentToDocument < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :invoice_content, :jsonb
  end
end
