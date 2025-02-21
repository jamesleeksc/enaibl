class CreateContainer < ActiveRecord::Migration[7.2]
  def change
    create_table :containers do |t|
      t.string :container_number
      t.timestamps
    end
  end
end
