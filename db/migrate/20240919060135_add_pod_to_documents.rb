class AddPodToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_column :documents, :pod, :boolean
  end
end
