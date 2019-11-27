class RenameAtToOn < ActiveRecord::Migration[5.2]
  def change
    rename_column :contacts, :created_at, :created_on
    rename_column :contacts, :updated_at, :updated_on
  end
end
