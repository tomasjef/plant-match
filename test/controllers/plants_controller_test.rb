require "test_helper"

class PlantsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.create!(email: "plants-controller@example.com", password: "password")
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
    sign_in @user

    get plant_url(@plant)
    assert_response :success
    assert_select "img.detail-image[onerror]"
    assert_select ".plant-assistant-form + .plant-assistant-prompts"
    assert_select ".plant-assistant-prompt", text: "How big will it grow?"
    assert_select ".plant-assistant-prompt", text: "Is it air purifying?"
    assert_select ".plant-assistant-prompt", text: "How fast does it grow?"
    assert_select ".plant-assistant-prompt", text: "Common problems to watch for?"
  end

  test "show uses a soft empty detail state when plant content is unavailable" do
    @plant.update!(description: nil, plant_info: nil)

    get plant_url(@plant)

    assert_response :success
    assert_select ".detail-empty", text: "Detailed care notes are still being loaded."
    assert_select ".detail-copy", false
    assert_select "body", text: /Plant care information is not available/, count: 0
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

    with_perenual_failure do
      get plant_matches_url, params: {
        light_needs: "low",
        water_needs: "moderate",
        care_level: "easy",
        pet_safe: "true"
      }
    end

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

    with_perenual_failure do
      get plant_matches_url, params: {
        light_needs: "low",
        water_needs: "moderate",
        care_level: "easy",
        pet_safe: "true"
      }
    end

    assert_response :success
    assert_select ".plant-card", 1
  end

  private

  def with_perenual_failure
    original_new = Perenual::MatchPlants.method(:new)
    failing_service = Class.new do
      def call
        raise "Perenual unavailable"
      end
    end.new
    Perenual::MatchPlants.define_singleton_method(:new) { |**| failing_service }

    yield
  ensure
    Perenual::MatchPlants.define_singleton_method(:new) do |*args, **kwargs, &block|
      original_new.call(*args, **kwargs, &block)
    end
  end
end
