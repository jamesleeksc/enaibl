class CreateEadaptorData < ActiveRecord::Migration[7.1]
  def change
    create_table :eadaptor_data do |t|
      t.string :record_type
      t.jsonb :raw

      t.timestamps
    end
  end
end
