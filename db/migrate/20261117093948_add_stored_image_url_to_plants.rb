class AddStoredImageUrlToPlants < ActiveRecord::Migration[8.1]
  def change
    add_column :plants, :stored_image_url, :string
  end
end
