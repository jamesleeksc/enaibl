class AddQaFlagAndQaFlagReasonToDocuments < ActiveRecord::Migration[7.2]
  def change
    add_column :documents, :qa_flag, :boolean, default: false
    add_column :documents, :qa_flag_reason, :string
  end
end
