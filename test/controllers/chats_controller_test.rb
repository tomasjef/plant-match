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
end
