RubyLLM.configure do |config|
  openai_api_key = ENV["OPENAI_API_KEY"].presence
  github_models_token = ENV["GITHUB_TOKEN"].presence
  api_base = ENV["OPENAI_API_BASE"].presence

  if openai_api_key.present?
    config.openai_api_key = openai_api_key
    config.openai_api_base = api_base if api_base.present?
    default_model = config.default_model
  elsif github_models_token.present?
    config.openai_api_key = github_models_token
    config.openai_api_base = api_base || "https://models.github.ai/inference"
    default_model = "openai/gpt-4.1"
  end

  config.default_model = ENV.fetch("PLANT_ASSISTANT_MODEL", default_model || config.default_model)
  config.request_timeout = ENV.fetch("RUBYLLM_REQUEST_TIMEOUT", 15).to_i
end
