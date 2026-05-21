require "test_helper"

class PlantAssistantTest < ActiveSupport::TestCase
  setup do
    @plant = Plant.new(name: "Test Fern")
    @assistant = PlantAssistant.new(plant: @plant, chat: Chat.new)
  end

  test "normalizes valid replies" do
    assert_equal "Keep it in bright indirect light.",
                 @assistant.send(:normalize_reply, " Keep it in bright indirect light. ")
  end

  test "unwraps fenced markdown replies" do
    reply = @assistant.send(:normalize_reply, "```markdown\nWater when the top inch is dry.\n```")

    assert_equal "Water when the top inch is dry.", reply
  end

  test "falls back when reply is only backticks" do
    assert_equal PlantAssistant::FALLBACK_REPLY,
                 @assistant.send(:normalize_reply, "`")
  end
end
