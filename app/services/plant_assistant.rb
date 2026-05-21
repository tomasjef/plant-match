class PlantAssistant
  def initialize(plant:, chat:)
    @plant = plant
    @chat = chat
  end

  def call
    RubyLLM.chat(model: assistant_model, provider: :openai, assume_model_exists: true)
           .with_instructions(system_prompt)
           .ask(user_prompt)
           .content
  rescue StandardError => e
    Rails.logger.warn("Plant assistant failed: #{e.class} - #{e.message}")
    "Sorry, I couldn't answer that just now. Please try again."
  end

  private

  attr_reader :plant, :chat

  def assistant_model
    ENV["PLANT_ASSISTANT_MODEL"].presence || RubyLLM.config.default_model
  end

  def system_prompt
    <<~PROMPT
      You are a helpful houseplant care assistant.
      Answer using the plant data provided.
      Be practical, concise, and beginner-friendly.
      If the API data does not contain the answer, say so clearly.
      Do not invent exact facts such as toxicity, watering needs, or light needs.
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
