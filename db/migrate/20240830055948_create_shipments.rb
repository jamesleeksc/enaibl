class CreateShipments < ActiveRecord::Migration[7.1]
  def change
    create_table :shipments do |t|
      t.string :origin_code
      t.string :destination_code
      t.string :transport_type
      t.string :container_type
      t.string :shipment_type
      t.string :shipper_code
      t.string :consignee_code
      t.string :customer_code
      t.integer :origin_location_id
      t.integer :destination_location_id
      t.decimal :weight
      t.string :weight_units
      t.decimal :volume
      t.string :volume_units
      t.decimal :length
      t.decimal :width
      t.decimal :height
      t.string :measurement_units
      t.string :po_number
      t.string :bol_number
      t.date :shipped_date
      t.date :issue_date
      t.datetime :eta
      t.datetime :etd
      t.string :description
      t.string :commodity_code
      t.string :initial_platform
      t.string :destination_platform
      t.string :platform_shipment_id
      t.string :platform_consol_id
      t.boolean :draft, default: false
      t.datetime :uploaded_to_platform_at
      t.integer :eadaptor_data_id
      t.integer :client_account_id

      t.timestamps
    end
  end
end
