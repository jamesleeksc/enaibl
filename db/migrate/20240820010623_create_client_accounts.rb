class CreateClientAccounts < ActiveRecord::Migration[7.1]
  def change
    create_table :client_accounts do |t|
      t.string :full_name
      t.string :city
      t.string :state
      t.string :country_region
      t.string :address_1
      t.string :address_2
      t.string :email
      t.string :phone
      t.string :postcode
      t.string :mobile
      t.string :website_url
      t.text :additional_address_info
      t.text :notes
      t.string :eadaptor_url
      t.string :eadaptor_username
      t.string :eadaptor_password
      t.string :eadaptor_endpoint
      t.timestamps
    end
  end
end
