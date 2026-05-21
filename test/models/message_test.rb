require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "recent_first orders newest messages first" do
    user = User.create!(email: "message-order@example.com", password: "password")
    plant = Plant.create!(
      name: "Message Order Plant",
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      pet_safe: true,
      image_url: "https://example.com/message-order-plant.jpg",
      description: "A plant used for message order tests."
    )
    chat = user.chats.create!(plant: plant)
    oldest = chat.messages.create!(role: "user", content: "Oldest")
    newest = chat.messages.create!(role: "assistant", content: "Newest")

    assert_equal [newest, oldest], chat.messages.recent_first.to_a
  end
end
