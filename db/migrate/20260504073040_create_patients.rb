class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients do |t|
      t.integer :health_id
      t.integer :health_id_provincial
      t.string :name
      t.text :address
      t.string :email
      t.string :phone
      t.string :sex

      t.timestamps
    end
  end
end
