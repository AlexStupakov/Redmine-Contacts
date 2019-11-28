class AddAuthorIdToContact < ActiveRecord::Migration[5.2]
  def change
    add_column :contacts, :author_id, :integer
  end
end
