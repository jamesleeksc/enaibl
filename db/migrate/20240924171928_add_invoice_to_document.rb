class AddInvoiceToDocument < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :invoice, :boolean, default: false
  end
end
