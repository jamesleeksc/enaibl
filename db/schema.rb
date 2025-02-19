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

ActiveRecord::Schema[7.2].define(version: 2024_10_17_223351) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.text "alias_organizations"
    t.string "branch_shortcode"
  end

  create_table "documents", force: :cascade do |t|
    t.integer "email_id"
    t.integer "parent_document_id"
    t.integer "shipment_id"
    t.string "filename"
    t.string "content"
    t.string "category"
    t.integer "user_id"
    t.integer "client_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "irrelevant", default: false
    t.boolean "pod"
    t.jsonb "invoice_content"
    t.boolean "invoice", default: false
    t.string "ap_or_ar"
    t.boolean "shipping_invoice"
    t.boolean "confirmed_invoice", default: false
    t.boolean "ocr", default: false
    t.string "file_hash"
    t.integer "duplicate_of_id"
    t.boolean "qa_flag", default: false
    t.string "qa_flag_reason"
    t.jsonb "box_content"
    t.index ["client_account_id"], name: "index_documents_on_client_account_id"
    t.index ["filename"], name: "index_documents_on_filename"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "eadaptor_data", force: :cascade do |t|
    t.string "record_type"
    t.jsonb "raw"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "emails", force: :cascade do |t|
    t.string "to"
    t.string "ccs"
    t.string "from"
    t.string "subject"
    t.text "body"
    t.string "category"
    t.datetime "date"
    t.string "platform"
    t.string "platform_id"
    t.bigint "user_id"
    t.bigint "client_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "irrelevant", default: false
    t.boolean "pod"
    t.index ["client_account_id"], name: "index_emails_on_client_account_id"
    t.index ["user_id"], name: "index_emails_on_user_id"
  end

  create_table "emails_shipments", id: false, force: :cascade do |t|
    t.bigint "shipment_id", null: false
    t.bigint "email_id", null: false
  end

  create_table "locations", force: :cascade do |t|
    t.string "proper_name"
    t.string "code"
    t.string "port_name"
    t.string "iata"
    t.string "iata_region_code"
    t.string "coordinates"
    t.decimal "gmt_offset"
    t.boolean "daylight_savings", default: false
    t.boolean "in_eu", default: false
    t.string "economic_group"
    t.string "country_region_states_code"
    t.boolean "airport", default: false
    t.boolean "border_crossing", default: false
    t.boolean "customs_lodge", default: false
    t.boolean "discharge", default: false
    t.boolean "outport", default: false
    t.boolean "post", default: false
    t.boolean "rail", default: false
    t.boolean "road", default: false
    t.boolean "seaport", default: false
    t.boolean "store", default: false
    t.boolean "terminal", default: false
    t.boolean "unload", default: false
    t.boolean "active", default: false
    t.string "source"
    t.integer "client_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_account_id"], name: "index_locations_on_client_account_id"
    t.index ["code"], name: "index_locations_on_code"
    t.index ["iata"], name: "index_locations_on_iata"
    t.index ["port_name"], name: "index_locations_on_port_name"
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
    t.integer "organization_id"
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
    t.bigint "user_id"
    t.index ["client_account_id"], name: "index_organizations_on_client_account_id"
    t.index ["organization_code"], name: "index_organizations_on_organization_code", unique: true
    t.index ["user_id"], name: "index_organizations_on_user_id"
  end

  create_table "prompts", force: :cascade do |t|
    t.string "model"
    t.text "input"
    t.string "output"
    t.string "task_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shipments", force: :cascade do |t|
    t.string "origin_code"
    t.string "destination_code"
    t.string "transport_type"
    t.string "container_type"
    t.string "shipment_type"
    t.string "shipper_code"
    t.string "consignee_code"
    t.string "customer_code"
    t.integer "origin_location_id"
    t.integer "destination_location_id"
    t.decimal "weight"
    t.string "weight_units"
    t.decimal "volume"
    t.string "volume_units"
    t.decimal "length"
    t.decimal "width"
    t.decimal "height"
    t.string "measurement_units"
    t.string "po_number"
    t.string "bol_number"
    t.date "shipped_date"
    t.date "issue_date"
    t.datetime "eta"
    t.datetime "etd"
    t.string "description"
    t.string "commodity_code"
    t.string "initial_platform"
    t.string "destination_platform"
    t.string "platform_shipment_id"
    t.string "platform_consol_id"
    t.boolean "draft", default: false
    t.datetime "uploaded_to_platform_at"
    t.integer "eadaptor_data_id"
    t.integer "client_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "line_items"
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
    t.string "google_access_token"
    t.string "google_refresh_token"
    t.datetime "google_expires_at"
    t.index ["client_account_id"], name: "index_users_on_client_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "emails", "client_accounts"
  add_foreign_key "emails", "users"
  add_foreign_key "organization_contacts", "organizations", column: "organization_code", primary_key: "organization_code"
  add_foreign_key "organizations", "client_accounts"
  add_foreign_key "organizations", "users"
  add_foreign_key "users", "client_accounts"
end
