class ChatsController < ApplicationController
  def new
    @chat = Chat.new
  end

  def create
    @chat = current_user.chats.build

    if @chat.save
      redirect_to plant_chat_path(@chat)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @chat = current_user.chats.find(params[:id])
    @message = Message.new
  end
end

# class ChatsController < ApplicationController
#   def create
#     @plant = plant.find(params[:plant_id])

#     @chat = Chat.new(title: Chat::DEFAULT_TITLE)
#     @chat.plant = @plant
#     @chat.user = current_user

#     if @chat.save
#       redirect_to plant_chat_path(@chat)
#     else
#       @chats = @plant.chats.where(user: current_user)
#       render "plants/show"
#     end
#   end

#   def show
#     @chat    = current_user.chats.find(params[:id])
#     @message = Message.new
#   end
# end
