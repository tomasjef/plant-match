class ChatsController < ApplicationController
  def new
    @chat = Chat.new
  end

  def show
    @plant = Plant.find(params[:plant_id])
    @chat = current_user.chats.find_or_create_by!(plant: @plant)
    @message = Message.new
  end
end
