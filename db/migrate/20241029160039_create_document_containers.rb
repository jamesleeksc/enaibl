class CreateDocumentContainers < ActiveRecord::Migration[7.2]
  def change
    create_table :document_containers do |t|
      t.belongs_to :document
      t.belongs_to :container
      t.timestamps
    end

    add_index :document_containers, [:document_id, :container_id], unique: true
  end
end
