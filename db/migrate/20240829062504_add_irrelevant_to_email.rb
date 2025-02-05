class AddIrrelevantToEmail < ActiveRecord::Migration[7.1]
  def change
    add_column :emails, :irrelevant, :boolean, default: false
  end
end
