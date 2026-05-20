require "test_helper"

class PlantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @plant = Plant.create!(
      name: "Test Fern",
      growth_style: "bushy",
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      pet_safe: true,
      air_purifying: true,
      image_url: "https://example.com/test-fern.jpg",
      plant_info: "Test care information"
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
      growth_style: "bushy",
      indoor_outdoor: "indoor",
      pet_safe: "true",
      air_purifying: "true"
    }

    assert_response :success
  end
end
