class AddBranchShortcodeToClientAccount < ActiveRecord::Migration[7.1]
  def change
    add_column :client_accounts, :branch_shortcode, :string
  end
end
