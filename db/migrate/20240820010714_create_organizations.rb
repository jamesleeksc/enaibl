class CreateOrganizations < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.references :client_account, null: false, foreign_key: true
      t.string :organization_code, null: false
      t.string :full_name
      t.string :unloco
      t.string :city
      t.string :state
      t.string :branch
      t.string :screening_status
      t.string :achievable_business
      t.string :category
      t.string :country_region
      t.string :employer_identification_number
      t.date :imp_bond_last_queried_date
      t.string :created_by
      t.datetime :created_time_utc
      t.string :last_edit
      t.datetime :last_edited_time_utc
      t.string :address_1
      t.string :address_2
      t.string :email
      t.boolean :competitor_on_customs
      t.boolean :competitor_on_forwarding
      t.boolean :competitor_on_land_transport
      t.boolean :competitor_on_warehouse
      t.string :staff_account_manager
      t.string :staff_cartage_coordinator
      t.string :staff_controller
      t.string :staff_credit_controller
      t.string :staff_customer_service_representative
      t.string :staff_customs_agent
      t.string :staff_project_manager
      t.string :staff_sales_representative
      t.string :fax
      t.boolean :active_client, default: true
      t.string :phone
      t.string :postcode
      t.boolean :national, default: false
      t.string :mobile
      t.string :website_url
      t.string :business_no
      t.string :customs_id
      t.string :lsc_code
      t.datetime :last_actual_communication
      t.datetime :next_scheduled_communication
      t.datetime :last_unactioned_communication
      t.integer :client_relation
      t.string :sales_client_size
      t.string :sales_client_category
      t.string :external_validation_status
      t.string :controlling_agent
      t.string :controlling_customers
      t.text :additional_address_info
      t.string :client_number
      t.string :security_group
      t.string :carrier_category
      t.timestamps
    end
    add_index :organizations, :organization_code, unique: true
  end
end
