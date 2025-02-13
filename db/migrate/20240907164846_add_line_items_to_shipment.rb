class AddLineItemsToShipment < ActiveRecord::Migration[7.1]
  def change
    add_column :shipments, :line_items, :text
  end
end
