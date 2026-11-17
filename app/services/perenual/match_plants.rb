module Perenual
  class MatchPlants
    PAGE_LIMIT = 2
    DETAIL_LIMIT = 12
    NEXT_PAGE_BUDGET_SECONDS = 7
    # Under a day, so the image links saved with the plants are still valid
    CACHE_TTL = 12.hours

    def initialize(params:, client: nil)
      @params = params
      @client = client
    end

    # The search list has no descriptions; a plant's page fetches its details when opened.
    def call
      cached_plants || search
    end

    private

    attr_reader :params

    def client
      @client ||= Client.new
    end

    def search
      plants = candidates.first(DETAIL_LIMIT).filter_map { |data| import(data) }
      Rails.cache.write(cache_key, plants.map(&:id), expires_in: CACHE_TTL) if plants.any?
      plants
    end

    def cached_plants
      ids = Rails.cache.read(cache_key)
      return if ids.blank?

      Plant.where(id: ids).in_order_of(:id, ids).to_a.presence
    end

    def cache_key
      ["perenual-matches", search_params, matched_answers.compact]
    end

    # Each Perenual page is a slow request, so stop once there are enough plants,
    # or when another page could push the search past Heroku's 30 second limit
    def candidates
      found = []
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      (1..PAGE_LIMIT).each do |page|
        response = client.species_list(search_params.merge(page: page))
        found = (found + Array(response["data"]).select { |data| importable?(data) })
                .uniq { |data| plant_identity(data) }
        break if found.size >= DETAIL_LIMIT || page >= response["last_page"].to_i
        break if Process.clock_gettime(Process::CLOCK_MONOTONIC) - started > NEXT_PAGE_BUDGET_SECONDS
      end

      found
    end

    def import(data)
      ImportPlant.new(data, answers: matched_answers).call
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("Perenual import skipped: #{e.message}")
      nil
    end

    def importable?(data)
      data["id"].present? && image_url(data).present? && !Plant.locked_image?(image_url(data))
    end

    def plant_identity(data)
      scientific_name(data).presence || normalized_name(data["common_name"]).presence || data["id"]
    end

    def scientific_name(data)
      normalized_name(Array(data["scientific_name"]).first)
    end

    def normalized_name(name)
      name.to_s.downcase.gsub(/[^a-z0-9]+/, " ").squish
    end

    def image_url(data)
      data.dig("default_image", "regular_url") ||
        data.dig("default_image", "original_url") ||
        data.dig("default_image", "medium_url")
    end

    def search_params
      {
        indoor: 1,
        watering: watering_filter,
        sunlight: sunlight_filter,
        poisonous: poisonous_filter
      }.compact
    end

    # Answers Perenual filtered on, so every plant it returns has them
    def matched_answers
      {
        light_needs: (params[:light_needs] if sunlight_filter),
        water_needs: (params[:water_needs] if watering_filter),
        pet_safe: (true if poisonous_filter)
      }
    end

    def watering_filter
      {
        "low" => "minimum",
        "moderate" => "average",
        "high" => "frequent"
      }[params[:water_needs]]
    end

    def sunlight_filter
      {
        "low" => "full_shade",
        "medium" => "part_shade",
        "bright indirect" => "part_shade",
        "direct sun" => "full_sun"
      }[params[:light_needs]]
    end

    def poisonous_filter
      0 if params[:pet_safe].to_s == "true"
    end
  end
end
