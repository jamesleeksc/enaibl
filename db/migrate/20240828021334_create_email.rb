class CreateEmail < ActiveRecord::Migration[7.1]
  def change
    create_table :emails do |t|
      t.string :to
      t.string :ccs
      t.string :from
      t.string :subject
      t.text :body
      t.string :category
      t.datetime :date
      t.string :platform
      t.string :platform_id
      t.references :user, null: true, foreign_key: true
      t.references :client_account, null: true, foreign_key: true
      t.timestamps
    end
  end
end
