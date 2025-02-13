class AddGoogleTokensToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :google_access_token, :string
    add_column :users, :google_refresh_token, :string
    add_column :users, :google_expires_at, :datetime
  end
end
