class CreateMyRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :my_records do |t|
      t.json :value
      t.text :description

      t.timestamps
    end
  end
end
