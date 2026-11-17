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

  test "show loads missing Perenual details after the page instead of waiting for them" do
    @plant.update!(perenual_id: 4242, description: nil)

    get plant_url(@plant)

    assert_response :success
    assert_select "turbo-frame#plant_details[src=?]", plant_details_path(@plant)
    assert_select ".detail-empty"
  end

  test "show needs no extra load when details are fresh" do
    @plant.update!(perenual_id: 4242, synced_at: Time.current)

    get plant_url(@plant)

    assert_select "turbo-frame#plant_details"
    assert_select "turbo-frame#plant_details[src]", false
  end

  test "details renders the frame with what is known when Perenual is unavailable" do
    @plant.update!(perenual_id: 4242, description: nil)

    get plant_details_url(@plant)

    assert_response :success
    assert_select "turbo-frame#plant_details[src]", false
    assert_select ".page-title", text: "Test Fern"
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

  test "results skip local fallback plants without care content" do
    Plant.create!(
      name: "Empty Result Plant",
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      pet_safe: true,
      image_url: "https://example.com/empty-result-plant.jpg"
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
    assert_select ".plant-card", text: /Test Fern/
    assert_select ".plant-card", text: /Empty Result Plant/, count: 0
  end

  test "results show Perenual matches before their details arrive, topped up with saved plants" do
    new_match = Plant.create!(
      perenual_id: 4242,
      name: "Fresh Match",
      light_needs: "low",
      water_needs: "moderate",
      care_level: "easy",
      indoor_outdoor: "indoor",
      image_url: "https://example.com/fresh-match.jpg"
    )

    with_perenual_matches([new_match]) do
      get plant_matches_url, params: {
        light_needs: "low",
        water_needs: "moderate",
        care_level: "easy",
        pet_safe: "false"
      }
    end

    assert_response :success
    assert_select ".plant-card", 2
    assert_select ".plant-card:first-child", text: /Fresh Match/
    assert_select ".plant-card:first-child .plant-tag", text: /pet safe/, count: 0
    assert_select ".plant-card", text: /Test Fern/
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

  def with_perenual_failure(&)
    failing_service = Class.new do
      def call
        raise "Perenual unavailable"
      end
    end.new

    with_match_service(failing_service, &)
  end

  def with_perenual_matches(plants, &)
    service = Struct.new(:plants) do
      def call = plants
    end.new(plants)

    with_match_service(service, &)
  end

  def with_match_service(service)
    original_new = Perenual::MatchPlants.method(:new)
    Perenual::MatchPlants.define_singleton_method(:new) { |**| service }

    yield
  ensure
    Perenual::MatchPlants.define_singleton_method(:new) do |*args, **kwargs, &block|
      original_new.call(*args, **kwargs, &block)
    end
  end
end
