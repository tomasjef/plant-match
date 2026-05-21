class PlantAssistant
  FALLBACK_REPLY = "Sorry, I couldn't answer that just now. Please try again."

  def initialize(plant:, chat:)
    @plant = plant
    @chat = chat
  end

  def call
    response = RubyLLM.chat(model: assistant_model, provider: :openai, assume_model_exists: true)
                    .with_instructions(system_prompt)
                    .ask(user_prompt)

    normalize_reply(response.content)
  rescue StandardError => e
    Rails.logger.warn("Plant assistant failed: #{e.class} - #{e.message}")
    FALLBACK_REPLY
  end

  private

  attr_reader :plant, :chat

  def assistant_model
    ENV["PLANT_ASSISTANT_MODEL"].presence || RubyLLM.config.default_model
  end

  def normalize_reply(content)
    text = strip_code_fence(content.to_s.strip)
    text = strip_repetitive_opening(text)

    return FALLBACK_REPLY if malformed_reply?(text)

    text
  end

  def strip_code_fence(text)
    text.sub(/\A```[a-zA-Z0-9_-]*\s*/m, "").sub(/\s*```\z/m, "").strip
  end

  def strip_repetitive_opening(text)
    text.sub(/\A(?:according to|based on) the (?:provided )?data,?\s*/i, "")
        .strip
        .sub(/\A[[:lower:]]/) { |char| char.upcase }
  end

  def malformed_reply?(text)
    text.blank? || text !~ /[[:alnum:]]/
  end

  def system_prompt
    <<~PROMPT
      You are a helpful houseplant care assistant.
      Use the plant data provided first.
      If the plant data is incomplete, supplement with general houseplant knowledge that is specific to this plant, its scientific name, or its closest known genus.
      Be practical, concise, and beginner-friendly.
      Start answers directly and naturally.
      Do not begin with phrases like "According to the provided data" or "Based on the data".
      Do not over-explain where the information came from.
      Do not give exact claims for toxicity, mature size, growth speed, or air-purifying ability unless the plant data or well-established plant knowledge supports them.
      If you are unsure, give a cautious plant-specific answer and say what to watch for.
    PROMPT
  end

  def user_prompt
    <<~PROMPT
      Plant:
      Name: #{plant.display_name}
      Scientific name: #{plant.scientific_name}
      Description: #{plant.description}
      Light: #{plant.light_needs}
      Water: #{plant.water_needs}
      Care level: #{plant.care_level}
      Pet safe: #{plant.pet_safe ? 'yes' : 'no'}
      API data: #{plant.api_data}

      Conversation so far:
      #{conversation_history}

      User question:
      #{chat.messages.where(role: 'user').last.content}
    PROMPT
  end

  def conversation_history
    chat.messages.order(:created_at).last(8).map do |message|
      "#{message.role}: #{message.content}"
    end.join("\n")
  end
end
