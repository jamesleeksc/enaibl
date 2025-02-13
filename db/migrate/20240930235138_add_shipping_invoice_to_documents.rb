class AddShippingInvoiceToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :shipping_invoice, :boolean
  end
end
