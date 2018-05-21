class CreateChanges < ActiveRecord::Migration[4.2]
  def change
    create_table :changes do |t|
      t.references :calendar, index: true, foreign_key: true
      t.string :uri
      t.boolean :is_delete

      t.timestamps null: false
    end
  end
end
