require "test_helper"

module Perenual
  class ImportPlantTest < ActiveSupport::TestCase
    test "imports Perenual fields into a local plant" do
      plant = ImportPlant.new(perenual_data).call

      assert_equal 12345, plant.perenual_id
      assert_equal "Prayer Plant", plant.name
      assert_equal "Maranta leuconeura", plant.scientific_name
      assert_equal "A compact plant with patterned leaves.", plant.description
      assert_equal "https://example.com/prayer-plant.jpg", plant.image_url
      assert_equal "bright indirect", plant.light_needs
      assert_equal "moderate", plant.water_needs
      assert_equal "medium", plant.care_level
      assert_equal "indoor", plant.indoor_outdoor
      assert plant.pet_safe
    end

    test "preserves existing detail content when importing lightweight list data" do
      plant = Plant.create!(
        perenual_id: 12345,
        name: "Prayer Plant",
        scientific_name: "Maranta leuconeura",
        description: "Detailed care content.",
        light_needs: "bright indirect",
        water_needs: "moderate",
        care_level: "medium",
        indoor_outdoor: "indoor",
        pet_safe: true,
        image_url: "https://example.com/prayer-plant.jpg",
        api_data: { "description" => "Detailed care content." }
      )

      ImportPlant.new(lightweight_perenual_data).call

      plant.reload
      assert_equal "Detailed care content.", plant.description
      assert_equal "Maranta leuconeura", plant.scientific_name
      assert_equal "medium", plant.care_level
      assert plant.pet_safe
      assert_equal "Lightweight Prayer Plant", plant.name
      assert_equal "https://example.com/lightweight-prayer-plant.jpg", plant.image_url
      assert_equal "Detailed care content.", plant.api_data["description"]
    end

    private

    def perenual_data
      {
        "id" => 12345,
        "common_name" => "Prayer Plant",
        "scientific_name" => ["Maranta leuconeura"],
        "description" => "A compact plant with patterned leaves.",
        "sunlight" => ["part shade"],
        "watering" => "Average",
        "care_level" => "Medium",
        "poisonous_to_pets" => false,
        "default_image" => {
          "regular_url" => "https://example.com/prayer-plant.jpg"
        }
      }
    end

    def lightweight_perenual_data
      {
        "id" => 12345,
        "common_name" => "Lightweight Prayer Plant",
        "watering" => "Average",
        "default_image" => {
          "regular_url" => "https://example.com/lightweight-prayer-plant.jpg"
        }
      }
    end
  end
end
