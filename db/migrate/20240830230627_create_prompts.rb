class CreatePrompts < ActiveRecord::Migration[7.1]
  def change
    create_table :prompts do |t|
      t.string :model
      t.text :input
      t.string :output
      t.string :task_type

      t.timestamps
    end
  end
end
