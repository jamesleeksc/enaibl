class CreateLocation < ActiveRecord::Migration[7.1]
  def up
    create_table :locations do |t|
      t.string :proper_name
      t.string :code
      t.string :port_name
      t.string :iata
      t.string :iata_region_code
      t.string :coordinates
      t.decimal :gmt_offset
      t.boolean :daylight_savings, default: false
      t.boolean :in_eu, default: false
      t.string :economic_group
      t.string :country_region_states_code
      t.boolean :airport, default: false
      t.boolean :border_crossing, default: false
      t.boolean :customs_lodge, default: false
      t.boolean :discharge, default: false
      t.boolean :outport, default: false
      t.boolean :post, default: false
      t.boolean :rail, default: false
      t.boolean :road, default: false
      t.boolean :seaport, default: false
      t.boolean :store, default: false
      t.boolean :terminal, default: false
      t.boolean :unload, default: false
      t.boolean :active, default: false
      t.string :source
      t.integer :client_account_id

      t.timestamps
    end

    add_index :locations, :client_account_id
    add_index :locations, :code
    add_index :locations, :iata
    add_index :locations, :port_name
  end

  def down
    drop_table :locations
  end
end
