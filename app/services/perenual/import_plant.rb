module Perenual
  class ImportPlant
    def initialize(data, answers: {})
      @data = data
      @answers = answers
    end

    def call
      find_plant.tap do |plant|
        assign_api_fields(plant)
        assign_matching_fields(plant)
        plant.save!
        StorePlantImageJob.perform_later(plant.id) if ImageStore.configured? && plant.stored_image_url.blank?
      end
    end

    private

    attr_reader :data, :answers

    def find_plant
      Plant.find_by(perenual_id: perenual_id) ||
        Plant.find_or_initialize_by(name: plant_name)
    end

    def assign_api_fields(plant)
      plant.perenual_id = perenual_id if perenual_id.present?
      plant.name = plant_name
      plant.scientific_name = scientific_name if scientific_name.present?
      plant.description = description if description.present?
      plant.image_url = display_image_url if display_image_url.present?
      plant.api_image_url = original_image_url if original_image_url.present?
      plant.api_data = plant.api_data.merge(data)
      plant.synced_at = Time.current
    end

    def assign_matching_fields(plant)
      unconfirmed = plant.description.blank?

      plant.light_needs = need(plant, :light_needs, data["sunlight"], unconfirmed) { |value| map_sunlight(value) }
      plant.water_needs = need(plant, :water_needs, data["watering"], unconfirmed) { |value| map_watering(value) }
      plant.care_level = map_care_level(care_level_data) if care_level_data.present? || plant.care_level.blank?
      plant.indoor_outdoor = "indoor"
      plant.pet_safe = pet_safe(plant, unconfirmed)
    end

    # Search results leave out most care fields. Until a plant's details arrive,
    # use the answers the search matched it on.
    def need(plant, attribute, api_value, unconfirmed)
      return yield(api_value) if api_value.present?
      return answers[attribute] if unconfirmed && answers[attribute].present?

      plant.public_send(attribute).presence || yield(nil)
    end

    # nil means not known yet, so the page makes no claim either way
    def pet_safe(plant, unconfirmed)
      return !truthy?(data["poisonous_to_pets"]) if data.key?("poisonous_to_pets")
      return answers[:pet_safe] if unconfirmed

      plant.pet_safe
    end

    def perenual_id
      data["id"]
    end

    def plant_name
      (data["common_name"].presence || scientific_name || "Unknown plant").titleize
    end

    def scientific_name
      Array(data["scientific_name"]).first
    end

    def description
      data["description"].to_s.strip.presence
    end

    def care_level_data
      data["care_level"] || data["maintenance"]
    end

    def display_image_url
      data.dig("default_image", "regular_url") ||
        data.dig("default_image", "medium_url") ||
        original_image_url
    end

    def original_image_url
      data.dig("default_image", "original_url") ||
        data.dig("default_image", "regular_url") ||
        data.dig("default_image", "medium_url")
    end

    def map_sunlight(value)
      values = Array(value).map { |item| item.to_s.downcase.tr("_", " ") }

      return "direct sun" if values.any? { |item| item.include?("full sun") }
      return "low" if values.any? { |item| item.include?("full shade") }

      "bright indirect"
    end

    def map_watering(value)
      case value.to_s.downcase
      when "frequent"
        "high"
      when "minimum", "none"
        "low"
      else
        "moderate"
      end
    end

    def map_care_level(value)
      case value.to_s.downcase
      when "high", "advanced"
        "advanced"
      when "medium", "moderate"
        "medium"
      else
        "easy"
      end
    end

    def truthy?(value)
      value == true || value.to_s == "1"
    end
  end
end
