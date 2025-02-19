class AddBoxContentToDocument < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :box_content, :jsonb
  end
end
