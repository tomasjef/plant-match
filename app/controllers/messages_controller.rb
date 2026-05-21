class MessagesController < ApplicationController
  def create
    @plant = Plant.find(params[:plant_id])
    @chat = current_user.chats.find_or_create_by!(plant: @plant)
    @message = @chat.messages.build(message_params.merge(role: "user"))

    if @message.save
      create_assistant_reply
      redirect_to plant_path(@plant)
    else
      render_invalid_message
    end
  end

  private

  def create_assistant_reply
    ai_reply = PlantAssistant.new(plant: @plant, chat: @chat).call
    @chat.messages.create!(role: "assistant", content: ai_reply)
  end

  def render_invalid_message
    @plant_info = @plant.description.presence || @plant.plant_info.presence
    render "plants/show", status: :unprocessable_entity
  end

  def message_params
    params.require(:message).permit(:content)
  end
end
