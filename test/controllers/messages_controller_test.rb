require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "message-user@example.com", password: "password")
    @plant = Plant.create!(
      name: "Message Test Plant",
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      pet_safe: true,
      image_url: "https://example.com/message-test-plant.jpg",
      description: "A plant used for message tests."
    )
    @chat = @user.chats.create!(plant: @plant)
    sign_in @user
  end

  test "should create message" do
    assistant = Struct.new(:reply) do
      def call
        reply
      end
    end.new("AI reply")

    with_assistant_stub(assistant) do
      assert_difference("@chat.messages.count", 2) do
        post plant_assistant_messages_url(@plant), params: { message: { content: "Low light, please" } }
      end
    end

    assert_redirected_to plant_url(@plant)
  end

  test "should create message from quick question" do
    assistant = Struct.new(:reply) do
      def call
        reply
      end
    end.new("Quick reply")

    with_assistant_stub(assistant) do
      assert_difference("@chat.messages.count", 2) do
        post plant_assistant_messages_url(@plant), params: { message: { content: "Growth style?" } }
      end
    end

    assert_equal "Growth style?", @chat.messages.where(role: "user").last.content
    assert_equal "Quick reply", @chat.messages.where(role: "assistant").last.content
    assert_redirected_to plant_url(@plant)
  end

  private

  def with_assistant_stub(assistant)
    original_new = PlantAssistant.method(:new)
    PlantAssistant.define_singleton_method(:new) { |**| assistant }

    yield
  ensure
    PlantAssistant.define_singleton_method(:new) do |*args, **kwargs, &block|
      original_new.call(*args, **kwargs, &block)
    end
  end
end
