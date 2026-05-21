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

  test "removes repetitive provided data opener" do
    reply = @assistant.send(:normalize_reply, "According to the provided data, it grows slowly.")

    assert_equal "It grows slowly.", reply
  end

  test "removes based on the data opener" do
    reply = @assistant.send(:normalize_reply, "Based on the data, Monstera grows quickly.")

    assert_equal "Monstera grows quickly.", reply
  end

  test "prompt allows general plant knowledge when data is incomplete" do
    prompt = @assistant.send(:system_prompt)

    assert_includes prompt, "supplement with general houseplant knowledge"
    assert_includes prompt, "specific to this plant"
    assert_includes prompt, "Do not over-explain where the information came from."
  end
end
