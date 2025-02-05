class CreateJoinTableShipmentsEmails < ActiveRecord::Migration[7.1]
  def change
    create_join_table :shipments, :emails do |t|
      # t.index [:shipment_id, :email_id]
      # t.index [:email_id, :shipment_id]
    end
  end
end
