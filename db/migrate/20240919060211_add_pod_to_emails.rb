class AddPodToEmails < ActiveRecord::Migration[7.1]
  def change
    add_column :emails, :pod, :boolean
  end
end
