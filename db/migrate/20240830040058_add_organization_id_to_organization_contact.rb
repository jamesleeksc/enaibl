class AddOrganizationIdToOrganizationContact < ActiveRecord::Migration[7.1]
  def change
    add_column :organization_contacts, :organization_id, :integer
  end
end
