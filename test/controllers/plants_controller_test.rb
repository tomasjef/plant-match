require "test_helper"

class PlantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plant = Plant.create!(
      name: "Test Fern",
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      pet_safe: true,
      image_url: "https://example.com/test-fern.jpg",
      description: "Test care information"
    )
  end

  test "should get index" do
    get browse_plants_url
    assert_response :success
  end

  test "should get show" do
    get plant_url(@plant)
    assert_response :success
  end

  test "should get results" do
    get plant_matches_url, params: {
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      pet_safe: "true"
    }

    assert_response :success
  end

  test "results show up to nine unique plants" do
    @plant.destroy!

    10.times do |index|
      Plant.create!(
        name: "Result Plant #{index}",
        scientific_name: "Result scientific #{index}",
        light_needs: "low",
        water_needs: "moderate",
        care_level: "easy",
        indoor_outdoor: "indoor",
        pet_safe: true,
        image_url: "https://example.com/result-plant-#{index}.jpg",
        description: "Care information #{index}"
      )
    end

    get plant_matches_url, params: {
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      pet_safe: "true"
    }

    assert_response :success
    assert_select ".plant-card", 9
  end

  test "results deduplicate plants by scientific name" do
    @plant.update!(scientific_name: "Nephrolepis exaltata")
    Plant.create!(
      name: "Test Fern Duplicate",
      scientific_name: "Nephrolepis exaltata",
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      pet_safe: true,
      image_url: "https://example.com/test-fern-duplicate.jpg",
      description: "Duplicate care information"
    )

    get plant_matches_url, params: {
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      pet_safe: "true"
    }

    assert_response :success
    assert_select ".plant-card", 1
  end
end
