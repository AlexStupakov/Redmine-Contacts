class CreateContacts < ActiveRecord::Migration[5.2]
  def change
    create_table :contacts do |t|
      t.integer :project_id
      t.string :name
      t.string :country
      t.string :city
      t.string :street
      t.string :house
      t.string :phone
      t.string :zip
      t.string :email

      t.timestamps
    end
  end
end
