module Perenual
  class ImportPlant
    def initialize(data)
      @data = data
    end

    def call
      find_plant.tap do |plant|
        assign_api_fields(plant)
        assign_matching_fields(plant)
        plant.save!
      end
    end

    private

    attr_reader :data

    def find_plant
      Plant.find_by(perenual_id: perenual_id) ||
        Plant.find_or_initialize_by(name: plant_name)
    end

    def assign_api_fields(plant)
      plant.perenual_id = perenual_id if perenual_id.present?
      plant.name = plant_name
      plant.scientific_name = scientific_name
      plant.description = description
      plant.image_url = display_image_url if display_image_url.present?
      plant.api_image_url = original_image_url if original_image_url.present?
      plant.api_data = data
      plant.synced_at = Time.current
    end

    def assign_matching_fields(plant)
      plant.light_needs = map_sunlight(data["sunlight"])
      plant.water_needs = map_watering(data["watering"])
      plant.care_level = map_care_level(data["care_level"] || data["maintenance"])
      plant.indoor_outdoor = "indoor"
      plant.pet_safe = !truthy?(data["poisonous_to_pets"])
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
