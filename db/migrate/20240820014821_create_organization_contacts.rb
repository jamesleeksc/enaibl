class CreateOrganizationContacts < ActiveRecord::Migration[6.1]
  def change
    create_table :organization_contacts do |t|
      t.string :contact_name
      t.string :organization_code, null: false
      t.string :organization_name
      t.string :working_location
      t.string :title
      t.string :email
      t.string :job_category
      t.string :password_instruction_sent_by
      t.datetime :password_instruction_last_sent_time
      t.boolean :active, default: true
      t.boolean :primary_workplace, default: false
      t.boolean :web_access, default: false
      t.boolean :verified, default: false
      t.string :created_by
      t.datetime :created_time_utc
      t.string :last_edit
      t.datetime :last_edited_time_utc
      t.boolean :csv, default: false
      t.string :phone
      t.string :mobile
      t.string :notify_mode
      t.string :attachment_type
      t.string :branch_address
      t.boolean :web_access_superseded, default: false

      t.timestamps
    end

    add_foreign_key :organization_contacts, :organizations, column: :organization_code, primary_key: :organization_code
    add_index :organization_contacts, :organization_code
  end
end
