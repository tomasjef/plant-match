module Perenual
  class MatchPlants
    PAGE_LIMIT = 2
    DETAIL_LIMIT = 12

    def initialize(params:, client: Client.new)
      @params = params
      @client = client
    end

    def call
      candidates.first(DETAIL_LIMIT)
                .filter_map { |data| import(data) }
                .select(&:displayable?)
    end

    private

    attr_reader :params, :client

    def candidates
      pages.flat_map { |page| Array(page["data"]) }
           .select { |data| importable?(data) }
           .uniq { |data| plant_identity(data) }
    end

    def pages
      first_page = client.species_list(search_params.merge(page: 1))

      [first_page] + (2..page_count(first_page)).map do |page|
        client.species_list(search_params.merge(page: page))
      end
    end

    def page_count(response)
      last_page = response["last_page"].to_i
      last_page = 1 if last_page < 1

      [last_page, PAGE_LIMIT].min
    end

    def import(data)
      ImportPlant.new(data).call
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.warn("Perenual import skipped: #{e.message}")
      nil
    end

    def importable?(data)
      data["id"].present? && image_url(data).present?
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
