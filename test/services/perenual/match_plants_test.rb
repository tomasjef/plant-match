require "test_helper"

module Perenual
  class MatchPlantsTest < ActiveSupport::TestCase
    test "searches Perenual for indoor plants without fetching details" do
      client = FakePerenualClient.new

      plants = MatchPlants.new(params: match_params, client: client).call

      assert_equal 1, plants.size
      assert_empty client.detail_ids
      assert_equal "Calathea Orbifolia", plants.first.name
      assert_nil plants.first.description
      assert_equal "easy", plants.first.care_level
      assert plants.first.pet_safe
      assert_equal expected_search_params, client.species_list_params.first
    end

    private

    def match_params
      {
        light_needs: "bright indirect",
        water_needs: "moderate",
        care_level: "medium",
        pet_safe: "true"
      }
    end

    def expected_search_params
      {
        indoor: 1,
        watering: "average",
        sunlight: "part_shade",
        poisonous: 0,
        page: 1
      }
    end

    class FakePerenualClient
      attr_reader :detail_ids, :species_list_params

      def initialize
        @detail_ids = []
        @species_list_params = []
      end

      def species_list(params = {})
        species_list_params << params

        {
          "data" => [plant_without_image, plant_with_image],
          "last_page" => 1
        }
      end

      def species_details(id)
        detail_ids << id
        plant_details
      end

      private

      def plant_without_image
        {
          "id" => 98764,
          "common_name" => "Image Missing Plant"
        }
      end

      def plant_with_image
        {
          "id" => 98765,
          "common_name" => "Calathea Orbifolia",
          "scientific_name" => ["Goeppertia orbifolia"],
          "sunlight" => ["part shade"],
          "watering" => "Average",
          "default_image" => {
            "regular_url" => "https://example.com/calathea.jpg"
          }
        }
      end

      def plant_details
        plant_with_image.merge(
          "description" => "A leafy indoor plant.",
          "care_level" => "Medium",
          "poisonous_to_pets" => false
        )
      end
    end
  end
end
