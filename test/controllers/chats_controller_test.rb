require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "chat-user@example.com", password: "password")
    sign_in @user
  end

  test "should get new" do
    get find_plant_url
    assert_response :success
  end

  test "should create chat" do
    assert_difference("Chat.count", 1) do
      post plant_chats_url
    end

    assert_redirected_to plant_chat_url(Chat.last)
  end

  test "should show own chat" do
    chat = @user.chats.create!

    get plant_chat_url(chat)
    assert_response :success
  end
end
