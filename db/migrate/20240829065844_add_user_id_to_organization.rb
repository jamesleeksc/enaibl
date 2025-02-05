class AddUserIdToOrganization < ActiveRecord::Migration[7.1]
  def change
    add_reference :organizations, :user, null: true, foreign_key: true
  end
end
