class LocationImportService
  def self.import(file_path, account_id = nil)
    # spreasheet headers Code	Port Name	IATA	IATA Region Code	Coordinates	GMT Offset	Daylight Savings	Is In Current Country/Region	Is In EU	Economic Group	Created By	Created Time (UTC)	Last Edit	Last Edited Time (UTC)	Country/Region States Code	Has Airport	Has Border Crossing	Has Customs Lodge	Discharge	Has Outport	Has Post	Has Rail	Has Road	Has Seaport	Has Store	Has Terminal	Has Unload	Proper Name	Is Active	Is System Updatable	Is System

    # db columns:
    # t.string "proper_name"
    # t.string "code"
    # t.string "port_name"
    # t.string "iata"
    # t.string "iata_region_code"
    # t.string "coordinates"
    # t.decimal "gmt_offset"
    # t.boolean "daylight_savings", default: false
    # t.boolean "in_eu", default: false
    # t.string "economic_group"
    # t.string "country_region_states_code"
    # t.boolean "airport", default: false
    # t.boolean "border_crossing", default: false
    # t.boolean "customs_lodge", default: false
    # t.boolean "discharge", default: false
    # t.boolean "outport", default: false
    # t.boolean "post", default: false
    # t.boolean "rail", default: false
    # t.boolean "road", default: false
    # t.boolean "seaport", default: false
    # t.boolean "store", default: false
    # t.boolean "terminal", default: false
    # t.boolean "unload", default: false
    # t.boolean "active", default: false
    # t.string "source"
    # t.integer "client_account_id"
    # t.datetime "created_at", null: false
    # t.datetime "updated_at", null: false

    xlsx = Roo::Spreadsheet.open(file_path)
    sheet_h = xlsx.parse(headers: true)
    sheet_h[1..-1].each do |row|
      location = Location.find_or_create_by(
        code: row["Code"],
        iata: row["IATA"],
        client_account_id: account_id
      )

      location.assign_attributes(
        code: row["Code"],
        port_name: row["Port Name"],
        iata: row["IATA"],
        iata_region_code: row["IATA Region Code"],
        coordinates: row["Coordinates"],
        gmt_offset: row["GMT Offset"],
        daylight_savings: Utils.to_boolean(row["Daylight Savings"]),
        in_eu: Utils.to_boolean(row["Is In EU"]),
        economic_group: row["Economic Group"],
        country_region_states_code: row["Country/Region States Code"],
        airport: Utils.to_boolean(row["Has Airport"]),
        border_crossing: Utils.to_boolean(row["Has Border Crossing"]),
        customs_lodge: Utils.to_boolean(row["Has Customs Lodge"]),
        discharge: Utils.to_boolean(row["Discharge"]),
        outport: Utils.to_boolean(row["Has Outport"]),
        post: Utils.to_boolean(row["Has Post"]),
        rail: Utils.to_boolean(row["Has Rail"]),
        road: Utils.to_boolean(row["Has Road"]),
        seaport: Utils.to_boolean(row["Has Seaport"]),
        store: Utils.to_boolean(row["Has Store"]),
        terminal: Utils.to_boolean(row["Has Terminal"]),
        unload: Utils.to_boolean(row["Has Unload"]),
        proper_name: row["Proper Name"],
        active: Utils.to_boolean(row["Is Active"]),
        source: "CW1"
      )

      location.save if location.valid? && location.changed
    end
  end
end
