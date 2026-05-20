require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "message-user@example.com", password: "password")
    @chat = @user.chats.create!
    sign_in @user
  end

  test "should create message" do
    assert_difference("@chat.messages.count", 1) do
      post plant_chat_messages_url(@chat), params: { message: { content: "Low light, please" } }
    end

    assert_redirected_to plant_chat_url(@chat)
  end
end
