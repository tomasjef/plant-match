class AddPerenualFieldsToPlants < ActiveRecord::Migration[8.1]
  def change
    add_column :plants, :perenual_id, :integer
    add_column :plants, :scientific_name, :string
    add_column :plants, :description, :text
    add_column :plants, :api_image_url, :string
    add_column :plants, :api_data, :jsonb, default: {}, null: false
    add_column :plants, :synced_at, :datetime

    add_index :plants, :perenual_id, unique: true
  end
end
