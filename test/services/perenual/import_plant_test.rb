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
  end
end
