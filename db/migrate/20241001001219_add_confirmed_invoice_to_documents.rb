class AddConfirmedInvoiceToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :confirmed_invoice, :boolean, default: false
  end
end
