class AddAliasOrganizationsToClientAccounts < ActiveRecord::Migration[7.1]
  def change
    add_column :client_accounts, :alias_organizations, :text
  end
end
