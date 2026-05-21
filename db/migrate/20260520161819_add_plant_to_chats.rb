class AddPlantToChats < ActiveRecord::Migration[8.1]
  def change
    add_reference :chats, :plant, null: true, foreign_key: true
  end
end
