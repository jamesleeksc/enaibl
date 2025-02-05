# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_08_27_080723) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "client_accounts", force: :cascade do |t|
    t.string "full_name"
    t.string "city"
    t.string "state"
    t.string "country_region"
    t.string "address_1"
    t.string "address_2"
    t.string "email"
    t.string "phone"
    t.string "postcode"
    t.string "mobile"
    t.string "website_url"
    t.text "additional_address_info"
    t.text "notes"
    t.string "eadaptor_url"
    t.string "eadaptor_username"
    t.string "eadaptor_password"
    t.string "eadaptor_endpoint"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "organization_contacts", force: :cascade do |t|
    t.string "contact_name"
    t.string "organization_code", null: false
    t.string "organization_name"
    t.string "working_location"
    t.string "title"
    t.string "email"
    t.string "job_category"
    t.string "password_instruction_sent_by"
    t.datetime "password_instruction_last_sent_time", precision: nil
    t.boolean "active", default: true
    t.boolean "primary_workplace", default: false
    t.boolean "web_access", default: false
    t.boolean "verified", default: false
    t.string "created_by"
    t.datetime "created_time_utc", precision: nil
    t.string "last_edit"
    t.datetime "last_edited_time_utc", precision: nil
    t.boolean "csv", default: false
    t.string "phone"
    t.string "mobile"
    t.string "notify_mode"
    t.string "attachment_type"
    t.string "branch_address"
    t.boolean "web_access_superseded", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_code"], name: "index_organization_contacts_on_organization_code"
  end

  create_table "organizations", force: :cascade do |t|
    t.bigint "client_account_id", null: false
    t.string "organization_code", null: false
    t.string "full_name"
    t.string "unloco"
    t.string "city"
    t.string "state"
    t.string "branch"
    t.string "screening_status"
    t.string "achievable_business"
    t.string "category"
    t.string "country_region"
    t.string "employer_identification_number"
    t.date "imp_bond_last_queried_date"
    t.string "created_by"
    t.datetime "created_time_utc"
    t.string "last_edit"
    t.datetime "last_edited_time_utc"
    t.string "address_1"
    t.string "address_2"
    t.string "email"
    t.boolean "competitor_on_customs"
    t.boolean "competitor_on_forwarding"
    t.boolean "competitor_on_land_transport"
    t.boolean "competitor_on_warehouse"
    t.string "staff_account_manager"
    t.string "staff_cartage_coordinator"
    t.string "staff_controller"
    t.string "staff_credit_controller"
    t.string "staff_customer_service_representative"
    t.string "staff_customs_agent"
    t.string "staff_project_manager"
    t.string "staff_sales_representative"
    t.string "fax"
    t.boolean "active_client", default: true
    t.string "phone"
    t.string "postcode"
    t.boolean "national", default: false
    t.string "mobile"
    t.string "website_url"
    t.string "business_no"
    t.string "customs_id"
    t.string "lsc_code"
    t.datetime "last_actual_communication"
    t.datetime "next_scheduled_communication"
    t.datetime "last_unactioned_communication"
    t.integer "client_relation"
    t.string "sales_client_size"
    t.string "sales_client_category"
    t.string "external_validation_status"
    t.string "controlling_agent"
    t.string "controlling_customers"
    t.text "additional_address_info"
    t.string "client_number"
    t.string "security_group"
    t.string "carrier_category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_account_id"], name: "index_organizations_on_client_account_id"
    t.index ["organization_code"], name: "index_organizations_on_organization_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.bigint "client_account_id"
    t.index ["client_account_id"], name: "index_users_on_client_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "organization_contacts", "organizations", column: "organization_code", primary_key: "organization_code"
  add_foreign_key "organizations", "client_accounts"
  add_foreign_key "users", "client_accounts"
end
